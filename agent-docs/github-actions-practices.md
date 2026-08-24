# github-actions-practices

Agent reference. Rules, not prose. See `CLAUDE.md` for layout overview.

## two file kinds

- `job-*.yml` — reusable, `on: workflow_call`. Generic. Never stack-specific.
- `pipeline-*-ci.yml` — one per stack. `on: push`/`pull_request` with path filters. Only wiring: inputs + `needs` + `if`.

Add a stack → add one `pipeline-*.yml`. Never add a `job-*.yml` unless the *mechanism* is new.

## reusable jobs

| file | purpose |
| --- | --- |
| `job-tf-fmt.yml` | `terraform fmt -check -recursive`, repo root, no inputs |
| `job-tf-plan.yml` | init + plan, outputs `changes-detected`, comments on PR |
| `job-tf-apply.yml` | init + `apply -auto-approve` |
| `job-tf-plan-firewall.yml` | plan, wrapped in runner-IP firewall open/close |
| `job-tf-apply-firewall.yml` | apply, wrapped in runner-IP firewall open/close |

## job inputs

- `working-directory` — stack dir, e.g. `mesazon-clusters/dev`
- `module` — state key prefix, e.g. `mesazon-clusters-dev`. Convention: `<stack-dir-with-slashes-as-dashes>`. Changing it orphans state.
- `project-id` — DO project UUID; pass `""` with a trailing comment when the stack does not use it
- `environment` — GitHub Environment name; apply jobs only
- `firewall-module` — full TF address, e.g. `module.gateway_pg_configure.digitalocean_database_firewall.pg_firewall`; firewall jobs only

## backend wiring

```
key = "${{ inputs.module }}-tf-state/terraform.tfstate"
bucket    ← secrets.DO_SPACES_BUCKET
endpoints ← https://${{ secrets.DO_SPACES_REGION }}.digitaloceanspaces.com
```

Always partial config via `-backend-config`. Never in `providers.tf`.

## secrets → env

`secrets: inherit` on every `uses:` call. Repo/environment secrets:

| secret | used as |
| --- | --- |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Spaces keys, for backend and `SPACES_*` |
| `DO_API_KEY` | `TF_VAR_do_token` |
| `DO_SPACES_BUCKET` / `DO_SPACES_REGION` | backend config |
| `DOCKER_TOKEN` | `TF_VAR_docker_token` |

`SPACES_ACCESS_KEY_ID`/`SPACES_SECRET_ACCESS_KEY` are set only in the non-firewall plan/apply jobs (needed by the DO provider for Spaces buckets).

Runner IP arrives via `candidob/get-runner-ip@v1.0.0` → `TF_VAR_runner_ip` in `$GITHUB_ENV`. Firewall jobs only.

## environment selection

```yaml
environment: ${{ github.event_name == 'pull_request' && 'dev_pr' || inputs.environment || 'prod' }}
```

Apply jobs only. Plan jobs run without a GitHub Environment.

## plan/apply gating

- plan runs `terraform plan -no-color -input=false -detailed-exitcode` with `continue-on-error: true`
- exit 2 → `changes_detected=true`; exit 0 → false; exit 1 → job fails via final step
- apply job is gated: `if: needs.<plan-job>.outputs.changes-detected == 'true'`
- plan posts a PR comment via `actions/github-script@v7` when `exitcode != 0`

Never call an apply job without a preceding plan job and this gate.

## firewall variant — when to use

Use `*-firewall` jobs when the stack talks to a DO managed database over the network (i.e. uses the `postgresql` provider). Currently `mesazon-clusters-configure` only.

Sequence inside the job:
1. `apply -target=<firewall-module>` — add runner IP
2. plan or apply the stack
3. `apply -target=<firewall-module> -var="disable_runner_ip=true"` — remove runner IP

Step 3 must always run. In `job-tf-apply-firewall.yml` the main apply uses `continue-on-error: true` and a trailing step re-fails the job, so the IP is revoked even when apply fails. Preserve that structure.

Stack must expose `runner_ip` and `disable_runner_ip` variables; module must build rules as:

```hcl
runner_database_firewall_rule = var.disable_runner_ip ? [] : [{ type = "ip_addr", value = var.runner_ip }]
```

## triggers

Every `pipeline-*-ci.yml`:

```yaml
on:
  push:
    branches: [ main ]
    paths: [ ".github/**", '<stack-dir>/**', 'modules/**' ]
  pull_request:
    paths: [ ".github/**", '<stack-dir>/**', 'modules/**' ]
```

`modules/**` is always included — a module change affects every consumer.
`pipeline-mesazon-tf-ci.yml` is the exception: `paths-ignore` on `.gitignore`/`README.md`, runs `tf-fmt` only.

## intra-pipeline ordering

`needs:` + `if:`. Chained stages in the same pipeline (clusters → clusters-configure) use:

```yaml
if: always() && !failure() && !cancelled()
```

so a skipped no-change apply does not block the next stage. Add `&& needs.<plan>.outputs.changes-detected == 'true'` on apply stages.

Cross-pipeline ordering (vpc → clusters) is **not** automated. Manual.

## pinned versions

`hashicorp/setup-terraform@v3` with `terraform_version: 1.14.3`, `actions/checkout@v6`, `actions/github-script@v7`, `candidob/get-runner-ip@v1.0.0`. Keep identical across all jobs.

## adding a pipeline for a new stack

```yaml
name: mesazon-<name>-ci
on:
  push:
    branches: [ main ]
    paths: [ ".github/**", 'mesazon-<name>/**', 'modules/**' ]
  pull_request:
    paths: [ ".github/**", 'mesazon-<name>/**', 'modules/**' ]
jobs:
  mesazon-<name>-tf-plan:
    uses: ./.github/workflows/job-tf-plan.yml
    secrets: inherit
    with:
      project-id: "" # Not used in mesazon-<name>
      working-directory: "mesazon-<name>"
      module: "mesazon-<name>"
  mesazon-<name>-tf-apply:
    needs: [ "mesazon-<name>-tf-plan" ]
    if: needs.mesazon-<name>-tf-plan.outputs.changes-detected == 'true'
    uses: ./.github/workflows/job-tf-apply.yml
    secrets: inherit
    with:
      project-id: "" # Not used in mesazon-<name>
      working-directory: "mesazon-<name>"
      module: "mesazon-<name>"
      environment: "prod"
```

Per-environment stack → append `/<env>` to `working-directory`, `-<env>` to `module`, set `environment` accordingly, and duplicate the pair per environment with `needs` chaining dev → prod.

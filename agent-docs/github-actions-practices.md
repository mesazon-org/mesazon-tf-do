# github-actions-practices

Agent reference. Rules, not prose. See `CLAUDE.md` for layout overview.

## three file kinds

- `job-*.yml` — reusable, `on: workflow_call`. Generic. Never stack-specific.
- `pipeline-*-ci.yml` — one per stack. `on: push`/`pull_request` with path filters. Only wiring: inputs + `needs` + `if`.
- `scheduled-*.yml` — cron/`workflow_dispatch`-triggered maintenance, not tied
  to any Terraform stack or state key. No path filters (nothing to scope to),
  no `terraform` step, doesn't call `job-tf-*`. Currently just
  `scheduled-registry-retention.yml`, which prunes DOCR tags and runs garbage
  collection — see below.

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

`DO_API_KEY` is also consumed directly (not as a `TF_VAR_*`) by `doctl` in
`scheduled-registry-retention.yml`. That workflow runs under the `prod`
GitHub Environment for that reason — same environment `mesazon-shared`'s
apply job uses to reach the same secret.

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

## validation — before finishing any workflow change

```bash
ruby -ryaml -e 'YAML.safe_load(File.read("<file>"), aliases: true); puts "YAML OK"'
```

(`python3 -c "import yaml"` is unavailable on this machine; use ruby or `yq`.)

- reusable job changed → check every `pipeline-*.yml` that calls it still passes required inputs
- `module` input changed on an existing stack → orphans state. Do not, unless migrating deliberately.
- new pipeline → confirm path filters include `.github/**` and `modules/**`

## docs — same commit as the change, not a follow-up

Mandatory. If a change makes any line in this file false, fix it in the same commit.

- new `pipeline-*.yml` → no table here lists pipelines, but confirm the new-pipeline template at the end still matches what you wrote
- new `job-*.yml` → add a row to the reusable-jobs table
- added/renamed/removed a job input → update the job-inputs list AND the template
- new secret or `TF_VAR_*` → update the secrets table
- new mechanism (a firewall-style wrapper, a new gating rule) → new section here, plus a line in `CLAUDE.md` if it changes how stacks deploy

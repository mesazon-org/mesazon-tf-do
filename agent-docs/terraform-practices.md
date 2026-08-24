# terraform-practices

Agent reference. Rules, not prose. See `CLAUDE.md` for layout overview.

## versions

- terraform `1.14.3` (matches CI; do not use other versions locally)
- `digitalocean/digitalocean ~> 2.0` — declare in every module `main.tf` and every stack `providers.tf`
- `cyrilgdn/postgresql ~> 1.21.0` — only `modules/postgres-configure`
- `.terraform.lock.hcl` not committed; do not add without deciding it repo-wide

## stack vs module

| | stack (`mesazon-*/`) | module (`modules/*/`) |
| --- | --- | --- |
| backend block | yes, `providers.tf` | never |
| `provider` block | yes, `providers.tf` | no (exception: `postgres-configure`) |
| `required_providers` | yes | yes, in `main.tf` |
| composes names | never | always, in `locals.tf` |
| applied by CI | yes | never directly |

## required files

stack: `providers.tf`, `locals.tf`, `variables.tf`, `<consumer>-<resource>.tf`
module: `main.tf`, `locals.tf`, `variables.tf`, `outputs.tf` (only if consumed)

## providers.tf (stack) — copy verbatim

```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    # Deactivate a few AWS-specific checks
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    use_lockfile                = true
    region                      = "us-east-1"
  }
}

provider "digitalocean" {
  token = var.do_token
}
```

`bucket`, `key`, `endpoints` are partial config — supplied by CI `-backend-config`. Never hardcode them.
`region = "us-east-1"` is a dummy; Spaces region comes from the endpoint URL.

## locals.tf (stack)

Only these. Nothing else belongs here.

```hcl
locals {
  region      = "fra1"
  environment = "dev"
}
```

Global stacks (`mesazon-org`, `mesazon-shared`) omit `environment`.

## naming

Caller passes `*_raw`. Module composes. Never invert this.

dash — DO infrastructure names:
```
"${var.X_name_raw}-${var.region}-${var.environment}"
```
underscore — Postgres identifiers:
```
"${var.X_raw}_${var.region}_${var.environment}"
"${var.user_raw}_user_${var.region}_${var.environment}"
"${var.user_raw}_group_${var.region}_${var.environment}"
"${var.user_raw}_flyway_user_${var.region}_${var.environment}"
"${var.schema_raw}_schema_${var.region}_${var.environment}"
```
exceptions — only these two, do not invent more:
- `container-registry` = `"${raw}-${region}"`, no environment (globally unique, shared)
- `dns-zone` = no composition at all. Variable is `domain_name`, not `domain_name_raw`; module has no `locals.tf`. A zone name must equal the registered domain exactly (`mesazon.space`). Env separation for DNS is at the record level (`api.dev.mesazon.space`), never in the zone name.

block labels: `snake_case`. Existing kebab-case blocks (`module "gateway-vpc"`, `module "mesazon-registry"`) are legacy — do not replicate, do not rename without `terraform state mv`.

variable names: `<thing>_name_raw` for names, `<thing>_raw` for postgres identifiers, plain nouns otherwise.

## cross-stack references

No `terraform_remote_state`. Look up by composed name:

```hcl
data "digitalocean_vpc" "vpc" { name = local.vpc_name }
data "digitalocean_database_cluster" "postgres_cluster" { name = local.cluster_name }
```

- consuming stack must repeat the producer's `*_name_raw` literal
- apply order is manual: `mesazon-vpc` → `mesazon-clusters` → `mesazon-clusters-configure`
- data lookup fails at plan if producer not applied — this is expected, not a bug to work around

## variables

- always `type`; always `description` in modules
- `do_token`: `type = string`, `sensitive = true`, in every stack `variables.tf`
- `project_id`: only stacks that assign resources to a DO project
- defaults belong in the module, not the stack — stack passes only what differs
- no `.tfvars` files; `*.tfvars` is gitignored. Values arrive as `TF_VAR_*` from CI

## resources

- `prevent_destroy = true` on `digitalocean_database_cluster` and `digitalocean_database_db`. Do not remove. A rename that forces replacement should fail the apply.
- explicit `depends_on` where the provider's implicit graph is insufficient — the `postgres-configure` grant chain is serialized this way to avoid deadlocks; preserve the single-file ordering when editing it
- tags: `local.common_tags = [var.environment, data.digitalocean_project.project.name]` (currently `postgres-cluster` only)

## known deviations — do not treat as patterns

- `modules/postgres-configure/main.tf` declares `provider "postgresql"` inside a child module. Blocks `count`/`for_each` on that module. Leave as-is; do not copy into new modules.
- `mesazon-clusters` mixes Postgres and Spaces in one stack.
- `spaces-bucket` and `vpc` expose no outputs.
- prod environment does not exist yet.

## validation — run before finishing any change

```bash
terraform fmt -recursive                  # from repo root, always
cd <changed-dir> && terraform init -backend=false && terraform validate
find . -name '.terraform.lock.hcl' -not -path './.git/*' -delete
```

- `fmt` is repo-wide in CI; one bad file fails everything
- backend unreachable locally; `-backend=false` is required
- changed a module interface → validate the module AND every stack calling it
- never run `terraform apply` locally; CI owns apply
- lock files are untracked here; delete what `init` generates before committing

## docs — same commit as the change, not a follow-up

Mandatory third validation step. Drift here causes wrong changes later, because these files are what agents read before naming resources or wiring state.

- new stack → stack table in `CLAUDE.md`
- new module → child-module list in `CLAUDE.md` + module list in `README.md`
- new naming rule or exception → naming section here + `CLAUDE.md`
- new/changed workflow or job input → `agent-docs/github-actions-practices.md`
- deliberate deviation from a convention → record it as an exception, here, under the matching heading. Undocumented deviation is indistinguishable from a bug and gets "fixed" by the next agent.
- **if a change makes any line in `CLAUDE.md` or `agent-docs/` false, fix that line in the same commit**

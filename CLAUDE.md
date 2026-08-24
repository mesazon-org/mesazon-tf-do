# CLAUDE.md

Guidance for agents working in this repository.

## What this repo is

Terraform for Mesazon's DigitalOcean infrastructure. No application code. Every
change here is infrastructure that CI applies to real DO resources on merge to
`main`, so correctness of naming and state keys matters more than elegance.

Providers: `digitalocean/digitalocean ~> 2.0` everywhere, plus
`cyrilgdn/postgresql ~> 1.21.0` in `modules/postgres-configure`. Terraform is
pinned to **1.14.3** in CI — use the same locally.

State lives in a DigitalOcean Spaces bucket accessed through the S3 backend.
The backend block is a *partial* configuration; bucket, key and endpoint are
supplied by `-backend-config` flags in CI. You cannot `terraform init` against
the real backend locally without Spaces credentials — use `-backend=false`.

## Layout

Two kinds of directory, and the distinction is load-bearing:

**Root modules (stacks)** — top-level `mesazon-*` directories. Each stack owns
one remote state file and one CI pipeline. Environment, where it applies, is a
subdirectory.

| Stack | State key | Owns |
| --- | --- | --- |
| `mesazon-org/` | `mesazon-org` | DO projects |
| `mesazon-shared/` | `mesazon-shared` | Cross-environment resources (container registry) |
| `mesazon-dns/` | `mesazon-dns` | DNS zones |
| `mesazon-vpc/<env>/` | `mesazon-vpc-<env>` | VPCs |
| `mesazon-clusters/<env>/` | `mesazon-clusters-<env>` | Postgres clusters, Spaces buckets |
| `mesazon-clusters-configure/<env>/` | `mesazon-clusters-configure-<env>` | In-database objects, DB firewall |

`mesazon-org`, `mesazon-shared` and `mesazon-dns` have no `<env>` subdirectory
because their resources are global.

**Child modules** — `modules/<resource>/`. Reusable, never applied directly,
never hold a backend or state: `container-registry`, `dns-zone`,
`postgres-cluster`, `postgres-configure`, `spaces-bucket`, `vpc`.

### Files inside a stack

- `providers.tf` — `terraform {}` block with `required_providers` and the
  partial `backend "s3"`, then `provider "digitalocean"`. Identical across
  stacks; copy it verbatim when adding one.
- `locals.tf` — only `region` and `environment`. These are the two values that
  make the directory an environment.
- `variables.tf` — `do_token` (sensitive), `project_id` where used, plus
  stack-specific inputs. All injected by CI as `TF_VAR_*`; there are no
  `.tfvars` files (they are gitignored).
- One file per logical resource group, named `<consumer>-<resource-type>.tf`:
  `gateway-postgres.tf`, `gateway-spaces.tf`, `gateway-vpc.tf`. Stacks without a
  consumer prefix use the plural resource name: `projects.tf`,
  `container-registries.tf`.

### Files inside a module

- `main.tf` — `terraform { required_providers {} }` (no backend, no version
  constraint on Terraform itself), data sources, then resources.
- `locals.tf` — name composition, nothing else.
- `variables.tf` — every input typed and described.
- `outputs.tf` — only where a caller consumes something. `vpc` and
  `spaces-bucket` have none.

## Naming conventions

The central rule: **callers pass short `*_raw` names; modules compose the full
name in `locals.tf`.** Never pass a fully-qualified name into a module, and
never compose a name in a stack.

Two separators, chosen by what the name addresses:

**Dash** for DigitalOcean infrastructure names — `${raw}-${region}-${environment}`:

```
vpc_name     = "gateway-vpc-fra1-dev"
bucket_name  = "gateway-organization-media-fra1-dev"
cluster_name = "gateway-fra1-dev"
pool         = "gateway-pool-01-fra1-dev"   # ${raw}-pool-01-${region}-${env}
```

**Underscore** for identifiers that live inside Postgres —
`${raw}_${region}_${environment}`, with a role marker before the region where
one applies:

```
database     = "gateway_db_fra1_dev"
schema       = "gateway_schema_fra1_dev"
user         = "gateway_user_fra1_dev"
user_group   = "gateway_group_fra1_dev"
flyway_user  = "gateway_flyway_user_fra1_dev"
flyway_group = "gateway_flyway_group_fra1_dev"
```

Two deliberate exceptions:

- `container-registry` composes `${raw}-${region}` with no environment, because
  DO registry names are globally unique and the registry is shared across
  environments.
- `dns-zone` composes **nothing**. It takes a plain `domain_name` (not
  `domain_name_raw`) and has no `locals.tf`, because a DNS zone name is a real,
  globally-unique DNS name that must match the registered domain exactly —
  `mesazon.space`, never `mesazon.space-fra1-dev`. Environment separation for
  DNS happens at the record level (`api.dev.mesazon.space`), not in the zone
  name.

Terraform block labels are `snake_case` (`module "gateway_pg_cluster"`,
`resource ... "pg_cluster"`). A few older blocks use kebab-case
(`module "gateway-vpc"`, `module "mesazon-registry"`) — do not copy that;
leave them alone unless you are prepared to `terraform state mv`.

## How stacks find each other

There is **no `terraform_remote_state`**. Stacks reference each other by
looking resources up by name:

```hcl
data "digitalocean_vpc" "vpc" { name = local.vpc_name }
data "digitalocean_database_cluster" "postgres_cluster" { name = local.cluster_name }
```

Consequences you must respect:

- The consuming stack repeats the same `*_name_raw` value as the producing
  stack. `mesazon-clusters/dev/gateway-postgres.tf` passes
  `vpc_name_raw = "gateway-vpc"` because `mesazon-vpc/dev/gateway-vpc.tf` did.
  Change one, change both.
- Apply order across stacks is **not** enforced by CI. VPC before clusters,
  clusters before clusters-configure. Applying out of order fails at the data
  source lookup, not at plan time in an obvious way.
- Renaming a `*_name_raw` destroys and recreates. `digitalocean_database_cluster`
  and `digitalocean_database_db` carry `prevent_destroy = true`, so such a
  change fails the apply instead — that is intentional.

## Environment separation

Environment is a **directory**, not a workspace and not a variable. There is no
`terraform workspace` usage anywhere. `dev` is the only environment currently
built; the intended prod shape is the commented-out block at the bottom of
`.github/workflows/pipeline-mesazon-clusters-ci.yml`.

What differs per environment:

- `locals.tf` — `environment`, and `region` if it ever diverges.
- The DO `project_id`, hardcoded per environment in the pipeline YAML and passed
  as `TF_VAR_project_id`.
- The GitHub Environment used for secrets: `dev_pr` on pull requests, otherwise
  the pipeline's `environment` input, falling back to `prod`.
- The state key, via the pipeline's `module` input.

## Validation and formatting — required for every change

Three steps. None of them are optional, and the third is the one most often
skipped.

### 1. Format

CI runs `terraform fmt -check -recursive` from the repo root on **every** push
and pull request that touches anything but `.gitignore`/`README.md`. A single
misformatted file anywhere fails the whole repo's CI. Run this before you are
done, from the repo root:

```bash
terraform fmt -recursive
```

### 2. Validate

Validate each stack or module directory you touched. The real backend is not
reachable locally, so initialise without it:

```bash
cd <stack-or-module-dir>
terraform init -backend=false
terraform validate
```

For a module, validating the module directory alone catches syntax and type
errors; validating a stack that calls it exercises the wiring, so do both when
you change a module's interface.

Note that `.terraform.lock.hcl` files are not committed in this repo — CI
re-resolves providers on every run. Delete any that `init` generates before
committing.

### 3. Update the docs, in the same commit

**If a change makes any sentence in `CLAUDE.md` or `agent-docs/` false, fixing it
is part of that change, not a follow-up.** Documentation drift here is not
cosmetic: these files are what agents read to decide how to name resources and
wire state, so a stale line actively causes bad changes later.

What triggers what:

| You added or changed | Update |
| --- | --- |
| A stack | Stack table in this file; `README.md` if it introduces a module |
| A module | Child-module list in this file; module list in `README.md` |
| A naming rule, or a deliberate exception to one | Naming section in this file **and** `agent-docs/terraform-practices.md` |
| A `pipeline-*.yml` or `job-*.yml`, or a job's inputs | `agent-docs/github-actions-practices.md` |
| A new convention, or a knowingly-broken one | The relevant `agent-docs/` file, under the matching heading |

A deliberate deviation from a convention must be written down as an exception.
An undocumented deviation is indistinguishable from a mistake and will be
"corrected" by whoever touches it next.

## Adding a new stack

1. Create `mesazon-<name>/` (add `<env>/` if the resources are per-environment).
2. Copy `providers.tf` verbatim from an existing stack of the same shape.
3. Add `locals.tf` with `region` and `environment` — omit it entirely if the
   stack's resources are both region-less and environment-less, as in
   `mesazon-dns`. Do not carry an unused local; `validate` will not flag it.
4. Add `variables.tf` with `do_token`, plus `project_id` if resources are
   assigned to a DO project.
5. Add resource files named `<consumer>-<resource-type>.tf`, or the plural
   resource noun (`domains.tf`, `projects.tf`) where there is no consumer.
6. Add `.github/workflows/pipeline-mesazon-<name>-ci.yml` following
   `pipeline-mesazon-vpc-ci.yml`, with path filters on `.github/**`, the new
   stack directory, and `modules/**`.
7. Update the docs per step 3 of the validation section — at minimum the stack
   table above.
8. Format, validate, open a PR and read the plan comment before merging.

## Details

- `agent-docs/terraform-practices.md`
- `agent-docs/github-actions-practices.md`

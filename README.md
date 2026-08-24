## Mesazon DigitalOcean Infrastructure

This repository contains the Terraform configuration files used to set up and manage the infrastructure for Mesazon on DigitalOcean. The infrastructure includes Droplets, Databases, Load Balancers, and other necessary resources.

### Common Modules
The __modules__ directory contains reusable Terraform modules that can be used across different environments. Each module is designed to manage a specific resource or set of resources.
- `/container-registry`: Manages the DigitalOcean Container Registry.
- `/dns-zone`: Creates a DigitalOcean-managed DNS zone (domain).
- `/postgres-cluster`: Sets up a PostgreSQL database cluster.
- `/postgres-configure`: Configures PostgreSQL cluster by creating:
  - schemas 
  - flyway-user
  - provided-users
  - groups
  - roles.
- `/spaces-bucket`: Manages a DigitalOcean Spaces (S3-compatible) bucket.
- `/vpc`: Creates a VPC and its private IP range.

### Stacks

Top-level `mesazon-*` directories are independent Terraform root modules, each
with its own remote state and CI pipeline. See `CLAUDE.md` for the full stack
table, naming conventions and the required validation steps.

### Contributing

Every change must be formatted, validated and reflected in the docs before the
PR is opened — see *Validation and formatting* in `CLAUDE.md`.

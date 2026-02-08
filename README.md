## Mesazon DigitalOcean Infrastructure

This repository contains the Terraform configuration files used to set up and manage the infrastructure for Mesazon on DigitalOcean. The infrastructure includes Droplets, Databases, Load Balancers, and other necessary resources.

### Common Modules
The __modules__ directory contains reusable Terraform modules that can be used across different environments. Each module is designed to manage a specific resource or set of resources.
- `/container-registry`: Manages the DigitalOcean Container Registry.
- `/postgres-cluster`: Sets up a PostgreSQL database cluster.
- `/postgres-configure`: Configures PostgreSQL cluster by creating:
  - schemas 
  - flyway-user
  - provided-users
  - groups
  - roles.

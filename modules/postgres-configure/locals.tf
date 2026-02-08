locals {
  cluster_name = "${var.cluster_name_raw}-${var.region}-${var.environment}"

  database = "${var.database_raw}_${var.region}_${var.environment}"

  schema = "${var.schema_raw}_schema_${var.region}_${var.environment}"

  user       = "${var.user_raw}_user_${var.region}_${var.environment}"
  user_group = "${var.user_raw}_group_${var.region}_${var.environment}"

  flyway_user  = "${var.user_raw}_flyway_user_${var.region}_${var.environment}"
  flyway_group = "${var.user_raw}_flyway_group_${var.region}_${var.environment}"

  database_firewall_rules = [
    { type = "ip_addr", value = var.runner_ip },
    { type = "ip_addr", value = "127.0.0.1" } # The "Impossible IP" to ensure lockdown
  ]
}

locals {
  cluster_name = "${var.cluster_name_raw}-${var.region}-${var.environment}"

  database = "${var.database_raw}_${var.region}_${var.environment}"

  schema = "${var.schema_raw}_schema_${var.region}_${var.environment}"

  user       = "${var.user_raw}_user_${var.region}_${var.environment}"
  user_group = "${var.user_raw}_group_${var.region}_${var.environment}"

  flyway_user  = "${var.user_raw}_flyway_user_${var.region}_${var.environment}"
  flyway_group = "${var.user_raw}_flyway_group_${var.region}_${var.environment}"

  base_database_firewall_rule   = [{ type = "ip_addr", value = "127.0.0.1" }]
  runner_database_firewall_rule = var.disable_runner_ip ? [] : [{ type = "ip_addr", value = var.runner_ip }]

  active_database_firewall_rules = concat(local.base_database_firewall_rule, local.runner_database_firewall_rule)
}

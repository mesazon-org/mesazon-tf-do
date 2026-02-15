variable "do_token" {
  description = "DigitalOcean Personal Access Token"
  type        = string
  sensitive   = true
}

variable "runner_ip" {
  description = "Github runner IP address to allow in the cluster firewall"
  type        = string
}

variable "disable_runner_ip" {
  description = "Whether to disable the runner IP in the firewall rules."
  type        = bool
  default     = false
}

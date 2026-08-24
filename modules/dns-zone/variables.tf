variable "domain_name" {
  type        = string
  description = "Literal DNS zone name (e.g. mesazon.space). Deliberately NOT suffixed with region or environment, unlike other modules in this repository, because a zone name must match the registered domain exactly."
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "analytics_aad_group_id" {
  description = "Object ID of the analytics team AAD group."
  type        = string
}

variable "ingest_aad_group_id" {
  description = "Object ID of the ingest team AAD group."
  type        = string
}

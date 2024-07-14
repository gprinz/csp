// variables.tf
variable "ARM_SUBSCRIPTION_ID" {
  description = "The subscription ID for Azure"
  type        = string
  default     = "Placeholder"
}

variable "ARM_CLIENT_ID" {
  description = "The client ID for Azure"
  type        = string
  default     = "Placeholder"
}

variable "ARM_CLIENT_SECRET" {
  description = "The client secret for Azure"
  type        = string
  sensitive   = true
  default     = "Placeholder"
}

variable "ARM_TENANT_ID" {
  description = "The tenant ID for Azure"
  type        = string
  default     = "Placeholder"
}

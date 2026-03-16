variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment_unique" {
  description = "Bunnyshell environment unique ID (used for resource naming isolation)"
  type        = string
}

variable "enable_msk" {
  description = "Whether to provision an MSK (Kafka) cluster. Disabled by default due to cost and provisioning time (~20 min, ~$200/mo)."
  type        = bool
  default     = false
}

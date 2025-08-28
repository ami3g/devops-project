variable "db_password" {
  description = "The password for the RDS database."
  type        = string
  sensitive   = true
}

variable "db_endpoint" {
  description = "The endpoint for the RDS database."
  type        = string
}

variable "db_username" {
  description = "The username for the RDS database."
  type        = string
  default     = "projectadmin"
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "devops_project_db"
}

variable "db_engine_version" {
  description = "The version of the database engine."
  type        = string
  default     = "16.10"
}
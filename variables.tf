variable "db_username" {
  type = string
  description = "Username for database"
  default = "postgres"
}

variable "db_password" {
  type = string
  description = "Password for the database"
  validation {
    condition = length(var.db_password) >= 7
    error_message = "Password for db must be longer than 7 characters."
  }
sensitive = true
}

variable "db_port" {
  type = string
  description = "Port used to connect to database"
  default = "5432"
}

variable "db_name" {
  type = string
  description = "Name of the database"
  default = "gtd_db"
}

variable "db_type" {
  type = string
  description = "Database engine to use"
  default = "postgres"
}

variable "app_listen_host" {
  type = string
  description = "The IP address to listen to"
  default = "0.0.0.0"
}

variable "app_listen_port" {
  type = string
  description = "The port the app listens for requests from"
  default = "3000"
}

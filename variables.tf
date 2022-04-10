variable "postgresql_host"     { type = string }
variable "postgresql_port"     { type = number }
variable "postgresql_db"       { type = string }
variable "postgresql_user"     { type = string }
variable "postgresql_password" { type = string }
variable "kube_config"         { type = string }

variable "psql_namespace" {
  type    = string
  default = "postgresql"
}

variable "pg_roles" {
  type = list(object({
    name     = string
    password = string
    login    = bool
  }))
  default = []
}

variable "pg_databases" {
  type = list(object({
    name  = string
    owner = string
  }))
  default = []
}

variable "pg_grants" {
  type = list(object({
    database    = string
    schema      = string
    role        = string
    objects     = list(string)
    object_type = string
    privileges  = list(string)
  }))
  default = []
}

variable "pg_extensions" {
  type = list(object({
    name           = string
    database       = string
    schema         = string
    version        = string
    drop_cascade   = bool
    create_cascade = bool
  }))
  default = []
}

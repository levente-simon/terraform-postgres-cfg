terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.15.0"
    }
  }
}

locals {
  secret_tmpl = <<EOT
{
  "username": "%s",
  "password": "%s"
}
EOT
}

provider "postgresql" {
  host            = var.postgresql_host
  port            = var.postgresql_port
  database        = var.postgresql_db
  username        = var.postgresql_user
  password        = var.postgresql_password
  sslmode         = "require"
  connect_timeout = 15
}

resource "random_password" "psql_password" {
  count            = length(var.pg_roles)

  length           = 16
  special          = false
  override_special = "_%@"
}

resource "postgresql_role" "this" {
  count    = length(var.pg_roles)

  name     = var.pg_roles[count.index].name
  login    = true
  password = random_password.psql_password[count.index].result
  
  provisioner "local-exec" {
    command  = "sleep 2"
  }
  provisioner "local-exec" {
    when     = destroy
    command  = "sleep 2"
  }
}

resource "postgresql_database" "this" {
  depends_on = [ postgresql_role.this ]
  count      = length(var.pg_databases)

  name       = var.pg_databases[count.index].name
  owner      = var.pg_databases[count.index].owner

  provisioner "local-exec" {
    command  = "sleep 2"
  }
  provisioner "local-exec" {
    when     = destroy
    command  = "sleep 2"
  }
}

resource "null_resource" "update_pgpool" {
  depends_on = [ random_password.psql_password,
                 postgresql_database.this]
  count      = length(var.pg_roles) > 0 ? 1 : 0

  triggers = {
    kube_config    = var.kube_config
    psql_namespace = var.psql_namespace
    names          = join(";",[ for i in var.pg_roles: i.name ])
    passwords      = join(";",[ for i in random_password.psql_password: i.result ])
  }

  provisioner "local-exec" {
    command = format("${path.module}/bin/update_pgpool_conf.sh -f base64:%s -n '%s' -u '%s' -p '%s'",
        self.triggers.kube_config, self.triggers.psql_namespace, self.triggers.names, self.triggers.passwords)
  }

  provisioner "local-exec" {
    when    = destroy
    command = format("${path.module}/bin/update_pgpool_conf.sh -f base64:%s -n '%s'",
        self.triggers.kube_config, self.triggers.psql_namespace)
  }
}


resource "time_sleep" "wait_a_bit" {
  depends_on  = [ null_resource.update_pgpool ]
  create_duration = "15s"
}

resource "postgresql_grant" "this" {
  depends_on  = [ time_sleep.wait_a_bit ]
  count       = length(var.pg_grants)  

  database    = var.pg_grants[count.index].database
  schema      = var.pg_grants[count.index].schema
  role        = var.pg_grants[count.index].role
  object_type = var.pg_grants[count.index].object_type
  objects     = var.pg_grants[count.index].objects
  privileges  = var.pg_grants[count.index].privileges

  provisioner "local-exec" {
    command  = "sleep 2"
  }
  provisioner "local-exec" {
    when     = destroy
    command  = "sleep 2"
  }
}

resource "postgresql_extension" "this" {
  depends_on     = [ time_sleep.wait_a_bit ]
  count          = length(var.pg_extensions)  

  database       = var.pg_extensions[count.index].database
  schema         = var.pg_extensions[count.index].schema
  name           = var.pg_extensions[count.index].name
  version        = var.pg_extensions[count.index].version
  drop_cascade   = var.pg_extensions[count.index].drop_cascade
  create_cascade = var.pg_extensions[count.index].create_cascade

  provisioner "local-exec" {
    command  = "sleep 2"
  }
  provisioner "local-exec" {
    when     = destroy
    command  = "sleep 2"
  }
}


output "passwords" {
  value = zipmap(
    [ for i in var.pg_roles: i.name ],
    [ for i in random_password.psql_password: i.result ]
  )
  sensitive = true
}

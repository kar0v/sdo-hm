resource "azurerm_mssql_server" "main" {
  name                         = "karov-mssql-server"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_administrator_login
  administrator_login_password = var.sql_administrator_login_password
}

resource "azurerm_mssql_database" "demodb" {
  name                        = "demodb"
  min_capacity                = 0.5
  max_size_gb                 = 2
  auto_pause_delay_in_minutes = 20
  sku_name                    = "GP_S_Gen5_1"
  server_id                   = azurerm_mssql_server.main.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  read_scale                  = false
  zone_redundant              = false
  storage_account_type        = "Local"
  sample_name                 = "AdventureWorksLT"

}

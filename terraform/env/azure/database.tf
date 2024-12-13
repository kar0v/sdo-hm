resource "azurerm_mssql_server" "main" {
  name                         = "karov-mssql-server"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_administrator_login
  administrator_login_password = var.sql_administrator_login_password
}

# resource "azurerm_mssql_database" "exampledb" {
#   name                = "exampledb"
#   resource_group_name = azurerm_mssql_server.main.resource_group_name
#   server_name         = azurerm_mssql_server.main.name
#   collation           = "SQL_Latin1_General_CP1_CI_AS"
#   max_size_gb         = 10
# }

# resource "azurerm_subnet_network_security_group_association" "db_subnet_nsg" {
#   subnet_id                 = azurerm_subnet.db.id
#   network_security_group_id = azurerm_network_security_group.db.id
# }

# resource "azurerm_network_security_group" "db" {
#   name                = "db-nsg"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name

#   security_rule {
#     name                       = "allow_sql"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "1433"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# resource "azurerm_mssql_virtual_network_rule" "example" {
#   name                = "example-vnet-rule"
#   resource_group_name = azurerm_resource_group.main.name
#   server_name         = azurerm_mssql_server.main.name
#   subnet_id           = azurerm_subnet.db.id
# }

# # ...existing code...

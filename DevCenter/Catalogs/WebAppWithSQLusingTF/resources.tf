data "azurerm_resource_group" "Environment" {
  name = "${var.resource_group_name}"
}

resource "random_integer" "ResourceSuffix" {
	min 					= 10000
	max						= 99999
}

resource "azurerm_virtual_network" "primary-vnet" {
  name = "primaryvnet${random_integer.ResourceSuffix.result}"
  resource_group_name = data.azurerm_resource_group.Environment.name
  address_space       = ["30.0.0.0/16"]
  location            = data.azurerm_resource_group.Environment.location
}

resource "azurerm_subnet" "sql-subnet" {
  depends_on           = [azurerm_virtual_network.primary-vnet]
  name                 = "sqlsubnet"
  virtual_network_name = azurerm_virtual_network.primary-vnet.name
  resource_group_name  = data.azurerm_resource_group.Environment.name
  address_prefixes     = ["30.0.0.0/24"]
  delegation {
    name = "managedinstancedelegation"

    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_network_security_group" "sql_secgroup" {
  name                = "sqlnsg${random_integer.ResourceSuffix.result}"
  location            = data.azurerm_resource_group.Environment.location
  resource_group_name = data.azurerm_resource_group.Environment.name
}

resource "azurerm_subnet_network_security_group_association" "sql_secgroup_associate" {
  subnet_id                 = azurerm_subnet.sql-subnet.id
  network_security_group_id = azurerm_network_security_group.sql_secgroup.id
}

# Create a route table
resource "azurerm_route_table" "sql_route_table" {
  name                          = "sqlrt${random_integer.ResourceSuffix.result}"
  location                      = data.azurerm_resource_group.Environment.location
  resource_group_name           = data.azurerm_resource_group.Environment.name
  disable_bgp_route_propagation = false
}

# Associate subnet and the route table
resource "azurerm_subnet_route_table_association" "sql_route_table" {
  subnet_id      = azurerm_subnet.sql-subnet.id
  route_table_id = azurerm_route_table.sql_route_table.id
}

resource "azurerm_mssql_managed_instance" "primary-sql-server" {
  depends_on                   = [azurerm_subnet.sql-subnet]
  name                         = "primaryserver${random_integer.ResourceSuffix.result}"
  resource_group_name          = data.azurerm_resource_group.Environment.name
  location                     = data.azurerm_resource_group.Environment.location
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password    
  subnet_id                    = azurerm_subnet.sql-subnet.id
  license_type                 = "BasePrice"
  sku_name                     = "GP_Gen5"
  vcores                       = 8
  storage_size_in_gb           = 32
}

resource "azurerm_mssql_database" "db" {
  depends_on = [azurerm_mssql_managed_instance.primary-sql-server]
  name      = var.sql_db_name
  server_id = azurerm_mssql_managed_instance.primary-sql-server.id
  collation = "Latin1_General_CI_AS"
  zone_redundant = false
  read_scale = false
}

# # Create a DB Private DNS Zone
# resource "azurerm_private_dns_zone" "rbest-endpoint-dns-private-zone" {
#     #name = "${azurerm_private_dns_zone_virtual_network_link.rbest-endpoint-dns-link.name}.database.windows.net"
#     name = "privatelink.database.windows.net"
#     resource_group_name = data.azurerm_resource_group.sqlrg.name  
# }

# # Link the Private DNS Zone with the VNET
# resource "azurerm_private_dns_zone_virtual_network_link" "rbest-endpoint-dns-link" {
#   name = "rbest-vnet"
#   resource_group_name = data.azurerm_resource_group.sqlrg.name
#   private_dns_zone_name = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name
#   virtual_network_id = data.azurerm_virtual_network.rbest-vnet.id
# }

# # DB Private Endpoint Connecton
# data "azurerm_private_endpoint_connection" "rbest-endpoint-connection" {
#   depends_on = [azurerm_private_endpoint.rbest-db-endpoint]
#   name = azurerm_private_endpoint.rbest-db-endpoint.name
#   resource_group_name = data.azurerm_resource_group.sqlrg.name
# }

# Create a DB Private DNS A Record
# resource "azurerm_private_dns_a_record" "rbest-endpoint-dns-a-record" {
#   depends_on = [azurerm_mssql_server.rbest-sql-server]
#   name = lower(azurerm_mssql_server.rbest-sql-server.name)
#   zone_name = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name
#   resource_group_name = data.azurerm_resource_group.sqlrg.name
#   ttl = 300
#   records = [data.azurerm_private_endpoint_connection.rbest-endpoint-connection.private_service_connection.0.private_ip_address]
# }

# # Create a Private DNS to VNET link
# resource "azurerm_private_dns_zone_virtual_network_link" "dns-zone-to-vnet-link" {
#   name = "rbest-sql-db-vnet-link"
#   resource_group_name = data.azurerm_resource_group.vnetrg.name
#   private_dns_zone_name = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name  
#   virtual_network_id = data.azurerm_virtual_network.rbest-vnet.id
# }

# locals {
#   admin_password = try(random_password.admin_password[0].result, var.admin_password)
# }

# Create a DB Private Endpoint
# resource "azurerm_private_endpoint" "rbest-db-endpoint" {
#   depends_on = [
#     azurerm_mssql_server.rbest-sql-server,
#     azurerm_private_dns_zone.rbest-endpoint-dns-private-zone
#     ]
#   name = "rbest-sql-db-endpoint"
#   location = data.azurerm_resource_group.sqlrg.location
#   resource_group_name = data.azurerm_resource_group.sqlrg.name
#   subnet_id = data.azurerm_subnet.rbest-sql-subnet.id
#   private_service_connection {
#     name = "rbest-sql-db-endpoint"
#     is_manual_connection = "false"
#     private_connection_resource_id = azurerm_mssql_server.rbest-sql-server.id
#     subresource_names = ["sqlServer"]
#   }
#   private_dns_zone_group {
#     name                 = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name
#     private_dns_zone_ids = [azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.id]
#   }
# }
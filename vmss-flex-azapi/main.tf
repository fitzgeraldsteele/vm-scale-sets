resource "azurerm_resource_group" "rg" {
  name     = "vmssflex-specialtysku-azapi"
  location = "westus3"
}

resource "azurerm_virtual_network" "vnet" {
  name = "myvnet"
  address_space = [ "10.1.0.0/16" ]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}
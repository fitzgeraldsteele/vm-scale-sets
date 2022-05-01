resource "azurerm_resource_group" "rg" {
  name     = "vmssflex-specialtysku-azapi"
  location = "westus3"
}

variable "ADMIN_PASSWORD" {
  type = string
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

resource "azapi_resource" "vmssflex-specialty" {
  type      = "Microsoft.Compute/virtualMachineScaleSets@2021-11-01"
  name      = "flex-Mseries-azapi"
  parent_id = azurerm_resource_group.rg.id
  location = "westus3"

  body = jsonencode({
    sku = {
        capacity = 2
        name = "Standard_M8ms"
    }

    properties = {
        orchestrationMode = "Flexible"
        singlePlacementGroup = true
        platformFaultDomainCount = 3
        virtualMachineProfile = {
            osProfile = {
                computerNamePrefix = "vm"
                adminUsername = "azureuser"
                adminPassword = var.ADMIN_PASSWORD

            }
            networkProfile = {
                networkApiVersion = "2020-11-01"
                networkInterfaceConfigurations = [
                    {
                        name = "nic"
                        properties = {
                            ipConfigurations = [
                                {
                                    name = "ipconfig"
                                    properties = {
                                        subnet = {
                                            id = azurerm_subnet.subnet.id
                                        }
                                        publicIPAddressConfiguration = {
                                            name = "pip"
                                            sku = {
                                                name = "Standard"
                                                tier = "Regional"
                                            }
                                            properties = {
                                                publicIPAddressVersion = "IPv4"
                                                idleTimeoutInMinutes = 5
                                                deleteOption = "Delete"
                                            }
                                            
                                        }
                                    }
                                    
                                }
                            ]
                        
                        }      
                    }
                ]
            }
            storageProfile = {
                imageReference = {
                    publisher = "Canonical"
                    offer = "UbuntuServer"
                    sku = "18.04-LTS"
                    version = "latest"
                }
                osDisk = {
                    createOption = "FromImage"
                    managedDisk = {
                        storageAccountType = "Premium_LRS"
                    }                    
                }
            }
        }
    }
    zones = []
  })
}


resource "azapi_resource" "vmssflex-spotmix" {
  type      = "Microsoft.Compute/virtualMachineScaleSets@2021-11-01"
  name      = "flex-spotmix-azapi"
  parent_id = azurerm_resource_group.rg.id
  location = "westus3"
  schema_validation_enabled = false

  body = jsonencode({
    sku = {
        capacity = 20
        name = "Standard_F1s"
    }

    properties = {
        orchestrationMode = "Flexible"
        singlePlacementGroup = false
        platformFaultDomainCount = 1
        priorityMixPolicy = {
            baseRegularPriorityCount = 1
            regularPriorityPercentageAboveBase = 20
        }
        virtualMachineProfile = {
            priority = "Spot"
            billingProfile = {
                maxPrice = -1
            }
            osProfile = {
                computerNamePrefix = "vm"
                adminUsername = "azureuser"
                adminPassword = var.ADMIN_PASSWORD

            }
            networkProfile = {
                networkApiVersion = "2020-11-01"
                networkInterfaceConfigurations = [
                    {
                        name = "nic"
                        properties = {
                            ipConfigurations = [
                                {
                                    name = "ipconfig"
                                    properties = {
                                        subnet = {
                                            id = azurerm_subnet.subnet.id
                                        }
                                        publicIPAddressConfiguration = {
                                            name = "pip"
                                            sku = {
                                                name = "Standard"
                                                tier = "Regional"
                                            }
                                            properties = {
                                                publicIPAddressVersion = "IPv4"
                                                idleTimeoutInMinutes = 5
                                                deleteOption = "Delete"
                                            }
                                            
                                        }
                                    }
                                    
                                }
                            ]
                        
                        }      
                    }
                ]
            }
            storageProfile = {
                imageReference = {
                    publisher = "Canonical"
                    offer = "UbuntuServer"
                    sku = "18.04-LTS"
                    version = "latest"
                }
                osDisk = {
                    createOption = "FromImage"
                    managedDisk = {
                        storageAccountType = "Premium_LRS"
                    }                    
                }
            }
        }
    }
    zones = []
  })
}

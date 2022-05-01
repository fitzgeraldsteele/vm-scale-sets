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
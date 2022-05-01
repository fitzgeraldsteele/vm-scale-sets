
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

resource "azurerm_resource_group" "mrg" {
  name     = "azapi-special-fdalign"
  location = "eastus2"
}

resource "azurerm_virtual_network" "mvnet" {
  name = "myvnet"
  address_space = [ "10.1.0.0/16" ]
  location = azurerm_resource_group.mrg.location
  resource_group_name = azurerm_resource_group.mrg.name
}

resource "azurerm_subnet" "msubnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.mrg.name
  virtual_network_name = azurerm_virtual_network.mvnet.name
  address_prefixes     = ["10.1.2.0/24"]
}




# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.mrg.location
  resource_group_name = azurerm_resource_group.mrg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.mrg.location
  resource_group_name = azurerm_resource_group.mrg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.msubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}


# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azapi_resource" "vmssflex-specialty-manual" {
  type      = "Microsoft.Compute/virtualMachineScaleSets@2021-03-01"
  name      = "flex-Mseries-azapi"
  parent_id = azurerm_resource_group.mrg.id
  location = azurerm_resource_group.mrg.location
  schema_validation_enabled = false

  body = jsonencode({
 
    properties = {
        orchestrationMode = "Flexible"
        platformFaultDomainCount = 3
    }
    zones = [2]
  })
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "myVM"
  location              = azurerm_resource_group.mrg.location
  resource_group_name   = azurerm_resource_group.mrg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_M8ms"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }


  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "myvm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  virtual_machine_scale_set_id = azapi_resource.vmssflex-specialty-manual.id
}
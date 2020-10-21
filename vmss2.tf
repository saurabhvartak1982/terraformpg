provider "azurerm" {
version = ">=2.20"
features {}
}

resource "azurerm_resource_group" "my_playground" {
name = "saurabhtf-rg"
location = "southeastasia"
}


resource "azurerm_virtual_network" "my_app" {
name = "sauapp"
resource_group_name = azurerm_resource_group.my_playground.name
location = azurerm_resource_group.my_playground.location
address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "internal" {
name = "internal"
resource_group_name = azurerm_resource_group.my_playground.name
virtual_network_name = azurerm_virtual_network.my_app.name
address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_linux_virtual_machine_scale_set" "my_app_vmss" {
name = "mcg-pg-vmss-health"
resource_group_name = azurerm_resource_group.my_playground.name
location = azurerm_resource_group.my_playground.location
sku = "Standard_F2"
instances = 1
admin_username = "adminuser"

admin_ssh_key {
username = "adminuser"
public_key = file("~/.ssh/id_rsa.pub")
}

source_image_reference {
publisher = "Canonical"
offer = "UbuntuServer"
sku = "16.04-LTS"
version = "latest"
}

os_disk {
storage_account_type = "Standard_LRS"
caching = "ReadWrite"
}

network_interface {
name = "main"
primary = true

ip_configuration {
name = "internal"
primary = true
subnet_id = azurerm_subnet.internal.id
}
}

extension {
name = "mcgapphealth08"
publisher = "Microsoft.ManagedServices"
type = "ApplicationHealthLinux"
type_handler_version = "1.0"
settings = jsonencode({
"protocol": "http",
"requestPath": "/health"
})
}

automatic_instance_repair {
enabled = true
}
}


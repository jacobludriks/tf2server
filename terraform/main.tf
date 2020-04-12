# Run with: terraform plan -var-file="/mnt/c/path/to/variables.tfvars"

# The values for these variables are stored in variables.tfvars, which is not stored in the repository
variable "subscription_id" {}
variable "tenant_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "client_name" {}
variable "publickey" {}
variable "my_public_ip" {}

# The location that the VM will be deployed in
variable "location" {
    default = "Australia East"
}

# The size of the VM
variable "vm_size" {
    default = "Standard_B1ms"
}

# Username of admin on VM
variable "vm_admin" {
    default = "tf2oeadmin"
}

provider "azurerm" {
    version     = "~>2.0"
    features {}

    subscription_id     = var.subscription_id
    client_id           = var.client_id
    client_secret       = var.client_secret
    tenant_id           = var.tenant_id
}

resource "azurerm_resource_group" "tf2group" {
    name        = "TF2Server"
    location    = var.location
}

resource "azurerm_virtual_network" "tf2network" {
    name                    = "TF2"
    address_space           = ["10.90.0.0/16"]
    location                = var.location
    resource_group_name     = azurerm_resource_group.tf2group.name
}

resource "azurerm_subnet" "tf2subnet" {
    name                    = "TF2Subnet"
    resource_group_name     = azurerm_resource_group.tf2group.name
    virtual_network_name    = azurerm_virtual_network.tf2network.name
    address_prefix          = "10.90.1.0/24"
}

resource "azurerm_public_ip" "tf2publicip" {
    name                    = "TF2PublicIP"
    location                = var.location
    resource_group_name     = azurerm_resource_group.tf2group.name
    allocation_method       = "Static"
}

# Allow port 27015 on TCP and UDP for TF2
resource "azurerm_network_security_group" "tf2nsg" {
    name                    = "TF2NSG"
    location                = var.location
    resource_group_name     = azurerm_resource_group.tf2group.name

    security_rule {
        name                        = "SSH"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "22"
        source_address_prefix       = "${var.my_public_ip}/32"
        destination_address_prefix  = "*"
    }
    security_rule {
        name                        = "TF2Tcp"
        priority                    = 500
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "27015"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }

    security_rule {
        name                        = "TF2Udp"
        priority                    = 510
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Udp"
        source_port_range           = "*"
        destination_port_range      = "27015"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
}

resource "azurerm_network_interface" "tf2nic" {
    name                    = "TF2Nic"
    location                = var.location
    resource_group_name     = azurerm_resource_group.tf2group.name

    ip_configuration {
        name                            = "TF2NicConfiguration"
        subnet_id                       = azurerm_subnet.tf2subnet.id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.tf2publicip.id
    }
}

resource "azurerm_network_interface_security_group_association" "tf2nsga" {
    network_interface_id                = azurerm_network_interface.tf2nic.id
    network_security_group_id           = azurerm_network_security_group.tf2nsg.id
}

resource "random_id" "randomId" {
    keepers = {
        resource_group = azurerm_resource_group.tf2group.name
    }
    
    byte_length = 8
}

resource "azurerm_storage_account" "tf2bootdiag" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.tf2group.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

# Create VM using Ubuntu 18.04 LTS
resource "azurerm_linux_virtual_machine" "tf2vm" {
    name                  = "TF2Server"
    location              = var.location
    resource_group_name   = azurerm_resource_group.tf2group.name
    network_interface_ids = [azurerm_network_interface.tf2nic.id]
    size                  = var.vm_size

    os_disk {
        name              = "OSDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "TF2Server"
    admin_username = "tf2oeadmin"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = var.vm_admin
        public_key     = var.publickey
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.tf2bootdiag.primary_blob_endpoint
    }

    #provisioner "local-exec" {
    #    command = "sleep 120; ansible-playbook -i '${azurerm_public_ip.tf2publicip.ip_address}' -u '${var.vm_admin}' ../ansible/playbook.yml"
    #}
}

# Output IP address for DNS
output "public_ip_address" {
    value = azurerm_public_ip.tf2publicip.ip_address
}
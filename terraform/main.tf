provider "azurerm" {
    version     = "~>2.0"
    features {}

    subscription_id     = ""
    client_id           = ""
    client_secret       = ""
    tenant_id           = ""
}

resource "azurerm_resource_group" "tf2group" {
    name        = "TF2Server"
    location    = "Australia East"
}

resource "azurerm_virtual_network" "tf2network" {
    name                    = "TF2"
    address_space           = ["10.90.0.0/16"]
    location                = "Australia East"
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
    location                = "Australia East"
    resource_group_name     = azurerm_resource_group.tf2group.name
    allocation_method       = "Static"
}

resource "azurerm_network_security_group" "tf2nsg" {
    name                    = "TF2NSG"
    location                = "Australia East"
    resource_group_name     = azurerm_resource_group.tf2group.name

    security_rule {
        name                        = "SSH"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "22"
        source_address_prefix       = "*"
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
    location                = "Australia East"
    resource_group_name     = azurerm_resource_group.tf2group.name

    ip_configuration {
        name                            = "TF2NicConfiguration"
        subnet_id                       = azurerm_subnet.tf2subnet.id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.tf2publicip.id
    }
}

resource "azurerm_network_interface_security_group_association" "tf2nsga" {
    network_interface_id                = azurerm.azurerm_network_interface.tf2nic.id
    azurerm_network_security_group_id   = azurerm_network_security_group.tf2nsg.id
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
    location                    = "Australia East"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

resource "azurerm_linux_virtual_machine" "tf2vm" {
    name                  = "TF2Server"
    location              = "Australia East"
    resource_group_name   = azurerm_resource_group.tf2group.name
    network_interface_ids = [azurerm.azurerm_network_interface.tf2nic.id]
    size                  = "Standard_B1ms"

    os_disk {
        name              = "OSDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "TF2Server"
    admin_username = "binchicken"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = "binchicken"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEArlfEusjNcmeytxajGwedYTIhvkoOxnA5lD0F
IcpeAeXjvcQRGdSAy5SX1i5vXMa3jPbElXwmVWDgQ/Vdm5O19dRmv+E91LUynY5R
tgTDKzvcRrTCb/9NhM89juDIRyGyetWLwyOmQEz04gcbaQZLhl427t/mSyohhUtd
388a6sWeupmr8cEx3e7w00bGFqBZJuXn02rp9SoBMX7RCnDlPQlWJta6/Uylvjvs
hHgUCeAy6sqMeMAzRILf5wwwS4QqM8hf1rtyk/9oWSnqv4PS/slYOZdWdCpRX4nZ
wXHgjIimFrXKHzrZoFeKXtYcqPWm74YGfLBroSobFZPJ84WB/Q=="
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.tf2bootdiag.primary_blob_endpoint
    }
}
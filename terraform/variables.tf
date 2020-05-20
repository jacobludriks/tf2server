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
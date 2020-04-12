1. Install Terraform and Ansible
2. Configure your variables for Terraform:

```
subscription_id = "<Subscription ID>"
tenant_id = "<Tenant ID>"
client_id = "<Client ID>"
client_secret = "<Client Secret>"
publickey = "<SSH Public Key>"
my_public_ip = "Your IP Address"
```

3. Initialize Terraform

`terraform init`

4. Create Terraform plan

`terraform plan -var-file="/mnt/c/terraform/variables.tfvars"`

5. Apply (deploy) Terraform plan

`terraform apply -var-file="/mnt/c/terraform/variables.tfvars"`

6. Once completed, add the server to Ansible hosts in `/etc/ansible/hosts`

```
all:
  hosts:
    test.tf2oe.com:
      ansible_connection: ssh
      ansible_user: tf2oeadmin
```

7. Test connection in Ansible

`ansible -m ping test.tf2oe.com`

8. Apply Ansible configuration

`ansible-playbook ../ansible/playbook.yml --extra-vars "target=test.tf2oe.com"`
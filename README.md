1. Install Terraform and Ansible
2. Configure your variables for Terraform:

- subscription_id
- tenant_id
- client_id
- client_secret
- publickey
- my_public_ip

3. terraform init
4. terraform apply -var-file="/mnt/c/terraform/variables.tfvars"
5. terraform apply -var-file="/mnt/c/terraform/variables.tfvars"
6. Add the server to Ansible hosts, ie:

all:
  hosts:
    test.tf2oe.com:
      ansible_connection: ssh
      ansible_user: tf2oeadmin

7. Test connection:

ansible -m ping test.tf2oe.com

8. Apply config

ansible-playbook ../ansible/playbook.yml --extra-vars "target=test.tf2oe.com"


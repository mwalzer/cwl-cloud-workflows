# as set in portal env
export PORTAL_APP_REPO_FOLDER="/data"
export PORTAL_DEPLOYMENTS_ROOT="/deployments"
export PORTAL_DEPLOYMENT_REFERENCE="deployment-reference"

export APP="${PORTAL_APP_REPO_FOLDER}"
echo "export APP=${APP}"
export DPL="${PORTAL_DEPLOYMENTS_ROOT}/${PORTAL_DEPLOYMENT_REFERENCE}/"
echo "export DPL=${DPL}"

mkdir -p ${DPL}
export TF_VAR_username=${OS_USERNAME} 
export TF_VAR_password=${OS_PASSWORD} 
export TF_VAR_tenant=${OS_TENANT_NAME}
export TF_VAR_auth_url=${OS_AUTH_URL}

# Private Key
export PRIV_KEY_PATH="/home/user/.ssh/id_rsa"
echo "export PRIV_KEY_PATH=${PRIV_KEY_PATH}"
export PRIVATE_KEY="/home/user/.ssh/id_rsa"
echo "export PRIVATE_KEY=${PRIVATE_KEY}"

# Public Key
export KEY_PATH="/home/user/.ssh/id_rsa.pub"
echo "export KEY_PATH=${KEY_PATH}"
export PUBLIC_KEY="/home/user/.ssh/id_rsa.pub"
echo "export PUBLIC_KEY=${PUBLIC_KEY}"


export TF_VAR_ansible_bastion_template_dir_path=${APP}'/terraform'
export TF_VAR_ansible_group_vars_dir_path=${DPL}'/group_vars'

export TF_VAR_cluster_name="clustertest"
export TF_VAR_number_of_etcd="0"
export TF_VAR_number_of_masters="1"
export TF_VAR_number_of_masters_no_floating_ip="0"
export TF_VAR_number_of_masters_no_etcd="0"
export TF_VAR_number_of_masters_no_floating_ip_no_etcd="0"
export TF_VAR_number_of_nodes_no_floating_ip="2"
export TF_VAR_number_of_nodes="0"
export TF_VAR_flavor_node="11"
export TF_VAR_flavor_master="11"
export TF_VAR_public_key_path=$PUBLIC_KEY
export TF_VAR_image="Ubuntu16.04"
export TF_VAR_ssh_user="ubuntu"
export TF_VAR_network_name="Elixir-Proteomics_private"
export TF_VAR_floatingip_pool="ext-net-37"

# GlusterFS variables
export TF_VAR_flavor_gfs_node="11"
export TF_VAR_image_gfs="Ubuntu16.04"
export TF_VAR_number_of_gfs_nodes_no_floating_ip="0" # was 3, gfs now on nodes ...
export TF_VAR_gfs_volume_size_in_gb="30"
export TF_VAR_ssh_user_gfs="ubuntu"

#Terraform clusterspray
cp -r ${APP}'/terraform/openstack/group_vars' ${DPL}'/group_vars'  # this needs to be tighter controlled for overwriting to achieve idempotency
cp ${APP}'/terraform/terraform.py' ${DPL}'/terraform.py'
terraform apply --state=${DPL}'terraform.tfstate' ${APP}'/terraform/openstack'
export TERRAFORM_STATE_ROOT=${DPL}

ansible-galaxy install --force -r ${APP}'/ansible/requirements.yml'

# so we still have the problem of ssh-agent in case of proxycommand use with 
# ansible and a dynamic inventory. 
#https://tech.ga.gov.au/dynamic-inventory-ansible-behind-a-jumpbox-bastion-5c04a3e4b354
#https://blog.scottlowe.org/2015/12/24/running-ansible-through-ssh-bastion-host/
#https://heipei.io/2015/02/26/SSH-Agent-Forwarding-considered-harmful/
#

export ANSIBLE_HOST_KEY_CHECKING=False
eval "$(ssh-agent -s)"
ssh-add $PRIV_KEY_PATH

ansible-playbook -b --become-user=root \
    -i ${DPL}'/terraform.py'\
    ${APP}'/ansible/playbook.yml' \
    --key-file "$PRIV_KEY_PATH" \
    -e host_key_checking=false \
    -e bootstrap_os=ubuntu

# Set default value for Ansible variables if they are either empty or undefined
export ANSIBLE_REMOTE_USER="${TF_VAR_remote_user:-ubuntu}"
echo "export ANSIBLE_REMOTE_USER=${ANSIBLE_REMOTE_USER}"

# Launch Ansible playbook
echo -e "\n\t${CYAN}Launch Ansible playbook${NC}\n"
ansible-playbook -b playbook.yml
echo -e "PROTAL VARS"
echo -e "${PORTAL_CALLBACK_SECRET}"
echo -e "${PORTAL_BASE_URL}"
                                                         

# terraform destroy --force --input=false --state=${DPL}'terraform.tfstate'
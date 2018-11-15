#!/usr/bin/env bash
###############
# BASH SETTINGS
###############
# Set color variable
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# exit immediately when a command fails, not allow unset variables
set -euoE pipefail
#set -euoEx pipefail  #debug mode: print each command before executing

###############
# VARIABLES
###############
# Variables inject by the portal
# PORTAL_APP_REPO_FOLDER
# PORTAL_DEPLOYMENTS_ROOT
# PORTAL_DEPLOYMENT_REFERENCE

# Local variables
# Export input variables in the bash environment

### Short variables
# Git cloned application folder
export APP="${PORTAL_APP_REPO_FOLDER}"
echo "export APP=${APP}"
# Deployment folder
export DPL="${PORTAL_DEPLOYMENTS_ROOT}/${PORTAL_DEPLOYMENT_REFERENCE}/"
echo "export DPL=${DPL}"

### Keys variables
# Private Key
export PRIV_KEY_PATH="${DPL}${PORTAL_DEPLOYMENT_REFERENCE}"
echo "export PRIV_KEY_PATH=${PRIV_KEY_PATH}"
# Public Key
export KEY_PATH="${DPL}${PORTAL_DEPLOYMENT_REFERENCE}.pub"
echo "export KEY_PATH=${KEY_PATH}"

### Terraform variables
### can be references in Terraform without the `TF_VAR_` prefix
export TF_VAR_deployment_path="${PORTAL_DEPLOYMENTS_ROOT}/${PORTAL_DEPLOYMENT_REFERENCE}"
echo "export TF_VAR_deployment_path=${TF_VAR_deployment_path}"
export TF_VAR_name="$(awk -v var="${PORTAL_DEPLOYMENT_REFERENCE}" 'BEGIN {print tolower(var)}')"
echo "export TF_VAR_name=${TF_VAR_name}"
export TF_VAR_key_path="${KEY_PATH}"
echo "export TF_VAR_key_path=${TF_VAR_key_path}"
export TF_STATE=${DPL}'terraform.tfstate'
echo "export TF_STATE=${TF_STATE}"

###############
# TERRAFORM
###############
# Provision cloud resources
echo -e "\n\t${CYAN}Terraform apply${NC}\n"
terraform apply --state=${DPL}'terraform.tfstate' ${APP}'/terraform'

# Extract runtime variables using terraform output
external_ip=$(terraform output -state=${DPL}'terraform.tfstate' external_ip)
###############
# ANSIBLE
###############
# Install Ansible requirements with ansible galaxy
echo -e "\n\t${CYAN}Install Ansible requirements with ansible galaxy${NC}\n"
cd ${APP}'/terraform' || exit
ansible-galaxy install --force -r requirements.yml
  
ansible-playbook -b --become-user=root \
    -i ${DPL}'/terraform.py' \
    ${APP}'/ansible/glusterfs/glusterfs.yml' \
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

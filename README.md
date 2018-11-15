# EMBL-EBI Cloud Portal - cluster template

___

## Requirements
A network is expected to be shared with other virtual machines, therefore is not provided and destroyed with this terraform description.
You need to set up the name of the network inside of the terraform.tfvars file.
If you want to provide a new network you can use the cpa-network terraform description.

### Ansible roles
Ansible Galaxy:

https://galaxy.ansible.com/geerlingguy/docker
https://galaxy.ansible.com/geerlingguy/glusterfs
https://galaxy.ansible.com/grycap/slurm

https://www.nextflow.io/docs/latest/executor.html#slurm
https://www.nextflow.io/docs/latest/docker.html#multiple-containers
https://www.nextflow.io/docs/latest/amazons3.html
https://www.nextflow.io/docs/latest/getstarted.html

## :shipit:
<sub>This is a template for applications in the [EMBL-EBI Cloud Portal](https://portal.tsi.ebi.ac.uk)</sub>
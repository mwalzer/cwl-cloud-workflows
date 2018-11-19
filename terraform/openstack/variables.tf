variable "cluster_name" {
  default = "example"
}

variable "number_of_masters" {
  default = 2
}

variable "number_of_masters_no_etcd" {
  default = 2
}

variable "number_of_etcd" {
  default = 2
}

variable "number_of_masters_no_floating_ip" {
  default = 2
}

variable "number_of_masters_no_floating_ip_no_etcd" {
  default = 2
}

variable "number_of_nodes" {
  default = 1
}

variable "number_of_nodes_no_floating_ip" {
  default = 1
}

variable "number_of_gfs_nodes_no_floating_ip" {
  default = 0
}

variable "gfs_volume_size_in_gb" {
  default = 75
}

variable "public_key_path" {
  description = "The path of the ssh pub key"
  default = "~/.ssh/id_rsa.pub"
}

variable "image" {
  description = "The image to use for node and master instances"
  default = "ubuntu-14.04"
}

variable "image_gfs" {
  description = "The image to use for GlusterFS instances"
  default = "ubuntu-16.04"
}

variable "ssh_user" {
  description = "used to fill out tags for ansible inventory"
  default = "ubuntu"
}

variable "ssh_user_gfs" {
  description = "used to fill out tags for ansible inventory"
  default = "ubuntu"
}

variable "flavor_master" {
  default = 3
}

variable "flavor_node" {
  default = 3
}

variable "flavor_etcd" {
  default = 3
}

variable "flavor_gfs_node" {
  default = 3
}

variable "network_name" {
  description = "name of the internal network to use"
  default = "internal"
}

variable "floatingip_pool" {
  description = "name of the floating ip pool to use"
  default = "external"
}

variable "username" {
  description = "Your openstack username"
}

variable "password" {
  description = "Your openstack password"
}

variable "tenant" {
  description = "Your openstack tenant/project"
}

variable "auth_url" {
  description = "Your openstack auth URL"
}

variable "ansible_bastion_template_dir_path" {
  default = "/tmp"
}

variable "ansible_group_vars_dir_path" {
  default = "/tmp"
}
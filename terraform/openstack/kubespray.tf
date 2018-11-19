resource "openstack_networking_floatingip_v2" "master" {
    count = "${var.number_of_masters + var.number_of_masters_no_etcd}"
    pool = "${var.floatingip_pool}"
}

resource "openstack_networking_floatingip_v2" "node" {
    count = "${var.number_of_nodes}"
    pool = "${var.floatingip_pool}"
}


resource "openstack_compute_keypair_v2" "cluster" {
    name = "${var.cluster_name}"
    public_key = "${file(var.public_key_path)}"
}

resource "openstack_compute_secgroup_v2" "master" {
    name = "${var.cluster_name}-masters"
    description = "${var.cluster_name} - Master"
}

resource "openstack_compute_secgroup_v2" "cluster" {
    name = "${var.cluster_name}-nodes"
    description = "${var.cluster_name} - Nodes"
    rule {
        ip_protocol = "tcp"
        from_port = "22"
        to_port = "22"
        cidr = "0.0.0.0/0"
    }
    rule {
        ip_protocol = "icmp"
        from_port = "-1"
        to_port = "-1"
        cidr = "0.0.0.0/0"
    }
    rule {
        ip_protocol = "tcp"
        from_port = "1"
        to_port = "65535"
        self = true
    }
    rule {
        ip_protocol = "udp"
        from_port = "1"
        to_port = "65535"
        self = true
    }
    rule {
        ip_protocol = "icmp"
        from_port = "-1"
        to_port = "-1"
        self = true
    }
}

resource "openstack_compute_instance_v2" "master" {
    name = "${var.cluster_name}-master-${count.index+1}"
    count = "${var.number_of_masters}"
    image_name = "${var.image}"
    flavor_id = "${var.flavor_master}"
    key_pair = "${openstack_compute_keypair_v2.cluster.name}"
    network {
        name = "${var.network_name}"
    }
    security_groups = [ "${openstack_compute_secgroup_v2.master.name}",
                        "${openstack_compute_secgroup_v2.cluster.name}", 
			"Gluster" ]
    floating_ip = "${element(openstack_networking_floatingip_v2.master.*.address, count.index)}"
    metadata = {
        ssh_user = "${var.ssh_user}"
        clusterspray_groups = "etcd,master,node,cluster,vault"
    }
    
}

resource "openstack_compute_instance_v2" "master_no_etcd" {
    name = "${var.cluster_name}-master-ne-${count.index+1}"
    count = "${var.number_of_masters_no_etcd}"
    image_name = "${var.image}"
    flavor_id = "${var.flavor_master}"
    key_pair = "${openstack_compute_keypair_v2.cluster.name}"
    network {
        name = "${var.network_name}"
    }
    security_groups = [ "${openstack_compute_secgroup_v2.master.name}",
                        "${openstack_compute_secgroup_v2.cluster.name}", 
			"Gluster" ]
    floating_ip = "${element(openstack_networking_floatingip_v2.master.*.address, count.index + var.number_of_masters)}"
    metadata = {
        ssh_user = "${var.ssh_user}"
        clusterspray_groups = "master,node,cluster,vault"
    }
    
}

resource "openstack_compute_instance_v2" "etcd" {
    name = "${var.cluster_name}-etcd-${count.index+1}"
    count = "${var.number_of_etcd}"
    image_name = "${var.image}"
    flavor_id = "${var.flavor_etcd}"
    key_pair = "${openstack_compute_keypair_v2.cluster.name}"
    network {
        name = "${var.network_name}"
    }
    security_groups = [ "${openstack_compute_secgroup_v2.cluster.name}", 
				"Gluster" ]
    metadata = {
        ssh_user = "${var.ssh_user}"
        clusterspray_groups = "etcd,vault,no-floating"
    }
    provisioner "local-exec" {
        command = "sed s/USER/${var.ssh_user}/  ${var.ansible_bastion_template_dir_path}/ansible_bastion_template.txt | sed s/BASTION_ADDRESS/${element(openstack_networking_floatingip_v2.master.*.address, 0)}/ > ${var.ansible_group_vars_dir_path}/no-floating.yml"
    } 
}


resource "openstack_compute_instance_v2" "master_no_floating_ip" {
    name = "${var.cluster_name}-master-nf-${count.index+1}"
    count = "${var.number_of_masters_no_floating_ip}"
    image_name = "${var.image}"
    flavor_id = "${var.flavor_master}"
    key_pair = "${openstack_compute_keypair_v2.cluster.name}"
    network {
        name = "${var.network_name}"
    }
    security_groups = [ "${openstack_compute_secgroup_v2.master.name}",
                        "${openstack_compute_secgroup_v2.cluster.name}", 
			"Gluster" ]
    metadata = {
        ssh_user = "${var.ssh_user}"
        clusterspray_groups = "etcd,master,node,cluster,vault,no-floating"
    }
    provisioner "local-exec" {
        command = "sed s/USER/${var.ssh_user}/ ${var.ansible_bastion_template_dir_path}/ansible_bastion_template.txt | sed s/BASTION_ADDRESS/${element(openstack_networking_floatingip_v2.master.*.address, 0)}/ > ${var.ansible_group_vars_dir_path}/no-floating.yml"
    }
}

resource "openstack_compute_instance_v2" "master_no_floating_ip_no_etcd" {
    name = "${var.cluster_name}-master-ne-nf-${count.index+1}"
    count = "${var.number_of_masters_no_floating_ip_no_etcd}"
    image_name = "${var.image}"
    flavor_id = "${var.flavor_master}"
    key_pair = "${openstack_compute_keypair_v2.cluster.name}"
    network {
        name = "${var.network_name}"
    }
    security_groups = [ "${openstack_compute_secgroup_v2.master.name}",
                        "${openstack_compute_secgroup_v2.cluster.name}", 
			"Gluster" ]
    metadata = {
        ssh_user = "${var.ssh_user}"
        clusterspray_groups = "master,node,cluster,vault,no-floating"
    }
    provisioner "local-exec" {
        command = "sed s/USER/${var.ssh_user}/ ${var.ansible_bastion_template_dir_path}/ansible_bastion_template.txt | sed s/BASTION_ADDRESS/${element(openstack_networking_floatingip_v2.master.*.address, 0)}/ > ${var.ansible_group_vars_dir_path}/no-floating.yml"
    }
}


resource "openstack_compute_instance_v2" "node" {
    name = "${var.cluster_name}-node-${count.index+1}"
    count = "${var.number_of_nodes}"
    image_name = "${var.image}"
    flavor_id = "${var.flavor_node}"
    key_pair = "${openstack_compute_keypair_v2.cluster.name}"
    network {
        name = "${var.network_name}"
    }
    security_groups = ["${openstack_compute_secgroup_v2.cluster.name}", 
				"Gluster" ]
    floating_ip = "${element(openstack_networking_floatingip_v2.node.*.address, count.index)}"
    metadata = {
        ssh_user = "${var.ssh_user}"
        clusterspray_groups = "node,cluster,vault"
    }
}

resource "openstack_compute_instance_v2" "node_no_floating_ip" {
    name = "${var.cluster_name}-node-nf-${count.index+1}"
    count = "${var.number_of_nodes_no_floating_ip}"
    image_name = "${var.image}"
    flavor_id = "${var.flavor_node}"
    key_pair = "${openstack_compute_keypair_v2.cluster.name}"
    network {
        name = "${var.network_name}"
    }
    security_groups = ["${openstack_compute_secgroup_v2.cluster.name}", 
				"Gluster" ]
    metadata = {
        ssh_user = "${var.ssh_user}"
        clusterspray_groups = "node,cluster,vault,no-floating"
    }
    provisioner "local-exec" {
	command = "sed s/USER/${var.ssh_user}/ ${var.ansible_bastion_template_dir_path}/ansible_bastion_template.txt | sed s/BASTION_ADDRESS/${element(openstack_networking_floatingip_v2.master.*.address, 0)}/ > ${var.ansible_group_vars_dir_path}/no-floating.yml"        
    }
}

resource "openstack_blockstorage_volume_v2" "glusterfs_volume" {
  name = "${var.cluster_name}-gfs-nephe-vol-${count.index+1}"
  count = "${var.number_of_gfs_nodes_no_floating_ip}"
  description = "Non-ephemeral volume for GlusterFS"
  size = "${var.gfs_volume_size_in_gb}"
}

resource "openstack_compute_instance_v2" "glusterfs_node_no_floating_ip" {
    name = "${var.cluster_name}-gfs-node-nf-${count.index+1}"
    count = "${var.number_of_gfs_nodes_no_floating_ip}"
    image_name = "${var.image_gfs}"
    flavor_id = "${var.flavor_gfs_node}"
    key_pair = "${openstack_compute_keypair_v2.cluster.name}"
    network {
        name = "${var.network_name}"
    }
    security_groups = ["${openstack_compute_secgroup_v2.cluster.name}", 
				"Gluster" ]
    metadata = {
        ssh_user = "${var.ssh_user_gfs}"
        clusterspray_groups = "gfs-cluster,network-storage"
    }
    volume {
        volume_id = "${element(openstack_blockstorage_volume_v2.glusterfs_volume.*.id, count.index)}"
    }
    provisioner "local-exec" {
	command = "sed s/USER/${var.ssh_user}/ ${var.ansible_bastion_template_dir_path}/ansible_bastion_template.txt | sed s/BASTION_ADDRESS/${element(openstack_networking_floatingip_v2.master.*.address, 0)}/ > ${var.ansible_group_vars_dir_path}/gfs-cluster.yml"        
    }
}




#output "msg" {
#    value = "Your hosts are ready to go!\nYour ssh hosts are: ${join(", ", openstack_networking_floatingip_v2.k8s_master.*.address )}"
#}

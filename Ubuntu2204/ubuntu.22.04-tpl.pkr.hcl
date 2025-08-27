# 插件配置
packer {
  required_version = ">= 1.13.1"
  required_plugins {
    vsphere = {
      source  = "github.com/hashicorp/vsphere"
      version = ">= 1.4.2"
    }
  }
}

variable "vcenter_server"   { default = "vcsa.basic-ops.com" }
variable "vcenter_user"     { default = "administrator@basic-ops.com" }
variable "vcenter_password" { default = "Ops1q2w.com" }
variable "datacenter"       { default = "City Shanghai" }
variable "cluster"          { default = "Headquarters Core" }
variable "host"             { default = "172.16.1.51" }
variable "datastore"        { default = "Esxi-DataStore-01" }
variable "network"          { default = "VM Network" }
variable "folder"           { default = "Templates" }

locals { template_name = "ubuntu-2204-static-template-v1" }

source "vsphere-iso" "ubuntu" {
  // vCenter Server Endpoint Settings and Credentials
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_user
  password            = var.vcenter_password
  insecure_connection = true

  // vSphere Settings
  datacenter     = var.datacenter
  host           = var.host
  datastore      = var.datastore
  folder         = var.folder

  // Virtual Machine Settings
  vm_name        = local.template_name
  guest_os_type  = "ubuntu64Guest"
  firmware       = "bios"
  CPUs           = 1
  cpu_cores      = 2
  CPU_hot_plug   = false
  RAM            = 2048
  RAM_hot_plug   = false
  disk_controller_type = ["pvscsi"]
  storage {
    disk_size             = 51200 # 50GB
    disk_thin_provisioned = true
  }
  network_adapters {
    network      = var.network
    network_card = "vmxnet3"
  }
  notes          = "build ubuntu 22.04 template machine by packer"

  // iso configuration
  iso_url      = "file:///opt/packer/iso/ubuntu-22.04.5-live-server-amd64.iso"
  iso_checksum = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

  // Boot and Provisioning Settings
  http_directory      = "./http"
  http_ip             = "172.16.1.72"
  http_bind_address   = "0.0.0.0"
  http_port_min       = 8276
  http_port_max       = 8276
  boot_order          = "disk,cdrom"
  boot_wait           = "3s"
  boot_command = [
    "<wait3s>e<wait3s>",
    "<down><down><down><end><bs><bs><bs><bs><wait>",
    "ip=172.16.1.250::172.16.1.254:255.255.255.0:ubuntu2204:ens192:none nameserver=10.80.93.100 autoinstall ds='nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/' ---",
    "<wait3s>",
    "<F10>"
  ]
  ip_wait_timeout     = "30m"
  shutdown_command    = "echo 'Packer123!' | sudo -S shutdown -P now"

  // Communicator Settings and Credentials
  communicator        = "ssh"
  ssh_username        = "app"
  ssh_password        = "Packer123!"
  ssh_port            = 22
  ssh_timeout         = "60m"
  
  // Template and Content Library Settings
  convert_to_template = true
}

# 构建配置
build {
  sources = ["source.vsphere-iso.ubuntu"]

  provisioner "shell" {
    execute_command = "sudo -S bash -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "apt-get update",
      "apt-get install -y -qq iputils-ping telnet net-tools dnsutils nmap htop iotop iftop vim wget tree parted expect open-vm-tools cron tcpdump tmux ntp ntpdate",
      # Set ntp service
      "sed -i -e 's/0.ubuntu.pool.ntp.org/ntpsvc.basic-ops.com/g' /etc/ntp.conf",
      "sed -i '/ubuntu.pool.ntp.org/d' /etc/ntp.conf",
      "sed -i '/ntp.ubuntu.com/d' /etc/ntp.conf",
      "systemctl enable ntp",
      # add time sync to crontab
      "echo '00 1 * * * /usr/sbin/ntpdate -u ntpsvc.basic-ops.com > /dev/null 2>&1' >> /var/spool/cron/crontabs/root ",
      # add ansible id_rsa.pub to authorized_keys
      "mkdir -p /root/.ssh",
      "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC4Z5b7k8z9f5d1b5e3f8c9d2e4f6a7b8c9e0f1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8b' >> /root/.ssh/authorized_keys",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo su root -c \"mkdir -p /etc/cloud/cloud.cfg.d/\"",
      "sudo su root -c \"echo 'network: {config: disabled}' | tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg\"",
      "sudo su root -c \"rm -f /etc/netplan/*.yaml\"",
    ]
  }
}

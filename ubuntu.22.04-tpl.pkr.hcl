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

locals { template_name = "ubuntu-2204-static-template-v4" }

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
  CPUs           = 2
  cpu_cores      = 1
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
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo su root -c \"mkdir -p /etc/cloud/cloud.cfg.d/\"",
      # 禁止cloud-init进行网卡初始化，规避基于模板的二次虚拟机创建多网卡问题。
      "sudo su root -c \"echo 'network: {config: disabled}' | tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg\"",
      "sudo su root -c \"rm -f /etc/netplan/*.yaml\"",
    ]
  }
}

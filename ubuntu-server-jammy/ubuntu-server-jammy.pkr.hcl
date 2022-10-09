# Packer Template to create an Ubuntu Server on Proxmox

# Variable Definitions
variable "proxmox_api_url" {
    type = string
    default = env("PROXMOX_API_URL")
}

variable "proxmox_api_token_id" {
    type = string
    default = env("PROXMOX_API_TOKEN_ID")
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
    default = env("PROXMOX_API_TOKEN_SECRET")
}

# Resource Definiation for the VM Template
source "proxmox" "ubuntu-server-jammy" {
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true
    
    # VM General Settings
    node = "pve"
    vm_id = "999"
    vm_name = "ubuntu-server-jammy"
    template_description = "Ubuntu Server jammy Image"

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "local:iso/ubuntu-22.04.1-live-server-amd64.iso"
    # - or -
    # (Option 2) Download ISO
    #iso_url = "https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso"
    #iso_checksum = "10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"
    #iso_storage_pool = "local"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "10G"
        storage_pool = "local-lvm"
        storage_pool_type = "lvm"
        type = "scsi"
    }

    # VM CPU Settings
    cores = "1"
    
    # VM Memory Settings
    memory = "2048" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # PACKER Boot Commands
    boot_command = [
    "c<wait5>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' ",
    "<enter><wait>",
    "initrd /casper/initrd <enter><wait>",
    "boot<enter>"
    ]
    boot_key_interval = "30ms"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    # http_bind_address = "0.0.0.0"
    http_port_min = 8802
    http_port_max = 8802

    ssh_username = "ubuntu"

    # (Option 1) Add your Password here
    ssh_password = "ubuntu"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    # ssh_private_key_file = "~/.ssh/id_rsa"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-server-jammy"
    sources = ["source.proxmox.ubuntu-server-jammy"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo cloud-init clean",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo sync"
        ]
    }
}


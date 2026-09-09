variable "cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-d"
}

# Static access key for a service account with the storage.editor role.
# Used by the yandex_storage_bucket resource to create the application bucket.
variable "access_key" {
  description = "Static access key ID for Object Storage"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Static secret access key for Object Storage"
  type        = string
  sensitive   = true
}

variable "vm_user" {
  description = "Login user created on the VM via cloud-init"
  type        = string
  default     = "yc-user"
}

variable "ssh_public_key" {
  description = "SSH public key content placed on the VM for the vm_user"
  type        = string
}

variable "vm_cores" {
  description = "Number of vCPUs for the VM"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "RAM in GB for the VM"
  type        = number
  default     = 2
}

variable "vm_core_fraction" {
  description = "Guaranteed vCPU performance share (5/20/50/100)"
  type        = number
  default     = 20
}

variable "vm_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 15
}

variable "app_bucket_name" {
  description = "Name of the application Object Storage bucket"
  type        = string
}

variable "gateway_port" {
  description = "Public HTTP port for the Kittygram gateway"
  type        = number
  default     = 9000
}

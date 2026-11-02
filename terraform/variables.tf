variable "do_region" {
  type    = string
  default = "blr1"
}

variable "droplet_size" {
  type    = string
  default = "s-1vcpu-1gb"
}

variable "ssh_key_fingerprint" {
  type        = string
  description = "Fingerprint of an SSH public key already added to DigitalOcean"
}

variable "project_name" {
  type    = string
  default = "flashbox-assignment"
}

variable "environments" {
  type        = set(string)
  description = "One droplet is created per environment"
  default     = ["prod", "staging"]
}

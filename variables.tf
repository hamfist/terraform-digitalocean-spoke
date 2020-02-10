variable "base_url" {
  description = "Fully qualified https URL of the app"
}

variable "resource_prefix" {
  description = "Prefix prepended to resource names"
  default     = "spoke-"
}

variable "node_options" {
  description = "Value defined at build time and run time as NODE_OPTIONS"
  default     = "--max_old_space_size=8192"
}

variable "node_env" {
  description = "Value defined at build time and run time as NODE_ENV"
  default     = "production"
}

variable "port" {
  description = "TCP port used to communicate between droplet and load balancer"
  default     = "3000"
}

variable "droplet_size" {
  description = "Size value passed when provisioning app droplet"
  default     = "s-1vcpu-1gb"
}

variable "database_cluster_size" {
  description = "Size value passed when provisioning database cluster"
  default     = "db-s-1vcpu-1gb"
}

variable "database_cluster_node_count" {
  default = 1
}

variable "region" {
  description = "Region at which all resources will be provisioned"
  default     = "nyc1"
}

variable "ssh_keys" {
  type        = "list"
  description = "List of ssh public keys to pass to droplet provisioning"
}

variable "cert_private_key" {
  description = "Certificate key to use when defining th cert used with the load balancer"
}

variable "cert_leaf_certificate" {
  description = "Leaf certificate to use when defining the cert used with the load balancer"
}

variable "env" {
  type        = "map"
  description = "Arbitrary *additional* environment variables passed at build time and run time"
  default     = {}
}

terraform {
  required_providers {
    digitalocean = "~ 1.14"
  }
}

variable "server_name" {
  description = "Server name used in nginx config"
}

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
  description = "TCP port used to communicate between droplet and nginx"
  default     = "3000"
}

variable "droplet_size" {
  description = "Size value passed when provisioning app droplet"
  default     = "s-1vcpu-1gb"
}

variable "region" {
  description = "Region in which all resources will be provisioned"
  default     = "nyc1"
}

variable "ssh_keys" {
  type        = list
  description = "List of ssh public keys to pass to droplet provisioning"
}

variable "cert_private_key" {
  description = "Certificate key to pass to nginx"
}

variable "cert_certificate" {
  description = "Certificate with leaf and intermediates to pass to nginx"
}

variable "env" {
  type        = map
  description = "Arbitrary *additional* environment variables passed at build time and run time"
  default     = {}
}

resource "digitalocean_ssh_key" "app" {
  count      = length(var.ssh_keys)
  name       = "${var.resource_prefix}app-${count.index}"
  public_key = element(var.ssh_keys, count.index)
}

resource "digitalocean_droplet" "app" {
  image  = "ubuntu-18-04-x64"
  name   = "${var.resource_prefix}app"
  region = var.region
  size   = var.droplet_size

  ssh_keys = [digitalocean_ssh_key.app[*].id]
}

resource "digitalocean_floating_ip" "app" {
  droplet_id = digitalocean_droplet.app.id
  region     = digitalocean_droplet.app.region
}

resource "digitalocean_firewall" "app" {
  name = "pghdsa-spoke-app"

  droplet_ids = [digitalocean_droplet.app.id]

  dynamic "inbound_rule" {
    for_each = ["22", "80", "443"]
    content {
      protocol         = "tcp"
      port_range       = inbound_rule.value
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  dynamic "outbound_rule" {
    for_each = ["tcp", "udp"]
    content {
      protocol              = outbound_rule.value
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "random_string" "session_secret" {
  length  = 199
  special = false
}

resource "random_string" "pg_password" {
  length = 31
}

locals {
  env_map = merge({
    ASSETS_MAP_FILE   = "assets.json",
    ASSETS_DIR        = "./build/client/assets",
    BASE_URL          = var.base_url,
    DATABASE_URL      = "postgres://spoke:${random_string.pg_password.result}@127.0.0.1:5432/spoke",
    DB_HOST           = "localhost",
    DB_NAME           = "spoke",
    DB_PASSWORD       = random_string.pg_password.result,
    DB_PORT           = "5432",
    DB_TYPE           = "pg",
    DB_USER           = "spoke",
    DB_USE_SSL        = "true",
    JOBS_SAME_PROCESS = "1",
    NODE_ENV          = var.node_env,
    NODE_OPTIONS      = var.node_options,
    OUTPUT_DIR        = "./build",
    PORT              = var.port,
    REDIS_URL         = "redis://127.0.0.1:6379/0",
    SESSION_SECRET    = random_string.session_secret.result,
  }, var.env)
}

resource "null_resource" "app_provision" {
  triggers = {
    droplet_id            = digitalocean_droplet.app.id
    provision_script_sha1 = filesha1("spoke-app-provision")
    run_script_sha1       = filesha1("spoke-app-run")
    service_sha1          = filesha1("spoke.service")
    env_sha1 = sha1(join(";", [
      jsonencode(var.env),
      random_string.session_secret.result,
      var.base_url,
      var.node_env,
      var.node_options,
      var.port,
    ]))
  }

  connection {
    host = digitalocean_droplet.app.ipv4_address
  }

  provisioner "file" {
    source      = "spoke-app-provision"
    destination = "/tmp/spoke-app-provision"
  }

  provisioner "file" {
    source      = "spoke-app-run"
    destination = "/tmp/spoke-app-run"
  }

  provisioner "file" {
    content = templatefile("nginx-sites-default.conf.tpl", {
      server_name = var.server_name,
      port        = var.port,
    })
    destination = "/tmp/nginx-sites-default.conf"
  }

  provisioner "file" {
    content     = var.cert_certificate
    destination = "/tmp/spoke.crt"
  }

  provisioner "file" {
    content     = var.cert_private_key
    destination = "/tmp/spoke.key"
  }

  provisioner "file" {
    content = <<-ENV_TMPL
      %{for var in local.env_map~}
      ${var.0}='${var.1}'
      %{endfor~}
    ENV_TMPL

    destination = "/tmp/app.env"
  }

  provisioner "file" {
    source      = "spoke.service"
    destination = "/tmp/spoke.service"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /tmp/spoke-app-provision system0",
      "sudo -H -u spoke bash /tmp/spoke-app-provision spoke0",
      "bash /tmp/spoke-app-provision system1",
    ]
  }
}

output "droplet_urn" {
  value = digitalocean_droplet.app.urn
}

output "droplet_ipv4_address" {
  value = digitalocean_droplet.app.ipv4_address
}

output "floating_ip_address" {
  value = digitalocean_floating_ip.app.ip_address
}

output "floating_ip_urn" {
  value = digitalocean_floating_ip.app.urn
}

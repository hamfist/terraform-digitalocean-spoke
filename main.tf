/**
 * # `tf_digitalocean_spoke`
 * <!-- WARNING: this file is generated -->
 *
 * This is a terraform module that provisions a
 * [Spoke](https://github.com/MoveOnOrg/Spoke) instance at DigitalOcean.
 *
 * ## Terraform versions
 *
 * This module is compatible with Terraform version `0.13+`.
 *
 * ## Usage
 *
 * A typical production deployment that uses `PASSPORT_STRATEGY=auth0`,
 * `DEFAULT_SERVICE=twilio`, and a direct SMTP connection for email might look
 * like this:
 *
 * ```hcl
 * module "digitalocean_spoke" {
 *   source = "github.com/meatballhat/tf_digitalocean_spoke"
 *
 *   server_name      = "spoke.example.org"
 *   base_url         = "https://spoke.example.org"
 *   resource_prefix  = "example-spoke-"
 *   region           = "nyc1"
 *   ssh_keys         = [file("path/to/id_rsa.pub")]
 *   cert_private_key = file("path/to/cert.key")
 *   cert_certificate = file("path/to/cert.crt")
 *   env = {
 *     AUTH0_CLIENT_ID            = "8570285697946a0cc03f8049b9309d7e"
 *     AUTH0_CLIENT_SECRET        = "1194435d32479ab99ed51a0a5f244cd5"
 *     AUTH0_DOMAIN               = "example.auth0.com"
 *     EMAIL_FROM                 = "admin@example.org"
 *     EMAIL_HOST                 = "mail.example.org"
 *     EMAIL_HOST_PASSWORD        = "b5090d80c82e608a1acd2f59ac366083"
 *     EMAIL_HOST_PORT            = "123"
 *     EMAIL_HOST_SECURE          = "true"
 *     EMAIL_HOST_USER            = "admin"
 *     DEFAULT_SERVICE            = "twilio",
 *     PASSPORT_STRATEGY          = "auth0",
 *     PHONE_NUMBER_COUNTRY       = "US",
 *     SUPPRESS_SELF_INVITE       = "true",
 *     TWILIO_API_KEY             = "6babd5fa8226c66406edcce7390675b3"
 *     TWILIO_APPLICATION_SID     = "be2d8e141ab5b45287d06ee649c48b82"
 *     TWILIO_AUTH_TOKEN          = "17381f485e35f89608b88b45f5a00873"
 *     TWILIO_MESSAGE_SERVICE_SID = "b2b551ca3228aa8d130b5739e1a20cdd"
 *     TWILIO_STATUS_CALLBACK_URL = "https://callback.example.org"
 *   }
 * }
 * ```
 */

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 1.22"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable server_name {
  description = "Server name used in nginx config"
  type        = string
}

variable base_url {
  description = "Fully qualified https URL of the app"
  type        = string
}

variable resource_prefix {
  description = "Prefix prepended to resource names"
  default     = "spoke-"
  type        = string
}

variable node_options {
  description = "Value defined at build time and run time as NODE_OPTIONS"
  default     = "--max_old_space_size=8192"
  type        = string
}

variable node_env {
  description = "Value defined at build time and run time as NODE_ENV"
  default     = "production"
  type        = string
}

variable port {
  description = "TCP port used to communicate between droplet and nginx"
  default     = "3000"
  type        = string
}

variable droplet_image {
  description = "Image to use when provisioning app droplet"
  default     = "ubuntu-20-04-x64"
  type        = string
}

variable droplet_size {
  description = "Size value passed when provisioning app droplet"
  default     = "s-1vcpu-1gb"
  type        = string
}

variable region {
  description = "Region in which all resources will be provisioned"
  default     = "nyc1"
  type        = string
}

variable spoke_version {
  description = "Git ref of MoveOnOrg/Spoke to deploy"
  default     = "v8.0"
  type        = string
}

variable ssh_keys {
  type        = list(string)
  description = "List of ssh public keys to pass to droplet provisioning"
}

variable cert_private_key {
  description = "Certificate key to pass to nginx"
  type        = string
}

variable cert_certificate {
  description = "Certificate with leaf and intermediates to pass to nginx"
  type        = string
}

variable env {
  description = "Arbitrary *additional* environment variables passed at build time and run time"
  default     = {}
  type        = map(string)
}

resource digitalocean_ssh_key app {
  count      = length(var.ssh_keys)
  name       = "${var.resource_prefix}app-${count.index}"
  public_key = element(var.ssh_keys, count.index)
}

resource digitalocean_droplet app {
  image  = var.droplet_image
  name   = "${var.resource_prefix}app"
  region = var.region
  size   = var.droplet_size

  ssh_keys = digitalocean_ssh_key.app[*].id
}

resource digitalocean_floating_ip app {
  droplet_id = digitalocean_droplet.app.id
  region     = digitalocean_droplet.app.region
}

resource digitalocean_firewall app {
  name = "pghdsa-spoke-app"

  droplet_ids = [digitalocean_droplet.app.id]

  dynamic inbound_rule {
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

  dynamic outbound_rule {
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

resource random_string session_secret {
  length  = 199
  special = false
}

resource random_string pg_password {
  length = 31
}

locals {
  env_map = merge({
    ASSETS_MAP_FILE         = "assets.json",
    ASSETS_DIR              = "./build/client/assets",
    BASE_URL                = var.base_url,
    DATABASE_URL            = "postgres://spoke:${random_string.pg_password.result}@127.0.0.1:5432/spoke",
    DB_HOST                 = "localhost",
    DB_NAME                 = "spoke",
    DB_PASSWORD             = random_string.pg_password.result,
    DB_PORT                 = "5432",
    DB_TYPE                 = "pg",
    DB_USER                 = "spoke",
    DB_USE_SSL              = "true",
    JOBS_SAME_PROCESS       = "1",
    NODE_ENV                = var.node_env,
    NODE_OPTIONS            = var.node_options,
    OUTPUT_DIR              = "./build",
    PORT                    = var.port,
    REDIS_URL               = "redis://127.0.0.1:6379/0",
    SESSION_SECRET          = random_string.session_secret.result,
    TERRAFORM_SPOKE_VERSION = var.spoke_version,
  }, var.env)
}

resource null_resource app_provision {
  triggers = {
    droplet_id            = digitalocean_droplet.app.id
    provision_script_sha1 = filesha1("${path.module}/spoke-app-provision")
    run_script_sha1       = filesha1("${path.module}/spoke-app-run")
    service_sha1          = filesha1("${path.module}/spoke.service")
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

  provisioner file {
    source      = "${path.module}/spoke-app-provision"
    destination = "/tmp/spoke-app-provision"
  }

  provisioner file {
    source      = "${path.module}/spoke-app-run"
    destination = "/tmp/spoke-app-run"
  }

  provisioner file {
    content = templatefile("${path.module}/nginx-sites-default.conf.tpl", {
      server_name = var.server_name,
      port        = var.port,
    })
    destination = "/tmp/nginx-sites-default.conf"
  }

  provisioner file {
    content     = var.cert_certificate
    destination = "/tmp/spoke.crt"
  }

  provisioner file {
    content     = var.cert_private_key
    destination = "/tmp/spoke.key"
  }

  provisioner file {
    content = <<-ENVTMPL
%{for key, value in local.env_map~}
${key}='${value}'
%{endfor~}
ENVTMPL

    destination = "/tmp/app.env"
  }

  provisioner file {
    source      = "${path.module}/spoke.service"
    destination = "/tmp/spoke.service"
  }

  provisioner remote-exec {
    inline = [
      "bash /tmp/spoke-app-provision system0",
      "sudo -H -u spoke bash /tmp/spoke-app-provision spoke0",
      "bash /tmp/spoke-app-provision system1",
    ]
  }
}

output droplet_urn {
  description = "urn of the droplet suitable for adding to project resources"
  value       = digitalocean_droplet.app.urn
}

output droplet_ipv4_address {
  description = "ipv4 address of the droplet"
  value       = digitalocean_droplet.app.ipv4_address
}

output floating_ip_address {
  description = "floating IP address assigned to the droplet suitable for creating a DNS A record"
  value       = digitalocean_floating_ip.app.ip_address
}

output floating_ip_urn {
  description = "urn of the floating IP address assigned to the droplet suitable for adding to project resources"
  value       = digitalocean_floating_ip.app.urn
}

// vim:filetype=terraform

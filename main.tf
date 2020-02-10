resource "digitalocean_ssh_key" "app" {
  count      = length(var.ssh_keys)
  name       = "${var.resource_prefix}app-${count.index}"
  public_key = element(var.ssh_keys, count.index)
}

resource "digitalocean_database_cluster" "pg" {
  name       = "${var.resource_prefix}pg"
  engine     = "pg"
  version    = "11"
  size       = var.database_cluster_size
  region     = var.region
  node_count = 1
}

resource "digitalocean_droplet" "app" {
  image  = "ubuntu-18-04-x64"
  name   = "${var.resource_prefix}app"
  region = var.region
  size   = var.droplet_size

  ssh_keys = [digitalocean_ssh_key.app.*.id]
}

resource "digitalocean_certificate" "app" {
  name             = "${var.resource_prefix}app"
  private_key      = var.cert_private_key
  leaf_certificate = var.cert_leaf_certificate

  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_loadbalancer" "app" {
  name                   = "${var.resource_prefix}lb-app"
  region                 = var.region
  droplet_ids            = [digitalocean_droplet.app.id]
  redirect_http_to_https = true

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = var.port
    target_protocol = "http"
  }

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = var.port
    target_protocol = "http"

    certificate_id = digitalocean_certificate.app.id
  }

  healthcheck {
    port     = var.port
    protocol = "tcp"
  }
}

resource "digitalocean_firewall" "app" {
  name = "${var.resource_prefix}app"

  droplet_ids = [digitalocean_droplet.app.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol   = "tcp"
    port_range = "1-65535"
    # FIXME: what
    #port_range                = var.port
    source_load_balancer_uids = [digitalocean_loadbalancer.app.id]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
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

resource "null_resource" "app_provision" {
  triggers = {
    droplet_id            = digitalocean_droplet.app.id
    database_cluster_id   = digitalocean_database_cluster.pg.id
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
    content = templatefile("app.env.tpl", merge({
      ASSETS_MAP_FILE   = "assets.json",
      ASSETS_DIR        = "./build/client/assets",
      BASE_URL          = var.base_url,
      DATABASE_URL      = digitalocean_database_cluster.pg.uri,
      DB_HOST           = digitalocean_database_cluster.pg.host,
      DB_NAME           = digitalocean_database_cluster.pg.database,
      DB_PASSWORD       = digitalocean_database_cluster.pg.password,
      DB_PORT           = digitalocean_database_cluster.pg.port,
      DB_TYPE           = "pg",
      DB_USER           = digitalocean_database_cluster.pg.user,
      DB_USE_SSL        = "true",
      JOBS_SAME_PROCESS = "1",
      NODE_ENV          = var.node_env,
      NODE_OPTIONS      = var.node_options,
      OUTPUT_DIR        = "./build",
      PORT              = var.port,
      REDIS_URL         = "redis://127.0.0.1:6379/0",
      SESSION_SECRET    = random_string.session_secret.result,
    }, var.env))
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

resource "digitalocean_database_firewall" "app_pg" {
  cluster_id = digitalocean_database_cluster.pg.id

  rule {
    type  = "droplet"
    value = digitalocean_droplet.app.id
  }
}

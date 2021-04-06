# `tf_digitalocean_spoke`
<!-- WARNING: this file is generated -->

This is a terraform module that provisions a
[Spoke](https://github.com/MoveOnOrg/Spoke) instance at DigitalOcean.

## Terraform versions

This module is compatible with Terraform version `0.13+`.

## Usage

A typical production deployment that uses `PASSPORT_STRATEGY=auth0`,
`DEFAULT_SERVICE=twilio`, and a direct SMTP connection for email might look
like this:

```hcl
module "digitalocean_spoke" {
  source = "github.com/meatballhat/tf_digitalocean_spoke"

  server_name      = "spoke.example.org"
  base_url         = "https://spoke.example.org"
  resource_prefix  = "example-spoke-"
  region           = "nyc1"
  ssh_keys         = [file("path/to/id_rsa.pub")]
  cert_private_key = file("path/to/cert.key")
  cert_certificate = file("path/to/cert.crt")
  env = {
    AUTH0_CLIENT_ID            = "8570285697946a0cc03f8049b9309d7e"
    AUTH0_CLIENT_SECRET        = "1194435d32479ab99ed51a0a5f244cd5"
    AUTH0_DOMAIN               = "example.auth0.com"
    EMAIL_FROM                 = "admin@example.org"
    EMAIL_HOST                 = "mail.example.org"
    EMAIL_HOST_PASSWORD        = "b5090d80c82e608a1acd2f59ac366083"
    EMAIL_HOST_PORT            = "123"
    EMAIL_HOST_SECURE          = "true"
    EMAIL_HOST_USER            = "admin"
    DEFAULT_SERVICE            = "twilio",
    PASSPORT_STRATEGY          = "auth0",
    PHONE_NUMBER_COUNTRY       = "US",
    SUPPRESS_SELF_INVITE       = "true",
    TWILIO_API_KEY             = "6babd5fa8226c66406edcce7390675b3"
    TWILIO_APPLICATION_SID     = "be2d8e141ab5b45287d06ee649c48b82"
    TWILIO_AUTH_TOKEN          = "17381f485e35f89608b88b45f5a00873"
    TWILIO_MESSAGE_SERVICE_SID = "b2b551ca3228aa8d130b5739e1a20cdd"
    TWILIO_STATUS_CALLBACK_URL = "https://callback.example.org"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_digitalocean"></a> [digitalocean](#requirement\_digitalocean) | >= 1.22 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_digitalocean"></a> [digitalocean](#provider\_digitalocean) | >= 1.22 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [digitalocean_droplet.app](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet) | resource |
| [digitalocean_firewall.app](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/firewall) | resource |
| [digitalocean_floating_ip.app](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/floating_ip) | resource |
| [digitalocean_ssh_key.app](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/ssh_key) | resource |
| [null_resource.app_provision](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.pg_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.session_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_base_url"></a> [base\_url](#input\_base\_url) | Fully qualified https URL of the app | `string` | n/a | yes |
| <a name="input_cert_certificate"></a> [cert\_certificate](#input\_cert\_certificate) | Certificate with leaf and intermediates to pass to nginx | `string` | n/a | yes |
| <a name="input_cert_private_key"></a> [cert\_private\_key](#input\_cert\_private\_key) | Certificate key to pass to nginx | `string` | n/a | yes |
| <a name="input_droplet_image"></a> [droplet\_image](#input\_droplet\_image) | Image to use when provisioning app droplet | `string` | `"ubuntu-20-04-x64"` | no |
| <a name="input_droplet_size"></a> [droplet\_size](#input\_droplet\_size) | Size value passed when provisioning app droplet | `string` | `"s-1vcpu-1gb"` | no |
| <a name="input_env"></a> [env](#input\_env) | Arbitrary *additional* environment variables passed at build time and run time | `map(string)` | `{}` | no |
| <a name="input_nginx_site_override_conf"></a> [nginx\_site\_override\_conf](#input\_nginx\_site\_override\_conf) | Complete nginx site configuration override | `string` | `""` | no |
| <a name="input_node_env"></a> [node\_env](#input\_node\_env) | Value defined at build time and run time as NODE\_ENV | `string` | `"production"` | no |
| <a name="input_node_options"></a> [node\_options](#input\_node\_options) | Value defined at build time and run time as NODE\_OPTIONS | `string` | `"--max_old_space_size=8192"` | no |
| <a name="input_port"></a> [port](#input\_port) | TCP port used to communicate between droplet and nginx | `string` | `"3000"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region in which all resources will be provisioned | `string` | `"nyc1"` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix prepended to resource names | `string` | `"spoke-"` | no |
| <a name="input_server_name"></a> [server\_name](#input\_server\_name) | Server name used in nginx config | `string` | n/a | yes |
| <a name="input_spoke_version"></a> [spoke\_version](#input\_spoke\_version) | Git ref of MoveOnOrg/Spoke to deploy | `string` | `"v8.0"` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | List of ssh public keys to pass to droplet provisioning | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_droplet_ipv4_address"></a> [droplet\_ipv4\_address](#output\_droplet\_ipv4\_address) | ipv4 address of the droplet |
| <a name="output_droplet_urn"></a> [droplet\_urn](#output\_droplet\_urn) | urn of the droplet suitable for adding to project resources |
| <a name="output_floating_ip_address"></a> [floating\_ip\_address](#output\_floating\_ip\_address) | floating IP address assigned to the droplet suitable for creating a DNS A record |
| <a name="output_floating_ip_urn"></a> [floating\_ip\_urn](#output\_floating\_ip\_urn) | urn of the floating IP address assigned to the droplet suitable for adding to project resources |

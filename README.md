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
| terraform | >= 0.13 |
| digitalocean | >= 1.22 |

## Providers

| Name | Version |
|------|---------|
| digitalocean | >= 1.22 |
| null | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| base\_url | Fully qualified https URL of the app | `string` | n/a | yes |
| cert\_certificate | Certificate with leaf and intermediates to pass to nginx | `string` | n/a | yes |
| cert\_private\_key | Certificate key to pass to nginx | `string` | n/a | yes |
| droplet\_image | Image to use when provisioning app droplet | `string` | `"ubuntu-20-04-x64"` | no |
| droplet\_size | Size value passed when provisioning app droplet | `string` | `"s-1vcpu-1gb"` | no |
| env | Arbitrary *additional* environment variables passed at build time and run time | `map(string)` | `{}` | no |
| node\_env | Value defined at build time and run time as NODE\_ENV | `string` | `"production"` | no |
| node\_options | Value defined at build time and run time as NODE\_OPTIONS | `string` | `"--max_old_space_size=8192"` | no |
| port | TCP port used to communicate between droplet and nginx | `string` | `"3000"` | no |
| region | Region in which all resources will be provisioned | `string` | `"nyc1"` | no |
| resource\_prefix | Prefix prepended to resource names | `string` | `"spoke-"` | no |
| server\_name | Server name used in nginx config | `string` | n/a | yes |
| spoke\_version | Git ref of MoveOnOrg/Spoke to deploy | `string` | `"v8.0"` | no |
| ssh\_keys | List of ssh public keys to pass to droplet provisioning | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| droplet\_ipv4\_address | ipv4 address of the droplet |
| droplet\_urn | urn of the droplet suitable for adding to project resources |
| floating\_ip\_address | floating IP address assigned to the droplet suitable for creating a DNS A record |
| floating\_ip\_urn | urn of the floating IP address assigned to the droplet suitable for adding to project resources |


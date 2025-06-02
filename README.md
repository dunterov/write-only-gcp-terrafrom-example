# Example of Terraform write-only argument usage with GCP secret manager

This example project demonstrates how to use a feature introduced in Terraform version [1.11](https://developer.hashicorp.com/terraform/language/resources/ephemeral/write-only) with GCP secret manager secret. 

## Requirements

- GCP project
- Terraform v1.11+
- Google provider v6.23+

## Components

- main.tf: main file, contains `google_secret_manager_secret` and `google_secret_manager_secret_version`.
- versions.tf: required versions.
- variables.tf: where input variable declared.
- provider.tf: provider configuration.

## Key concept

Write-only arguments let you securely pass temporary values to Terraform's managed resources during an operation without persisting those values to state or plan files. 

*TL;DR* - now supported resources have two arguments - `<argument>_wo` and `<argument>_wo_version`. Terraform will use `<argument>_wo` in runtime but not store in the state or plan files. The `<argument>_wo_version` in turn is stored in state and used as trigger for Terraform to update resource.

This example shows to automate `<argument>_wo_version` management based on `<argument>_wo` but keep it secret.

## Explanation

This is a terraform resource `google_secret_manager_secret_version`. Before recent changes it would look like this:

```tf
resource "google_secret_manager_secret_version" "version" {
  secret                 = "some-secret-it"
  secret_data            = "my secret"
}
```

The `secret_data` would be stored "as is" in Terraform state which is not secure.
Now it's possible to use write-only approach with `secret_data_wo` and `secret_data_wo_version` arguments. 

```tf
variable "secret_string" {
  type    = string
  default = "my-secret"
}

resource "google_secret_manager_secret_version" "version" {
  secret                 = "some-secret-it"
  secret_data_wo         = var.secret_string
  secret_data_wo_version = parseint(substr(sha256(var.secret_string), 0, 4), 16)
}
```

Using this approach, value of `secret_data_wo` ("my secret") will not be stored in Terraform state. Insted, the `secret_data_wo_version` will be stored in state. However, it still will be in the Terraform code. To avoid this create file `terraform.tfstate` with the following content (good idea is to also add this file name to `.gitignore` file):

```tf
secret_string = "my-secret"
```

### More details

```tf
parseint(substr(sha256(var.secret_string), 0, 4), 16)
```

This expression generates a simple, deterministic numeric ID from secret string.

#### How it works:

1. Hashes var.secret_string with SHA-256
2. Grabs the first 4 hex characters (16 bits)
3. Converts that to a base-16 integer as a version number

This approach keeps things simple, avoids full hash management, and limits brute-force usefulness. It's just for detecting changes, not generating globally unique IDs.
This method is practical, predictable, and secure enough for most high-entropy secrets (like API keys or JWTs).

# IaC test
This terraform project deploys WordPress on AWS using ECS, a Load Balancer and EFS for permanent data.

## Pre-requisites

- AWS account with credentials in `~/.aws/credentials` to access the API.
- aws-cli installed.
- OpenTofu is installed (I am using the open source fork of Terraform, OpenTofu, however the code most probably runs in Terraform too. (Code tested in Bash / MacOS)

```
$ aws --version
aws-cli/2.32.20 Python/3.13.11 Darwin/24.6.0 source/arm64
$ tofu --version
OpenTofu v1.11.1
```

## Execute the code

1. You might want to update the email in `variables.tf` to receive the alerts there

```
tofu init
tofu apply
```

## Test WordPress installation

1. Use the URL obtained from previous step to access WordPress.

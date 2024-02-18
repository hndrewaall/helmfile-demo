# helmfile-demo

This is a simple demo application built with nginx, Helmfile, and Terraform. It demonstrates basic multi-node load balancing for web traffic.

## Prerequisites

### AWS credentials
The remainder of this document assumes the presence of AWS credentials with AdminRole or equivalent privileges, with tokens exported via environment variables in all shells. Use of aws-vault is recommended to manage these.

### Hosted Zone and TLS Certificates
The configuration in this repository relies on the AWS Load Balancer Controller and the External DNS Controller to automatically deploy and configure an Application Load Balancer along with corresponding Route53 DNS entries along with the cluster and application. To enable this, **there must already be present a Route53 Hosted Zone**, along with a corresponding **Certificate Manager TLS certificate**. By default, the application looks for the domain `andrewhall.work`, but this can be overridden ([see below](README.md#domain-override)).

### CLI Dependencies
Several CLI tools are used by the automation in this repo: Make, Terraform, Helm, Helmfile, and the AWS CLI. These can be installed via HomeBrew using the provided `make brew-deps` convenience function. However, these have only been tested on macOS Sonoma 14.2.1, and may require modification to work in other environments.

## Deployment
The entire stack can be deployed through a single call to `make all`. This will trigger the `terraform plan`/`apply`, as well as the `helmfile sync` needed to deploy the VPC, cluster, and Helm charts to support the application. **You will be prompted by terraform to answer `yes` when running the `apply`**.

### Domain Override
By default, this application deploys to `helmfile-demo.andrewhall.work`. The domain portion of this however can be overridden at deploy time using an environmental variable, as follows:

```bash
HELMFILE_DEMO_DOMAIN=dummy.org make all
```

Using this command, the application will become available at `helmfile-demo.dummy.org` (assuming the presence of a corresponding hosted zone, certificate, and correctly configured DNS registration).

## Cleanup
All deployed infrastructure (both Helm and Terraform) can be deleted by using `make clean`. **You will be prompted by terraform to answer `yes` when running the `destroy`**.

## Outstanding Issues

### Hardcoded AWS account ID
The AWS account ID is hardcoded in two of the Helm values files. These need to be updated for use with other accounts. However, it should be trivial to add an override via environmental variable comparable to what is already in place for domain name.

### Autoscaling
The cluster deployed does not include either horizontal pod autoscaling or cluster node scaling. Both would be needed to effectively scale the application to production workloads.

### HA
As configured, we do not have strong guarantees about high availability across the three availability zones we are provisioning in. To get this, we need to add additional replicas to the External DNS Controller and Load Balancer Controller, and add Topology Spread Constraints to their deployments, as well as that of the demo application itself.

### Environments
The application is only deployed to a single environment (tagged "Dev"). Before going live in production, we need at least one more separate environment ("Prod") to effectively separate live traffic from development impacts.

### State management
Currently, there is no configured mechanism for persisting Terraform state beyond the laptop of a single developer. Tools such as Atlantis, Terraform Cloud, or Spacelift could be used in conjunction with S3 buckets to manage access to Terraform state and plans/applies.

### Access management
Currently, Kubernetes API access is granted only to the credentials of the deploying user. Before this application can be worked on by multiple developers, separate developer IAM roles and corresponding Kubernetes access and authorization configuration is needed.

### Automatic reloading for nginx config
The `nginx` configuration used by the demo app is stored on a Kubernetes `ConfigMap`. While convenient, live updates to this are not reread dynamically by the `nginx` containers. There are a variety of tools available for configuring this behavior (using sidecars or dedicated controllers).

## Tips

### Plugin caching
As configured, the Makefile will remove the local Terraform cache when cleaning up. To prevent time-consuming module downloads, [configure a local TF provider cache](https://developer.hashicorp.com/terraform/cli/config/config-file#provider-plugin-cache).

### DNS TTL
When creating new DNS records, you can reduce iteration time by reducing the TTL of your `SOA` record to 60 seconds.

### aws-vault
AWS credential management on the console is much easier (and more secure!) using a tool like [aws-vault](https://github.com/99designs/aws-vault).

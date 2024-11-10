# CAST.AI Node Target Group Manager

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Add Helm Repository](#add-helm-repository)
  - [Configuration Options](#configuration-options)
  - [Installation Methods](#installation-methods)
    - [Method 1: Using values.yaml](#method-1-using-valuesyaml)
    - [Method 2: Using --set flags](#method-2-using---set-flags)
    - [Method 3: Using Terraform](#method-3-using-terraform)
- [Configuration Reference](#configuration-reference)


## Overview
The CAST.AI Node Target Group Manager is a Helm chart that helps manage node target groups in your Kubernetes cluster.

## Prerequisites
- Kubernetes cluster
- Helm v3+
- Base64 encoded CAST.AI API key
- Base64 encoded CAST.AI cluster ID
- AWS credentials configured
- (For Terraform installation) Terraform v1.0+
- IAM policy to the Node Role, which grants permissions to interact with Elastic Load Balancing and EC2 instances.

**IAM Policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
```
## Installation

### Add Helm Repository
```bash
helm repo add castai-charts https://ronakforcast.github.io/auto-tg-register-deploy/castai-setup/charts
helm repo update
```

### Configuration Options
There are three ways to configure the installation:

#### Option 1: Using values.yaml
Create a `values.yaml` file with your configuration:

```yaml
# Required Configuration
namespace: casta-agent
replicas: 2
apiKey: "your-base64-encoded-api-key"
clusterId: "your-base64-encoded-cluster-id"
awsRegion: "us-west-2"

# Optional Configuration
nodeSelector: {}
tolerations: []
```

#### Option 2: Using Command Line Arguments
You can pass configuration values directly through the command line using `--set` flags.

#### Option 3: Using Terraform Configuration
Create Terraform configuration files to manage the Helm release.

### Installation Methods

#### Method 1: Using values.yaml
```bash
helm install castai-node-manager castai-charts/castai-node-targetgroup-manager \
  --namespace casta-agent \
  --create-namespace \
  -f values.yaml
```

#### Method 2: Using --set flags
```bash
helm install castai-node-manager castai-charts/castai-node-targetgroup-manager \
  --namespace casta-agent \
  --create-namespace \
  --set namespace=casta-agent \
  --set replicas=2 \
  --set apiKey="your-base64-encoded-api-key" \
  --set clusterId="your-base64-encoded-cluster-id" \
  --set awsRegion="us-west-2" \
  --set nodeSelector={} \
  --set tolerations="[]"
```

#### Method 3: Using Terraform
Create the following Terraform files:

1. `versions.tf`:
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10.0"
    }
  }
}
```

2. `providers.tf`:
```hcl
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"  # Or use other authentication methods
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"    # Or use other authentication methods
}
```

3. `main.tf`:
```hcl
resource "kubernetes_namespace" "casta_agent" {
  metadata {
    name = "casta-agent"
  }
}

resource "helm_release" "castai_node_manager" {
  name       = "castai-node-manager"
  repository = "https://ronakforcast.github.io/auto-tg-register-deploy/castai-setup/charts"
  chart      = "castai-node-targetgroup-manager"
  namespace  = kubernetes_namespace.casta_agent.metadata[0].name

  # Required Values
  set {
    name  = "apiKey"
    value = "your-base64-encoded-api-key"
  }

  set {
    name  = "clusterId"
    value = "your-base64-encoded-cluster-id"
  }

  set {
    name  = "awsRegion"
    value = "us-west-2"
  }

  set {
    name  = "replicas"
    value = "2"
  }

  # Optional Values
  set {
    name  = "nodeSelector"
    value = "{}"
  }

  set {
    name  = "tolerations"
    value = "[]"
  }
}
```

4. Deploy using Terraform:
```bash
terraform init
terraform plan
terraform apply
```

To destroy the deployment:
```bash
terraform destroy
```

## Configuration Reference

| Parameter     | Description                                    | Default                                        |
|--------------|------------------------------------------------|------------------------------------------------|
| namespace    | Namespace for deployment                        | casta-agent                                    |
| replicas     | Number of application replicas                  | 2                                             |
| image        | Container image                                 | ronakpatildocker/instacetargetmanager:latest  |
| awsRegion    | AWS region for cluster                         | us-west-2                                      |
| apiKey       | Base64 encoded CAST.AI API key                 | nil (required)                                 |
| clusterId    | Base64 encoded CAST.AI cluster ID              | nil (required)                                 |
| nodeSelector | Node selector configuration                     | {}                                            |
| tolerations  | Pod scheduling tolerations                      | []                                            |


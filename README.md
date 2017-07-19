# terraform-kubernetes

Terraform modules to bootstrap a Kubernetes cluster on AWS using [`kops`](https://github.com/kubernetes/kops).

## cluster

Creates a full `kops` cluster specification yaml, including the required instance groups

### Available variables:
 * [`name`]: String(required): base domain name of the cluster. This domain name will be used to lookup a hosted zone on Route53 and as the base for additional DNS records, e.g. for the API ELB.
 * [`k8s_data_bucket`]: String(required): The S3 bucket that `kops` will use to store it's configuration and state.
 * [`k8s_version`]: String(required): The Kubernetes version to deploy.
 * [`vpc_id`]: String(required): The VPC in which the Kubernetes cluster must be deployed
 * [`max_amount_workers`]: String(required): the amount of worker machines which can be deployed.
 * [`oidc_issuer_url`]: String(required): URL for the [OIDC issuer](https://kubernetes.io/docs/admin/authentication/#openid-connect-tokens).
 * [`worker_instance_type`]: String(optional): The EC2 instance type to use for the worker nodes. Defaults to `t2.medium`.
 * [`master_instance_type`]: String(optional): The EC2 instance type to use for the master nodes. Defaults to `t2.medium`.
 * [`master_net_number`]: String(required): First number of subnet to start of (ex I want a 10.1,10.2,10.3 subnet I specify 1) for the master subnets.
 * [`utility_net_number`]: String(required): First number of subnet to start of (ex I want a 10.1,10.2,10.3 subnet I specify 1) for utility subnets, e.g for load balancers. These are always public subnets.
 * [`elb_type`]: String(optional): Whether to use an Internal or Public ELB in front of the master nodes. Choices are `Public` or `Internal`. Defaults to `Public`.

### Output
 * None

### Example
```
module "kops-aws" {
  source               = "github.com/skyscrapers/terraform-kubernetes//cluster?ref=0.4.0"
  name                 = "kops.internal.skyscrape.rs"
  k8s_version          = "1.6.4"
  vpc_id               = "${module.customer_vpc.vpc_id}"
  k8s_data_bucket      = "kops-skyscrape-rs-state"
  master_instance_type = "m3.large"
  master_net_number    = "203"
  worker_instance_type = "c3.large"
  max_amount_workers   = "6"
  utility_net_number   = "13"
  oidc_issuer_url      = "https://signing.example.com/dex"
}
```

## base

Generates a `helm-values.yaml` file to be used to install all the needed helm packages for a base setup of a k8s cluster. It'll also create the needed IAM roles and policies for `external-dns` and `kube2iam`.

This terraform module will add an IAM policy to the k8s cluster nodes roles to allow them to assume other roles in the same AWS account on the path `/kube2iam/`. So if you create a role for a specific deployment in the cluster, make sure you create it on the `/kube2iam/` path.

**Note** that this module must be applied **after** there's a running Kubernetes cluster created with the [cluster module](#cluster), preferably on a different terraform stack.

### Available variables:

* [`name`]: String(required): base domain name of the cluster. This domain name will be used to lookup a hosted zone on Route53 and as the base for additional DNS records, e.g. for the API ELB.
* [`cluster_nodes_iam_role_name`]: String(required): The name of the IAM role of the cluster worker nodes
* [`nginx_controller_image_version`]: String(optional): The version of the nginx controller docker image
* [`lego_email`]: String(required): Email address to use for registration with Let's Encrypt
* [`lego_url`]: String(optional): Let's Encrypt API endpoint. Defaults to `https://acme-staging.api.letsencrypt.org/directory` (staging)
* [`dex_github_client_id`]: String(required): Client id of the GitHub application for the dex authentication. Must be base64 encoded
* [`dex_github_client_secret`]: String(required): Client secret of the GitHub application for the kubesignin/dex authentication. Must be base64 encoded
* [`dex_github_org`]: String(required): GitHub organization for the kubesignin/dex authentication
* [`kubesignin_client_secret`]: String(required): Secret string for the kubesignin/dex authentication

### Output

* [`external_dns_role_arn`]: String: ARN of the IAM role created for external-dns
* [`external_dns_role_name`]: String: Name of the IAM role created for external-dns

### Example

```
module "k8s-base" {
  source                      = "github.com/skyscrapers/terraform-kubernetes//base?ref=0.4.0"
  name                        = "kops.internal.skyscrape.rs"
  cluster_nodes_iam_role_name = "nodes.kops.internal.skyscrape.rs"
  lego_email                  = "hello@skyscrapers.eu"
  dex_github_client_id        = "Y2xpZW50X2lkY2xpZW50X2lk"
  dex_github_client_secret    = "Q2xpZW50U2VjcmV0Q2xpZW50U2VjcmV0Q2xpZW50U2VjcmV0Q2xpZW50U2VjcmV0Q2xpZW50U2VjcmV0"
  dex_github_org              = "skyscrapers"
  kubesignin_client_secret    = "something"
}
```

## Usage

### Bootstrap

First include the `cluster` module in an existing or new Terraform setup ([example](#example)). Run Terraform and you will get a file `kops-cluster.yaml` in your current working folder.

If your TF setup was not correct and you need to regenerate the cluster spec and Terraform hints that all resources are up to date, just mark the cluster spec file resource as dirty:

```console
$ terraform taint -module=kops-aws null_resource.kops_full_cluster-spec_file
```

Now rerun `terraform apply`.

Also install `kops`. See the section [Installing](https://github.com/kubernetes/kops#installing) of the `kops` readme file.

`kops` stores it's state in an S3 bucket. Point to the same S3 bucket as given in the Terraform setup:

```
$ export KOPS_STATE_STORE=s3://kops-skyscrape-rs-state
```

### Create the cluster

Now create the cluster with its initial state on the S3 bucket:

```
$ kops create -f kops-cluster.yaml
```

and register the SSH key to use for the nodes admin user:

```
$ kops create secret --name kops.internal.skyscrape.rs sshpublickey admin -i ~/.ssh/skyscrapers.pub
```

The name argument must match the cluster name you passed to the Terraform setup. Take a peek in the `kops-cluster.yaml` file if your forgot the name.

Kops calculates all the tasks it needs to execute. You can just see the output it *wants* to do by running the first command and you really execute it with the second command:

```
kops update cluster kops.internal.skyscrape.rs
kops update cluster kops.internal.skyscrape.rs --yes
```

Kops creates all the required AWS resources and eventually, your cluster should become available. If you ran `kops`, it will have saved the config to the API endpoint in the file `~/.kube/config`, ready to use for the Kubernetes CLI `kubectl`.

To test if your cluster came up correctly, run the command `kubectl get nodes` and you should see your master and worker nodes listed.

### Deploy base module

Then, in a different terraform stack, deploy the [base module](#base). This will also generate a `helm-values.yaml` file to deploy all the needed helm packages for a base setup.

### Deploy all helm packages

Now that we have the configuration for the different helm packages, we can start deploying them.

First we initialize helm:
```
helm init
```

Then we setup the proper RBAC config for helm:
```
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```

Install the Skyscrapers helm repo:
```
helm repo add skyscrapers https://skyscrapers.github.io/charts
```

Install the base helm packages:
```
helm install skyscrapers/kube2iam --values helm-values.yaml
helm install skyscrapers/kube-lego --values helm-values.yaml
helm install skyscrapers/nginx-ingress --values helm-values.yaml
helm install skyscrapers/external-dns --values helm-values.yaml
helm install skyscrapers/kubesignin --values helm-values.yaml
```

### Deploy dashboard

We deploy the dashboard with kubectl as the install through helm gives it a random name and we can't access the dashboard through the proxy
```
kubectl create -f https://git.io/kube-dashboard
```

After this you can access the dashboard through the proxy
```
kubectl proxy
```

Now you can visit `http://127.0.0.1:8001/ui`

### Evolve your cluster

If you want to tweak the setup of your cluster, it is quite easy. Note however that while the process is easy, some of the changes could potentially break your cluster.

First, update the parameters you want to change in your Terraform setup. Mark the `null_resource` as dirty (see above) and rerun `terraform apply`

Since we already have the cluster created, we must replace the old config with the new specification:

```
$ kops replace -f kops-cluster.yaml
```

If there are changes to AWS resources to be made, we can see and execute them by this pair of commands:

```
kops update cluster kops.internal.skyscrape.rs
kops update cluster kops.internal.skyscrape.rs --yes
```

If there are changes to an ASG, old existing nodes are not replaced automatically. To force this, you can view and execute which items it will upgrade in a rolling manner:

```
kops rolling-update cluster kops.internal.skyscrape.rs
kops rolling-update cluster kops.internal.skyscrape.rs --yes
```

Note that the `rolling-update` command also connects to the Kuberenetes API to monitor the liveliness of the complete system while the rolling upgrade is taking place.

If you made changes to one of the settings of your core Kuberenetes components (eg API), you will need to force the rolling update, you can use the following command.
```
kops rolling-update cluster kops.internal.skyscrape.rs --instance-group <instance-group-name> --force --yes
```

#### Helm packages

The same applies to the deployed Helm packages. If an update needs to be made, just taint the `null_resource.helm_values_file` resource in the base module and rerun `terraform apply`. Then with the new `helm-values.yaml` file you'll be able to upgrade all the helm packages by doing:

```
helm upgrade <release_name> skyscrapers/<helm_chart_name> --values helm-values.yaml
```

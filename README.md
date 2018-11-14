# terraform-kubernetes

Terraform modules to bootstrap a Kubernetes cluster on AWS using [`kops`](https://github.com/kubernetes/kops).

## cluster

Creates a full `kops` cluster specification yaml, including the required instance groups

### Available variables

* [`name`]: String(required): base domain name of the cluster. This domain name will be used to lookup a hosted zone on Route53 and as the base for additional DNS records, e.g. for the API ELB.
* [`environment`]: String(required): Environment of the cluster
* [`customer`]: String(required): Customer name
* [`k8s_data_bucket`]: String(required): The S3 bucket that `kops` will use to store it's configuration and state.
* [`k8s_version`]: String(required): The Kubernetes version to deploy.
* [`vpc_id`]: String(required): The VPC in which the Kubernetes cluster must be deployed
* [`max_amount_workers`]: String(required): the amount of worker machines which can be deployed.
* [`oidc_issuer_url`]: String(required): URL for the [OIDC issuer](https://kubernetes.io/docs/admin/authentication/#openid-connect-tokens).
* [`teleport_token`]: String(required): Teleport auth token that this node will present to the auth server
* [`teleport_server`]: String (Required): Teleport auth server that this node will connect to, including the port number
* [`environment`]: String (optional): Environment where this node belongs to, will be the third part of the node name. Defaults to ''
* [`worker_instance_type`]: String(optional): The EC2 instance type to use for the worker nodes. Defaults to `t2.medium`.
* [`master_instance_type`]: String(optional): The EC2 instance type to use for the master nodes. Defaults to `t2.medium`.
* [`master_net_number`]: String(required): First number of subnet to start of (ex I want a 10.1,10.2,10.3 subnet I specify 1) for the master subnets.
* [`utility_net_number`]: String(required): First number of subnet to start of (ex I want a 10.1,10.2,10.3 subnet I specify 1) for utility subnets, e.g for load balancers. These are always public subnets.
* [`elb_type`]: String(optional): Whether to use an Internal or Public ELB in front of the master nodes. Choices are `Public` or `Internal`. Defaults to `Public`.
* [`etcd_version`]: String(optional): Which Etcd version do you want to run. Defaults to default version defined in Kops.
* [`helm_node`]: Boolean(optional): Due to a [bug](https://github.com/kubernetes/helm/issues/3121) in HELM/Kubelet, we want to run the tiller on a seperate node. When you want it set this to "true". The `"` around true are really important. Defaults to `"false"`.
* [`extra_worker_securitygroups`]: List(optional): List of extra securitygroups that you want to attach to the worker nodes. Defaults to `[]`
* [`extra_master_securitygroups`]: List(optional): List of extra securitygroups that you want to attach to the master nodes. Defaults to `[]`
* [`spot_price`]: String(optional): Spot price you want to pay for your worker instances. By default this is empty and we will use on-demand instances. Default to `""`
* [`calico_logseverity`]: String(optional): Sets the logSeverityScreen setting for the Calico CNI. Defaults to `"warning"`
* [`nat_gateway_ids`]: List(required): List of NAT gateway ids to associate to the route tables created by kops. There must be one NAT gateway for each availability zone in the region.
* [`bastion_cidr`]: String(required): CIDR of the bastion host. This will be used to allow SSH access to kubernetes nodes

### Output

* None

### Example

```hcl
module "kops-aws" {
  source               = "github.com/skyscrapers/terraform-kubernetes//cluster?ref=0.4.0"
  name                 = "kops.internal.skyscrape.rs"
  environment          = "production"
  customer             = "customer"
  k8s_version          = "1.6.4"
  vpc_id               = "${module.customer_vpc.vpc_id}"
  k8s_data_bucket      = "kops-skyscrape-rs-state"
  master_instance_type = "m3.large"
  master_net_number    = "203"
  worker_instance_type = "c3.large"
  max_amount_workers   = "6"
  utility_net_number   = "13"
  oidc_issuer_url      = "https://signing.example.com/dex"
  teleport_token       = "78dwgfhjwdk"
  teleport_server      = "teleport.example.com:3025"
}
```

## base

**IMPORTANT:** If you're looking for the base terraform module, it has been moved to the [Kubernetes standard stack](https://github.com/skyscrapers/kubernetes-stack). The rest of this module will also be migrated soon.

## Usage

**Note**: [Refer to our documentation repo for the latest info on how to setup a cluster](https://github.com/skyscrapers/internal-documentation/tree/master/services/kubernetes/setup.md)

### Bootstrap

First include the `cluster` module in an existing or new Terraform stack ([example](#example)). Run Terraform and you will get a file `kops-cluster.yaml` in your current working folder.

If your TF setup was not correct and you need to regenerate the cluster spec and Terraform hints that all resources are up to date, just mark the cluster spec file resource as dirty:

```sh
terraform taint -module=kops-aws null_resource.kops_full_cluster-spec_file
```

Now rerun `terraform apply`.

Also install `kops`. See the section [Installing](https://github.com/kubernetes/kops#installing) of the `kops` readme file.

`kops` stores it's state in an S3 bucket. Point to the same S3 bucket as given in the Terraform setup:

```sh
export KOPS_STATE_STORE=s3://<s3-bucket-name>
```

*Replace `<s3-bucket-name>` with the name of the S3 bucket created with the `cluster` module*

To authenticate kops to AWS, you'll need to either set the credentials as environment variables, or use a profile name in your AWS config file with:

```sh
export AWS_PROFILE=MyProfile
```

### Create the cluster

*In the following examples, replace `<cluster-name>` with the correct cluster name that you're deploying. This is the name you set as `name` in the `cluster` module.*

Now create the cluster with its initial state on the S3 bucket:

```sh
kops create -f kops-cluster.yaml
```

Generate a new SSH key and register it in kops to use for the nodes admin user (remember to add the key to 1password so everyone can use it):

```sh
ssh-keygen -t rsa -b 4096 -C "<cluster-name>" -N "" -f <cluster-name>_key
kops create secret --name <cluster-name> sshpublickey admin -i ./<cluster-name>_key.pub
```

The name argument must match the cluster name you passed to the Terraform setup. Take a peek in the `kops-cluster.yaml` file if your forgot the name.

Kops calculates all the tasks it needs to execute. You can just see the output it *wants* to do by running the first command and you really execute it with the second command:

```sh
kops update cluster --name <cluster-name>
kops update cluster --name <cluster-name> --yes
```

Kops creates all the required AWS resources and eventually, your cluster should become available. If you ran `kops`, it will have saved the config to the API endpoint in the file `~/.kube/config`, ready to use for the Kubernetes CLI `kubectl`.

To test if your cluster came up correctly, run the command `kubectl get nodes` and you should see your master and worker nodes listed.

### Evolve your cluster

If you want to tweak the setup of your cluster, it is quite easy. Note however that while the process is easy, some of the changes could potentially break your cluster.

First, update the parameters you want to change in your Terraform setup.

Since we already have the cluster created, we must replace the old config with the new specification:

```sh
kops replace -f kops-cluster.yaml
```

If there are changes to AWS resources to be made, we can see and execute them by this pair of commands:

```sh
kops update cluster --name <cluster-name>
kops update cluster --name <cluster-name> --yes
```

If there are changes to an ASG, old existing nodes are not replaced automatically. To force this, you can view and execute which items it will upgrade in a rolling manner:

```sh
kops rolling-update cluster --name <cluster-name>
kops rolling-update cluster --name <cluster-name> --yes
```

Note that the `rolling-update` command also connects to the Kuberenetes API to monitor the liveliness of the complete system while the rolling upgrade is taking place.

If you made changes to one of the settings of your core Kuberenetes components (eg API), you will need to force the rolling update, you can use the following command.

```sh
kops rolling-update cluster --name <cluster-name> --instance-group <instance-group-name> --force --yes
```

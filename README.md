# terraform-kubernetes

Terraform module to bootstrap a Kubernetes cluster on AWS using 
[`kops`](https://github.com/kubernetes/kops).

## cluster
Creates a full `kops` cluster specification yaml, including the required
instance groups 

### Available variables:
 * [`name`]: String(required): base domain name of the cluster. This domain name will be used to lookup a hosted zone on Route53 and as the base for additional DNS records, e.g. for the API ELB.
 * [`k8s_data_bucket`]: String(required): The S3 bucket that `kops` will use to store it's configuration and state.
 * [`k8s_version`]: String(required): The Kubernetes version to deploy.
 * [`vpc_id`]: String(required): The VPC in which the Kubernetes cluster must be deployed
 * [`max_amount_workers`]: String(required): the amount of worker machines which can be deployed.
 * [`worker_instance_type`]: String(optional): The EC2 instance type to use for the worker nodes. Defaults to `t2.medium`.
 * [`master_instance_type`]: String(optional): The EC2 instance type to use for the master nodes. Defaults to `t2.medium`.
 * [`master_net_number`]: String(required): First number of subnet to start of (ex I want a 10.1,10.2,10.3 subnet I specify 1) for the master subnets.
 * [`utility_net_number`]: String(required): First number of subnet to start of (ex I want a 10.1,10.2,10.3 subnet I specify 1) for utility subnets, e.g for load balancers. These are always public subnets.

### Output
 * None

### Example
```
module "kops-aws" {
  source            = "github.com/skyscrapers/terraform-kubernetes//cluster?ref=937b2c9103dad47a4f292313cf04549217a43bc4"
  name                 = "kops.internal.skyscrape.rs"
  k8s_version          = "1.5.2"
  vpc_id               = "${module.customer_vpc.vpc_id}"
  k8s_data_bucket      = "kops-skyscrape-rs-state"
  master_instance_type = "m3.large"
  master_net_number    = "203"
  worker_instance_type = "c3.large"
  max_amount_workers   = "6"
  utility_net_number   = "13"
}
```

## Usage

### Bootstrap
First include the generation of the cluster specification to an existing Terraform setup as in the example above. Run Terraform and you will get a file `kops-cluster.yaml` in your current working folder.

If your TF setup was not correct and you need to regenerate the cluster spec and Terraform hints that all resources are up to date, just mark the cluster spec file resource as dirty:

```
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

### Deploy initial tooling

The cluster is configured for Container Network Integration (CNI). After the cluster comes up, we first must install a CNI plugin for all the network.

< @luca, can you add the correct instructions for the network setup here? >

### Evolve your cluster

If you want to tweak the setup of your cluster, it is quite easy. Note however that while the process is easy, some of the changes you can could break your cluster.

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
kops rolling-upgrade cluster kops.internal.skyscrape.rs
kops rolling-upgrade cluster kops.internal.skyscrape.rs --yes
```

Note that the `rolling-upgrade` command also connects to the Kuberenetes API to monitor the liveliness of the complete system while the rolling upgrade is taking place.


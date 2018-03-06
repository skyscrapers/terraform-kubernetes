# terraform-kubernetes

Terraform modules to bootstrap a Kubernetes cluster on AWS using [`kops`](https://github.com/kubernetes/kops).

## cluster

Creates a full `kops` cluster specification yaml, including the required instance groups

### Available variables:
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


### Output
 * None

### Example
```
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

Generates a `helm-values.yaml` file to be used to install all the needed helm packages for a base setup of a k8s cluster. It'll also create the needed IAM roles and policies for `external-dns` and `kube2iam`.

This terraform module will add an IAM policy to the k8s cluster nodes roles to allow them to assume other roles in the same AWS account on the path `/kube2iam/`. So if you create a role for a specific deployment in the cluster, make sure you create it on the `/kube2iam/` path.

**Note** that this module must be applied **after** there's a running Kubernetes cluster created with the [cluster module](#cluster), preferably on a different terraform stack.

### Available variables:

* [`name`]: String(required): base domain name of the cluster. This domain name will be used to lookup a hosted zone on Route53 and as the base for additional DNS records, e.g. for the API ELB.
* [`cluster_nodes_iam_role_name`]: String(required): The name of the IAM role of the cluster worker nodes
* [`nginx_controller_image_version`]: String(optional): The version of the nginx controller docker image
* [`lego_email`]: String(required): Email address to use for registration with Let's Encrypt
* [`lego_url`]: String(optional): Let's Encrypt API endpoint. Defaults to `https://acme-staging.api.letsencrypt.org/directory` (staging)
* [`dex_gh_connectors`]: Map(required): A map of the required github connectors used by dex. See example below.
* [`dex_expiry_signingkeys`]: String(optional, default `6h`): The duration of time after which the Dex SigningKeys will be rotated.
* [`dex_expiry_idtokens`]: : String(optional, default `1h`): The duration of time for which the Dex IdTokens will be valid. This value shouldn't be longer than `dex_expiry_signingkeys`.
* [`kubesignin_client_secret`]: String(required): Secret string for the kubesignin/dex authentication. Beware that some characters might give problems in some cases, so we recommend only using alphanumeric characters.
* [`opsgenie_api_key`]: String(required): Opsgenie API key from your [prometheus integration](https://docs.opsgenie.com/docs/integrations/prometheus-integration).
* [`slack_webhook_url`]: String(required): Slack webhook url from you [webhook configuration](https://api.slack.com/incoming-webhooks)
* [`opsgenie_heartbeat_name`]: String(optional): Opsgenie Heartbeat name. By default we compose this as `<Customer> <Environment> Cluster Deadmanswitch`
* [`bastion_cidr`]: String(required): Bastion CIDR of your kubernetes cluster.
* [`alertmanager_volume_size`]: String(optional, default: `20Gi`): Persistent volume size for the AlertManager.
* [`prometheus_volume_size`]: String(optional, default: `100Gi`): Persistent volume size for Prometheus.
* [`prometheus_retention`]: String(optional, default: `336h`): Data retention period for Prometheus (default: 2 weeks).
* [`grafana_admin_user`]: String(optional, default: `admin`): Grafana admin user name.
* [`grafana_admin_password`]: String(optional, default: `admin`): Grafana admin user password.
* [`grafana_volume_size`]: String(optional, default: `10Gi`): Persistent volume size Grafana.
* [`headers`]: Map(optional): The map name to use for the proxy headers. (default: `"X-Request-Start" = "t=${msec}"`)
* [`fluentd_loggroupname`]: String(optional): Cloudwatch loggroupname for fluentd-cloudwatch. (default: `kubernetes`)
* [`fluentd_aws_region`]: String(optional): AWS region where we want to store our logs we shipped from Fluentd to Cloudwatch. (default: AWS region name of your Terraform AWS provider)
* [`fluentd_custom_config`]: String(optional): Extra Fluentd config you want to add to the standard Fluentd config. (default: "")
* [`fluentd_retention`]: Int(optional): How long do we want to keep the Fluentd logs in Cloudwatch logs. (default: `30`)
* [`elasticsearch_url`]: String(optional): The URL for elasticsearch. If not filled in, you will not be able to deploy Kibana. (default: "")
* [`kibana_image_tag`]: String(optional): Image tag of the kibana image. (default: "6.0.0")
* [`extra_grafana_datasoures`]: Map(optional): Extra Grafana datasource urls we want to add. Form is a map with name as key and url as value. (default: {})
* [`extra_grafana_dashboards`]: String(optional): Extra Grafana dashboards. From is the map structure of HELM.
* [`extra_alertmanager_routes`]: String(optional): Extra alertmanager routes. Yaml format. (default: "")
* [`extra_alertmanager_receivers`]: String(optional): Extra alertmanager receivers. Yaml format. (default: "")
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
  opsgenie_api_key            = "somesecretopsgeniekey"
  bastion_cidr                = "1.2.3.4/32"
  fluentd_custom_config       = <<EOF
<filter kubernetes.var.log.containers.busybox_**.log>
  type parser
  format /^.*\"(?<json>{.*})\"$/
  key_name log
  reserve_data yes
</filter>

<filter kubernetes.var.log.containers.busybox_**.log>
  @type parser
  format json
  key_name json
  reserve_data true
  hash_value_field json
</filter>
EOF
}
```

example of the `dex_gh_connectors` map:
```yaml
dex_gh_connectors = {
  github1 = {
    clientId = "base64clientID"
    clientSecret = "base64clientSecret"
    orgName = "org1"
    teamName = "team1"
  }
  github2 = {
    clientId = "base64clientID"
    clientSecret = "base64clientSecret"
    orgName = "org2"
    teamName = "team2"
  }
}
```

example of the `extra_alertmanager_routes`:
```yaml
extra_alertmanager_routes = <<EOF
- match:
    severity: warning
  receiver: slack-runtime
  routes:
  - match:
      group: persistence
    receiver: slack-persistence
EOF
```

example of the `extra_alertmanager_receivers`:
```yaml
extra_alertmanager_receivers = <<EOF
- name: opsgenieproxy
  webhook_configs:
    - send_resolved: false
      url: http://k8s-monitor-opsgenie-heartbeat-proxy/proxy
EOF
```

## Usage

### Bootstrap

First include the `cluster` module in an existing or new Terraform stack ([example](#example)). Run Terraform and you will get a file `kops-cluster.yaml` in your current working folder.

If your TF setup was not correct and you need to regenerate the cluster spec and Terraform hints that all resources are up to date, just mark the cluster spec file resource as dirty:

```console
$ terraform taint -module=kops-aws null_resource.kops_full_cluster-spec_file
```

Now rerun `terraform apply`.

Also install `kops`. See the section [Installing](https://github.com/kubernetes/kops#installing) of the `kops` readme file.

`kops` stores it's state in an S3 bucket. Point to the same S3 bucket as given in the Terraform setup:

```
$ export KOPS_STATE_STORE=s3://<s3-bucket-name>
```

*Replace `<s3-bucket-name>` with the name of the S3 bucket created with the `cluster` module*

To authenticate kops to AWS, you'll need to either set the credentials as environment variables, or use a profile name in your AWS config file with:

```
export AWS_PROFILE=MyProfile
```

### Create the cluster

*In the following examples, replace <cluster-name> with the correct cluster name that you're deploying. This is the name you set as `name` in the `cluster` module.*

Now create the cluster with its initial state on the S3 bucket:

```
$ kops create -f kops-cluster.yaml
```

Generate a new SSH key and register it in kops to use for the nodes admin user (remember to add the key to 1password so everyone can use it):

```
$ ssh-keygen -t rsa -b 4096 -C "<cluster-name>" -N "" -f <cluster-name>_key
$ kops create secret --name <cluster-name> sshpublickey admin -i ./<cluster-name>_key.pub
```

The name argument must match the cluster name you passed to the Terraform setup. Take a peek in the `kops-cluster.yaml` file if your forgot the name.

Kops calculates all the tasks it needs to execute. You can just see the output it *wants* to do by running the first command and you really execute it with the second command:

```
kops update cluster <cluster-name>
kops update cluster <cluster-name> --yes
```

Kops creates all the required AWS resources and eventually, your cluster should become available. If you ran `kops`, it will have saved the config to the API endpoint in the file `~/.kube/config`, ready to use for the Kubernetes CLI `kubectl`.

To test if your cluster came up correctly, run the command `kubectl get nodes` and you should see your master and worker nodes listed.

### Deploy base module

Then, in a different terraform stack, deploy the [base module](#base).

Before doing this, you'll need to create a [Github OAuth application](https://github.com/organizations/skyscrapers/settings/applications), which will be used to authenticate to the cluster. The main thing to consider when creating the Github application is the callback, which has to be as follows:

`https://kubesignin.<cluster-name>/dex/callback`

Then set the application client id and client secret to the corresponding variables in the `base` module (beware that they need to be base64 encoded).

Also before applying terraform, you'll also need to generate a new random string for the `kubesignin_client_secret` variable (beware that some characters might give problems in some cases, so we recommend only using alphanumeric characters).

Now you can already apply terraform. This will generate a `helm-values.yaml` file to deploy all the needed helm packages for a base setup.

If your TF setup was not correct and you need to regenerate the helm values file and Terraform hints that all resources are up to date, just taint the null resource that generates the file:

```console
$ terraform taint -module=k8s-base null_resource.helm_values_file
```

And then re-run `terraform apply`.

### Deploy all helm packages

Now that we have the configuration for the different helm packages, we can start deploying them.

Setting up Helm and installing the required bootstrap helm packages is described in the
[`charts/README`](https://github.com/skyscrapers/charts/blob/master/README.md#bootstrap-base-charts) file.

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

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "external_dns_role" {
  name = "${var.name}_external_dns_role"
  path = "/kube2iam/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_nodes_iam_role_name}",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_masters_iam_role_name}"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "external_dns_role_policy" {
  name = "${var.name}_external_dns_policy"
  role = "${aws_iam_role.external_dns_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "route53:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "fluentd_role" {
  name = "${var.name}_fluentd_role"
  path = "/kube2iam/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
      "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_nodes_iam_role_name}",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_masters_iam_role_name}"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "fluentd_role_policy" {
  name = "${var.name}_fluentd_policy"
  role = "${aws_iam_role.fluentd_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:*",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:logs:${local.fluentd_aws_region}:*:*",
        "arn:aws:s3:::*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "kube2iam_assume_role_policy" {
  name = "${var.name}_kube2iam_assume_role_policy"
  role = "${var.cluster_nodes_iam_role_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kube2iam/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "kube2iam_assume_role_policy_masters" {
  name = "${var.name}_kube2iam_assume_role_policy_masters"
  role = "${var.cluster_masters_iam_role_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kube2iam/*"
    }
  ]
}
EOF
}


## Cluster-Autoscaler

data "aws_iam_policy_document" "autoscaler_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "AWS"
      identifiers= ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_masters_iam_role_name}"]
    }
  }
}

data "aws_iam_policy_document" "autoscaler" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]

    resources = [
      "arn:aws:autoscaling:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/*.${var.name}",
    ]
  }
}

resource "aws_iam_role" "autoscaler" {
  name               = "${var.name}_autoscaler_role"
  path               = "/kube2iam/"
  assume_role_policy = "${data.aws_iam_policy_document.autoscaler_assume.json}"
}

resource "aws_iam_policy" "autoscaler" {
  name   = "${var.name}_autoscaler_policy"
  policy = "${data.aws_iam_policy_document.autoscaler.json}"
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  role       = "${aws_iam_role.autoscaler.id}"
  policy_arn = "${aws_iam_policy.autoscaler.arn}"
}

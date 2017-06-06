//resource "aws_iam_role_policy" "masters" {
//  name = "k8s-master-${var.project}-${var.environment}-policy"
//  role = "${module.masters.role_id}"
//
//  policy = <<POLICY
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Effect": "Allow",
//      "Action": [
//        "ecr:GetAuthorizationToken",
//        "ecr:BatchCheckLayerAvailability",
//        "ecr:GetDownloadUrlForLayer",
//        "ecr:GetRepositoryPolicy",
//        "ecr:DescribeRepositories",
//        "ecr:ListImages",
//        "ecr:BatchGetImage"
//      ],
//      "Resource": [
//        "*"
//      ]
//    },
//    {
//      "Effect": "Allow",
//      "Action": [
//        "ec2:*"
//      ],
//      "Resource": [
//        "*"
//      ]
//    },
//    {
//      "Effect": "Allow",
//      "Action": [
//        "s3:*"
//      ],
//      "Resource": [
//        "*"
//      ]
//    },
//    {
//      "Effect": "Allow",
//      "Action": [
//        "route53:*"
//      ],
//      "Resource": [
//        "*"
//      ]
//    },
//    {
//      "Effect": "Allow",
//      "Action": [
//        "elasticloadbalancing:*"
//      ],
//      "Resource": [
//        "*"
//      ]
//    }
//  ]
//}
//POLICY
//}

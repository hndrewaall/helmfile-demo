# External DNS Controller
resource "aws_iam_role" "external_dns" {
  # https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
  name = "external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:external-dns"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  inline_policy {
    name = "ExternalDNSControllerIAMPolicy"

    # https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "route53:ChangeResourceRecordSets"
          Resource = "arn:aws:route53:::hostedzone/*"
        },
        {
          Effect = "Allow"
          Action = [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets",
            "route53:ListTagsForResource"
          ]
          Resource = "*"
        }
      ]
    })
  }
}


# Load Balancer Controller
resource "aws_iam_role" "load_balancer_controller" {
  name        = "load-balancer-controller"
  description = "https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/deploy/installation/"

  assume_role_policy = jsonencode({
    # https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:load-balancer-controller"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  inline_policy {
    name   = "AWSLoadBalancerControllerIAMPolicy"
    policy = file("${path.module}/lbc-iam-policy.json")
  }
}

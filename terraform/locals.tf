locals {
  name            = "helmfile-demo"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr        = "10.0.0.0/16"
  cluster_version = "1.29"
}

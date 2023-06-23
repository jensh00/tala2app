module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "virgo-cluster"
  cluster_version = "1.27"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = "vpc-02c88535c1e743f7f"
  subnet_ids               = ["subnet-034b190248728a154", "subnet-0d03082e2fc414537"]
  control_plane_subnet_ids = ["subnet-034b190248728a154", "subnet-0d03082e2fc414537"]

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 4
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }


  # aws-auth configmap
  manage_aws_auth_configmap = true

   aws_auth_users = [
    {
      userarn  = "arn:aws:iam::belenshi:user/user1"
      username = "belenshi"
      groups   = ["system:masters"]
    }
  ]
  aws_auth_accounts = [
    "8915-6415-5871",
  ]

  tags = {
    Environment = "bel"
    Terraform   = "true"
  }
}

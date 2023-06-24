provider "aws" {
  region  = "us-east-1" # USA
}

provider "helm" {
   # For Helm 3
}

provider "kubernetes" {
  host = aws_eks_cluster.eks-test-cluster.endpoint
}

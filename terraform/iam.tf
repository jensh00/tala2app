resource "aws_iam_role" "app_role" {
  name               = "app_role"
  assume_role_policy = data.aws_iam_policy_document.app_assume_role_policy.json
}

resource "aws_eks_service_account" "app_sa" {
  name      = "app-sa"
  namespace = "default"
  cluster   = aws_eks_cluster.eks-tala2-cluster.name
  role_arn  = aws_iam_role.app_role.arn
}
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.9.1"

  set {
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.eks-tala2-cluster.name
  }
}
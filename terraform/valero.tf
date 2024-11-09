resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"

  set {
    name  = "configuration.provider"
    value = "aws"
  }
  set {
    name  = "configuration.backupStorageLocation.name"
    value = "default"
  }
  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = "your-s3-bucket"
  }
}
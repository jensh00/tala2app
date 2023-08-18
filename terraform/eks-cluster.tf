variable "cluster-name" {
  default = "tala2-app"
  type    = string
}

resource "aws_iam_role" "eks-tala2-cluster-iam" {
  name = "virgo-tala2-cluster-iam"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-tala2-cluster-iam-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-tala2-cluster-iam.name
}

resource "aws_iam_role_policy_attachment" "eks-tala2-cluster-iam-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-tala2-cluster-iam.name
}

resource "aws_security_group" "eks-tala2-cluster-sg" {
  name        = "virgo-eks-tala2-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.eks-tala2-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tala2-eks"
  }
}

resource "aws_eks_cluster" "eks-tala2-cluster" {
  name     = var.cluster-name
  role_arn = aws_iam_role.eks-tala2-cluster-iam.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks-tala2-cluster-sg.id]
    subnet_ids         = aws_subnet.eks-tala2-subnet.*.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-tala2-cluster-iam-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-tala2-cluster-iam-AmazonEKSServicePolicy,
  ]
}

locals {
  kubeconfig = <<-KUBECONFIG

    ---
    apiVersion: v1
    clusters:
    - cluster:
        server: ${aws_eks_cluster.eks-tala2-cluster.endpoint}
        certificate-authority-data: ${aws_eks_cluster.eks-tala2-cluster.certificate_authority.0.data}
      name: eks-test
    contexts:
    - context:
        cluster: eks-test
        user: aws
      name: eks-test
    current-context: eks-test
    kind: Config
    preferences: {}
    users:
    - name: aws
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1alpha1
          command: aws-iam-authenticator
          args:
            - "token"
            - "-i"
            - "${var.cluster-name}"
  KUBECONFIG
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}
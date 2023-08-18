variable "node-type" {
  default = "t2.micro" # Free tier eligible, but allows only 4 pods per node (and 3 pods will be already there!)
  type    = string
}

resource "aws_iam_role" "eks-tala2-nodegroup-iam" {
  name = "eks-tala2-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-tala2-nodegroup-iam-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-tala2-nodegroup-iam.name
}

resource "aws_iam_role_policy_attachment" "eks-tala2-nodegroup-iam-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-tala2-nodegroup-iam.name
}

resource "aws_iam_role_policy_attachment" "eks-tala2-nodegroup-iam-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-tala2-nodegroup-iam.name
}

resource "aws_security_group" "eks-tala2-nodegroup" {
  name        = "terraform-eks-tala2-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.eks-tala2-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                      = "tala2-eks-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
  }
}

resource "aws_security_group_rule" "eks-tala2-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks-tala2-nodegroup.id
  source_security_group_id = aws_security_group.eks-tala2-cluster-sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-tala2-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control      plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-tala2-nodegroup.id
  source_security_group_id = aws_security_group.eks-tala2-cluster-sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-tala2-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-tala2-nodegroup.id
  source_security_group_id = aws_security_group.eks-tala2-cluster-sg.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_eks_node_group" "eks-tala2-nodegroup" {
  cluster_name    = aws_eks_cluster.eks-tala2-cluster.name
  node_group_name = "eks-virgo"
  node_role_arn   = aws_iam_role.eks-tala2-nodegroup-iam.arn
  subnet_ids      = aws_subnet.eks-tala2-subnet[*].id
  instance_types  = [var.node-type]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-tala2-cluster-iam-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-tala2-nodegroup-iam-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-tala2-nodegroup-iam-AmazonEC2ContainerRegistryReadOnly,
  ]
}

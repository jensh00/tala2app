data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "eks-tala2-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name"                                      = "tala2-eks-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_subnet" "eks-tala2-subnet" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.eks-tala2-vpc.cidr_block, 8, count.index)
  vpc_id            = aws_vpc.eks-tala2-vpc.id
  map_public_ip_on_launch = true

  tags = {
    "Name"                                      = "tala2-eks-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_internet_gateway" "eks-tala2-gw" {
  vpc_id = aws_vpc.eks-tala2-vpc.id

  tags = {
    "Name" = var.cluster-name
  }
}

resource "aws_route_table" "eks-tala2-rt" {
  vpc_id = aws_vpc.eks-tala2-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-tala2-gw.id
  }
}

resource "aws_route_table_association" "eks-tala2-rta" {
  count = 2

  subnet_id      = aws_subnet.eks-tala2-subnet[count.index].id
  route_table_id = aws_route_table.eks-tala2-rt.id
}

### IAM
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "ALBIngressControllerIAMPolicy"
  path        = "/"
  description = "Policy for ALB Ingress Controller"
  policy      = file("alb_policy.json") # Create and save the policy in a JSON file
}

resource "aws_iam_role" "alb_controller_role" {
  name               = "alb_controller_role"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}
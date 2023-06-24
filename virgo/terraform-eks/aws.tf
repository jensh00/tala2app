data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "eks-test-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name"                                      = "virgo-eks-test-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_subnet" "eks-test-subnet" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.eks-test-vpc.cidr_block, 8, count.index)
  vpc_id            = aws_vpc.eks-test-vpc.id
  map_public_ip_on_launch = true

  tags = {
    "Name"                                      = "virgo-eks-test-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_internet_gateway" "eks-test-gw" {
  vpc_id = aws_vpc.eks-test-vpc.id

  tags = {
    "Name" = var.cluster-name
  }
}

resource "aws_route_table" "eks-test-rt" {
  vpc_id = aws_vpc.eks-test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-test-gw.id
  }
}

resource "aws_route_table_association" "eks-test-rta" {
  count = 2

  subnet_id      = aws_subnet.eks-test-subnet[count.index].id
  route_table_id = aws_route_table.eks-test-rt.id
}

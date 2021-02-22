resource "aws_iam_role" "eks_cluster" {
  name = "test-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_security_group" "eks_cluster" {
  name        = "test-cluster"
  description = "test-cluster"
}

resource "aws_security_group_rule" "intra_cluster" {
  security_group_id = aws_security_group.eks_cluster.id

  type = "ingress"
  from_port = 1
  to_port = 65535
  protocol = -1
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "outbound" {
  security_group_id = aws_security_group.eks_cluster.id

  type = "egress"
  from_port = 1
  to_port = 65535
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_eks_cluster" "cluster" {
  name      = "test-cluster"
  role_arn  = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = var.subnets

    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.eks_vpc_controller
  ]
}

output "endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}

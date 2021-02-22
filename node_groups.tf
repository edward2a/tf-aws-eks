resource "aws_iam_role" "node_groups" {
  name = "eks_test_node_group"

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

resource "aws_iam_role_policy_attachment" "nodegroup-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_groups.name
}

resource "aws_iam_role_policy_attachment" "nodegroup-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_groups.name
}

resource "aws_iam_role_policy_attachment" "nodegroup-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_groups.name
}

resource "aws_eks_node_group" "ondemand" {
  cluster_name = aws_eks_cluster.cluster.name
  node_group_name = "ondemand_group"
  node_role_arn = aws_iam_role.node_groups.arn
  subnet_ids = var.subnets

  capacity_type = "ON_DEMAND"
  disk_size = 20
  instance_types = ["t3a.small"]

  scaling_config {
    desired_size = 2
    min_size = 2
    max_size = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodegroup-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodegroup-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodegroup-AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

resource "aws_eks_node_group" "spot" {
  cluster_name = aws_eks_cluster.cluster.name
  node_group_name = "spot_group"
  node_role_arn = aws_iam_role.node_groups.arn
  subnet_ids = var.subnets

  capacity_type = "SPOT"
  disk_size = 20
  instance_types = ["t3a.small"]

  scaling_config {
    desired_size = 2
    min_size = 2
    max_size = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodegroup-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodegroup-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodegroup-AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}


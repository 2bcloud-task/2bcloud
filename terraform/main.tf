# Provider Block
provider "aws" {
  profile = "default"
  region = var.my_region
}

# Storing Terraform State in S3 with DynamoDB
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-eks-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Terraform Backend configuration
terraform {
  backend "s3" {
    bucket         = "my-eks-terraform-state"
    key            = "terraform.tfstate"
    region         = var.my_region
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# VPC and Subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = [var.avz_a, var.avz_b]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
}

# EKS Cluster with a Single Node Pool
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      desired_capacity = 1
      min_size         = 1
      max_size         = 1

      instance_types = ["t3.medium"]
    }
  }
}

# Kubernetes proxy service Nginx
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Load Balancer service
resource "kubernetes_service" "nginx_lb" {
  metadata {
    name = "nginx-lb"
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}


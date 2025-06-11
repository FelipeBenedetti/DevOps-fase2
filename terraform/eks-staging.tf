module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"  

  cluster_name    = "devops-staging-cluster"
  cluster_version = "1.28"
  
  vpc_id     = "vpc-067c38190e61fd729"
  subnet_ids = [
    "subnet-0d0cb7d7f0316c51d",  # us-east-2c
    "subnet-0e4007db60a38d781",  # us-east-2b
    "subnet-0690f267a739551bc"   # us-east-2a
  ]

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] 

  eks_managed_node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 4
      min_capacity     = 1
      instance_types   = ["t3.medium"]
    }
  }
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "kubectl config values"
  value = {
    cluster_name                 = module.eks.cluster_name
    endpoint                     = module.eks.cluster_endpoint
    certificate_authority_data  = module.eks.cluster_certificate_authority_data
  }
}


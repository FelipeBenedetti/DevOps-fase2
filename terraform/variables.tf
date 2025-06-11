variable "aws_region" {
  description = "Região da AWS onde a infraestrutura será provisionada"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Nome do projeto, usado para nomear recursos"
  type        = string
  default     = "devops-projeto"
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Lista de CIDRs para subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Lista de CIDRs para subnets privadas"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "instance_type" {
  description = "Tipo de instância EC2 para o cluster ECS"
  type        = string
  default     = "t3.medium"
}

variable "min_instances" {
  description = "Número mínimo de instâncias no cluster ECS"
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Número máximo de instâncias no cluster ECS"
  type        = number
  default     = 10
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.medium"
}

variable "db_storage" {
  description = "Tamanho do armazenamento RDS em GB"
  type        = number
  default     = 100
}

variable "db_engine" {
  description = "Engine do banco de dados RDS"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Versão do engine do banco de dados RDS"
  type        = string
  default     = "17.2"
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "devops"
}

variable "db_username" {
  description = "Nome de usuário do banco de dados"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  default     = "devopsPUCRS" 
  sensitive   = true
}

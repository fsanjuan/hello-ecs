provider "aws" {
  region = "eu-west-1"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = "iyo-vpc"

  cidr = "20.10.0.0/16" # 10.0.0.0/8 is reserved for EC2-Classic

  azs                 = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets     = ["20.10.1.0/24", "20.10.2.0/24", "20.10.3.0/24"]
  public_subnets      = ["20.10.11.0/24", "20.10.12.0/24", "20.10.13.0/24"]
#   database_subnets    = ["20.10.21.0/24", "20.10.22.0/24", "20.10.23.0/24"]
#   elasticache_subnets = ["20.10.31.0/24", "20.10.32.0/24", "20.10.33.0/24"]
#   redshift_subnets    = ["20.10.41.0/24", "20.10.42.0/24", "20.10.43.0/24"]
  intra_subnets       = ["20.10.51.0/24", "20.10.52.0/24", "20.10.53.0/24"]

  create_database_subnet_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_classiclink             = true
  enable_classiclink_dns_support = true

  enable_nat_gateway = true
  single_nat_gateway = true

  customer_gateways = {
    IP1 = {
      bgp_asn    = 65112
      ip_address = "1.2.3.4"
    },
    IP2 = {
      bgp_asn    = 65112
      ip_address = "5.6.7.8"
    }
  }

  enable_vpn_gateway = true

  enable_dhcp_options              = true
  dhcp_options_domain_name         = "service.consul"
  dhcp_options_domain_name_servers = ["127.0.0.1", "10.10.0.2"]

  # VPC endpoint for S3
  enable_s3_endpoint = true

  # VPC endpoint for DynamoDB
  #enable_dynamodb_endpoint = true

  # VPC endpoint for SSM
  # enable_ssm_endpoint              = true
  # ssm_endpoint_private_dns_enabled = true
  # ssm_endpoint_security_group_ids  = [data.aws_security_group.iyo-sg.id]

  # VPC endpoint for SSMMESSAGES
  # enable_ssmmessages_endpoint              = true
  # ssmmessages_endpoint_private_dns_enabled = true
  # ssmmessages_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC Endpoint for EC2
  enable_ec2_endpoint              = true
  ec2_endpoint_private_dns_enabled = true
  ec2_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC Endpoint for EC2MESSAGES
  enable_ec2messages_endpoint              = true
  ec2messages_endpoint_private_dns_enabled = true
  ec2messages_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC Endpoint for ECR API
  enable_ecr_api_endpoint              = true
  ecr_api_endpoint_private_dns_enabled = true
  ecr_api_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC Endpoint for ECR DKR
  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC endpoint for KMS
  enable_kms_endpoint              = true
  kms_endpoint_private_dns_enabled = true
  kms_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC endpoint for ECS
  enable_ecs_endpoint              = true
  ecs_endpoint_private_dns_enabled = true
  ecs_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC endpoint for ECS telemetry
  enable_ecs_telemetry_endpoint              = true
  ecs_telemetry_endpoint_private_dns_enabled = true
  ecs_telemetry_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC endpoint for SQS
  # enable_sqs_endpoint              = true
  # sqs_endpoint_private_dns_enabled = true
  # sqs_endpoint_security_group_ids  = [data.aws_security_group.iyo-sg.id]

  tags = {
    Owner       = "iyo"
    Environment = "dev"
    Name        = "iyo-vpc"
  }

  vpc_endpoint_tags = {
    Project  = "Secret"
    Endpoint = "true"
  }
}


module "ecs_cluster" {
  source = "infrablocks/ecs-cluster/aws"
  version = "1.2.0-rc.2"
  
  region = "eu-west-1"
  vpc_id = module.vpc.vpc_id
  subnet_ids = join(",", module.vpc.private_subnets)
  
  component = "cmp"
  deployment_identifier = "dev"
  
  cluster_name = "iyo-ecs"
  cluster_instance_ssh_public_key_path = "~/.ssh/id_rsa.pub"
  cluster_instance_type = "t2.small"
  
  cluster_minimum_size = 2
  cluster_maximum_size = 10
  cluster_desired_capacity = 4
}
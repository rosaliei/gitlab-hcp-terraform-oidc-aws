# Ubuntu 24.04 (RKE2 supports Ubuntu; it does not officially support Amazon Linux)
customer_profile_ec2_ami_ssm_parameter = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
customer_profile_ec2_key_name          = "customer_profile_ec2_key"
customer_profile_ec2_monitoring        = false

# public subnets  -> jump host, nginx
# private subnets -> RKE2 masters (one per AZ) and worker
customer_profile_ec2s = {
  "hellocloud-jump" = {
    role           = "jump"
    instance_type  = "t3.micro"
    subnet         = "public"
    subnet_index   = 0
    public_ip      = true
    security_group = "customer_profile_jump_sg_id"
    disk_size      = 8
  }

  "nginx" = {
    role           = "nginx"
    instance_type  = "t3.micro"
    subnet         = "public"
    subnet_index   = 0
    public_ip      = true
    security_group = "nginx_sg_id"
    disk_size      = 10
  }

  "rke2-master-1" = {
    role           = "rke2-master"
    instance_type  = "t3.medium"
    subnet         = "private"
    subnet_index   = 0
    public_ip      = false
    security_group = "rke2_sg_id"
    disk_size      = 30
  }

  "rke2-master-2" = {
    role           = "rke2-master"
    instance_type  = "t3.medium"
    subnet         = "private"
    subnet_index   = 1
    public_ip      = false
    security_group = "rke2_sg_id"
    disk_size      = 30
  }

  "rke2-master-3" = {
    role           = "rke2-master"
    instance_type  = "t3.medium"
    subnet         = "private"
    subnet_index   = 2
    public_ip      = false
    security_group = "rke2_sg_id"
    disk_size      = 30
  }

  "rke2-worker-1" = {
    role           = "rke2-worker"
    instance_type  = "t3.medium"
    subnet         = "private"
    subnet_index   = 0
    public_ip      = false
    security_group = "rke2_sg_id"
    disk_size      = 30
  }
}

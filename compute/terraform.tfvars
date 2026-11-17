customer_profile_ec2_instance_type               = "t2.micro"
customer_profile_ec2_ami_ssm_parameter           = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
customer_profile_ec2_associate_public_ip_address = true
customer_profile_ec2_key_name                    = "customer_profile_ec2_key"
customer_profile_ec2_monitoring                  = false
customer_profile_ec2_name                        = ["hellocloud-jump", "customer-profile-ec2"]

account_ec2_instance_type               = "t2.micro"
account_ec2_ami_ssm_parameter           = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
account_ec2_associate_public_ip_address = false
account_ec2_key_name                    = "account_ec2_key"
account_ec2_monitoring                  = false
account_ec2_name                        = ["account-ec2"]
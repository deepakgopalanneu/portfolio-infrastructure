variable "access_key_id" {
	default=""
}
variable "secret_key_id" {
	default=""
}
variable "vpc_cidr" {
	default = "10.20.0.0/16"
}
variable "subnet1_cidr" {
	default = "10.20.1.0/24"
}
variable "subnet2_cidr" {
	default = "10.20.2.0/24"
}
variable "subnet3_cidr" {
	default = "10.20.3.0/24"
}
variable "routeTable_cidr" {
	default = "0.0.0.0/0"
}
variable "profile" {
  description = "The AWS profile on which Terraform has to create resources"
}
variable "aws_region" {
	description = "Region where you want to create VPC"
}
variable "vpcname"{
	description = "Pass the Name attribute/Tag for your VPC"
}
variable "bucketname"{
	default = "portfolio.deepak.gopalan"
	description="Name of the bucket _ ex: portfolio.fname.lname"
}


variable "ec2_instance_type"{
	description="Instance Type for the App Server"
	default = "t2.micro"
}

variable "encryption_algorithm"{
	default="AES256"
}
variable "keyname"{
	default="webapp1"
}
variable "ami_id"{
	description = "AMI id of the custom AMI built using packer"
}
variable "dynamodb_name"{
	description = "Name of the Dynamo DB table"
	default="csye6225"
}
variable "s3policyName"{
	default = "EC2AccessS3"
}
variable "bucketARN"{
	default="arn:aws:s3:::portfolio.deepak.gopalan/*"
}
variable "s3roleName"{
	default="EC2-CSYE6225"
}
variable "ec2InstanceProfile"{
	default="ec2-s3-profile"
}
variable "codedeploy_bucket_arn"{
	description = "Enter the bucket ARN"
}

variable "codedeploy_bucket_arn_star"{

}
variable "CodeDeploy-EC2-S3"{
	default="CodeDeploy-EC2-S3"
}
variable "CodeDeploy-Lambda-S3"{
	default="CodeDeploy-Lambda-S3"
}
variable "GH-Upload-To-S3"{
	default="GH-Upload-To-S3"
}

variable "ghactions_username"{
	default="ghactions"
}

variable "GH-Code-Deploy"{
	default= "GH-Code-Deploy"
}

variable "EC2ServiceRole"{
	default="EC2ServiceRole"
}

variable "CodeDeployServiceRole"{
	default="CodeDeployServiceRole"
}

variable "account_id"{

}

variable "CodeDeployServiceRole_policy"{
	default="arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

variable "codedeploy_appname"{
	default="portfolio-angular"
}

variable "codedeploy_group"{
	default="portfolio-angular-deployment"
}

variable "zoneId"{
	description = "Enter the ZoneId of the hosted Zone"

}
variable "route53_record_name"{
	description = "Enter Record Name ex: api.dev.domainname.tld"

}

variable "CloudWatchAgentServerPolicy_arn"{
	default = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
variable "CloudWatchAgentAdminPolicy_arn"{
	default = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}
variable "AmazonSSMManagedInstanceCore_arn"{
	default="arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

variable "lambdaHandlerMethod" {
  default="com.deepak.lambda.LambdaMethodHandler"
}

variable "ses_prod_arn"{
	default = "arn:aws:ses:us-east-1:384467288578:identity/prod.deepakgopalan.me"
}

variable "topicname"{
	default = "TOPIC_EMAIL"
}

variable "codedeploy_lambda_role_arn"{
	default = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
}

variable "codedeploy_lambda_appname"{
	default = "Lambda_codedeploy_app"
}

variable "codedeploy_lambda_bucket_arn"{}

variable "codedeploy_lambda_bucket_arn_star"{}
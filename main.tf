provider "aws" {
  region     = var.aws_region
  profile    = var.profile
  access_key = var.access_key_id
  secret_key = var.secret_key_id
}

# VPC
resource "aws_vpc" "portfolio_vpc" {
  cidr_block                       = var.vpc_cidr
  enable_dns_hostnames             = true
  enable_dns_support               = true
  enable_classiclink_dns_support   = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = var.vpcname
  }
}

# Internet Gateway
resource "aws_internet_gateway" "portfolio_gateway" {
  vpc_id = aws_vpc.portfolio_vpc.id
  tags = {
    Name = "portfolio_gateway"
  }
}

# Subnets 
resource "aws_subnet" "subnet1" {

  vpc_id                  = aws_vpc.portfolio_vpc.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpcname}_subnet1"
  }
}
resource "aws_subnet" "subnet2" {

  vpc_id                  = aws_vpc.portfolio_vpc.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpcname}_subnet2"
  }
}
resource "aws_subnet" "subnet3" {

  vpc_id                  = aws_vpc.portfolio_vpc.id
  cidr_block              = "${var.subnet3_cidr}"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpcname}_subnet3"
  }
}
# Route table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.portfolio_vpc.id
  route {
    cidr_block = var.routeTable_cidr
    gateway_id = aws_internet_gateway.portfolio_gateway.id
  }

  tags = {
    Name = "${var.vpcname}_Route_table"
  }
}

# Route table association with subnets
resource "aws_route_table_association" "route_subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "route_subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "route_subnet3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "app_security_group" {
  name        = "application security group"
  description = "Open ports 22, 80 and 4200"
  vpc_id      = aws_vpc.portfolio_vpc.id

  ingress {
    description = "Allow inbound HTTP traffic"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = [var.routeTable_cidr]
  }
  ingress {
    description     = "Allow inbound HTTP traffic"
    from_port       = "4200"
    to_port         = "4200"
    protocol        = "tcp"
    security_groups = [aws_security_group.elb_security_group.id]
  }
  ingress {
    description = "Allow inbound SSH traffic"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [var.routeTable_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "application security group"
  }
}


# Laod balancer security group
resource "aws_security_group" "elb_security_group" {
  name        = "loadbalancer security group"
  description = "Open port 80 & 443"
  vpc_id      = aws_vpc.portfolio_vpc.id

  ingress {
    description = "Allow inbound HTTP traffic"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = [var.routeTable_cidr]
  }
  ingress {
    description = "Allow inbound HTTPS traffic"
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = [var.routeTable_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.routeTable_cidr]
  }
  tags = {
    Name = "Loadbalancer security group"
  }
}



# This policy is required for EC2 instances to download latest application revision.
resource "aws_iam_policy" "CodeDeploy_EC2_S3" {
  name        = "${var.CodeDeploy-EC2-S3}"
  description = "Policy for EC2 instance to retrieve  artifacts in S3"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [ "arn:aws:s3:::codedeploy.prod.deepakgopalan.me" , "arn:aws:s3:::codedeploy.prod.deepakgopalan.me/*" ]
    }
  ]
}
EOF
}
# Policy allows GitHub Actions to upload artifacts from latest successful build to dedicated S3 bucket used by CodeDeploy.
# Add this to the dev-ghactions and prod-ghactions users
resource "aws_iam_policy" "GH_Upload_To_S3" {
  name        = "${var.GH-Upload-To-S3}"
  description = "Policy for Github actions script to store artifacts in S3"
  policy      = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [ "arn:aws:s3:::codedeploy.prod.deepakgopalan.me" , "arn:aws:s3:::codedeploy.prod.deepakgopalan.me/*"]
    }
  ]
}
EOF
}


# policy allows GitHub Actions to call CodeDeploy APIs to initiate application deployment on EC2 instances.
resource "aws_iam_policy" "GH_Code_Deploy" {
  name        = "${var.GH-Code-Deploy}"
  description = "Policy allows GitHub Actions to call CodeDeploy APIs to initiate application deployment on EC2 instances."
  policy      = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.aws_region}:${var.account_id}:application:${var.codedeploy_appname}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.aws_region}:${var.account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${var.aws_region}:${var.account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${var.aws_region}:${var.account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}

#attach policies to ghactions user

#attaching GH_Upload_To_S3 policy to ghactions  user
resource "aws_iam_user_policy_attachment" "attach_GH_Upload_To_S3" {
  user       = var.ghactions_username
  policy_arn = aws_iam_policy.GH_Upload_To_S3.arn
}

#attaching GH_Code_Deploy policy to ghactions  user
resource "aws_iam_user_policy_attachment" "attach_GH_Code_Deploy" {
  user       = var.ghactions_username
  policy_arn = aws_iam_policy.GH_Code_Deploy.arn
}

# create Role for Code Deploy
resource "aws_iam_role" "EC2ServiceRole" {
  name               = var.EC2ServiceRole
  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
    "Service": "ec2.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }
  ]
}
EOF
  tags = {
    Name = "EC2ServiceRole access policy"
  }
}
#create CodeDeployServiceRole role
resource "aws_iam_role" "CodeDeployServiceRole" {
  name = var.CodeDeployServiceRole
  # policy below has to be edited
  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    Name = "CodeDeployEC2Role access policy"
  }
}
#Attaching CloudWatchAgentServerPolicy to EC2 role
resource "aws_iam_role_policy_attachment" "cloudwatch_CloudWatchAgentServerPolicy_attacher" {
  policy_arn = var.CloudWatchAgentServerPolicy_arn
  role       = aws_iam_role.EC2ServiceRole.name
}
resource "aws_iam_instance_profile" "ec2_role_profile" {
  name = var.ec2InstanceProfile
  role = aws_iam_role.EC2ServiceRole.name
}



#Policy to be attached with CodeDeployServiceRole role
resource "aws_iam_role_policy_attachment" "CodeDeployServiceRole_policy_attacher" {
  role       = aws_iam_role.CodeDeployServiceRole.name
  policy_arn = var.CodeDeployServiceRole_policy
}



#attach policies to codedeploy role
resource "aws_iam_role_policy_attachment" "EC2ServiceRole_policy_attacher" {
  role       = aws_iam_role.EC2ServiceRole.name
  policy_arn = aws_iam_policy.CodeDeploy_EC2_S3.arn
}

# Code Deploy Applicaiton 
resource "aws_codedeploy_app" "codedeploy_app" {
  compute_platform = "Server"
  name             = var.codedeploy_appname
}

#  CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "example" {
  app_name               = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name  = var.codedeploy_group
  service_role_arn       = aws_iam_role.CodeDeployServiceRole.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  autoscaling_groups = [aws_autoscaling_group.autoscaling_group.name]
  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.target_group.name
    }
  }
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "Application Server"
    }
  }
}



# Autoscaling launch configuration

resource "aws_launch_configuration" "launch_configuration" {
  name                        = "autoscaling-launch-config"
  image_id                    = var.ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = var.keyname
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_role_profile.name
  security_groups             = [aws_security_group.app_security_group.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

#  create auto-scaling group
resource "aws_autoscaling_group" "autoscaling_group" {
  name                 = "asg_launch_config"
  max_size             = 5
  min_size             = 1
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.launch_configuration.name
  default_cooldown     = 60
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.target_group.arn]
  vpc_zone_identifier  = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "Application Server"
    propagate_at_launch = true
  }
}
# create auto-scaling policy for ScaleUP
resource "aws_autoscaling_policy" "WebServerScaleUpPolicy" {
  name                   = "WebServerScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
}

# create auto-scaling policy for ScaleDown
resource "aws_autoscaling_policy" "WebServerScaleDownPolicy" {
  name                   = "WebServerScaleDownPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
}

#  create cloudwatch alarm based on which autoscaling - ScaleUP will occur
resource "aws_cloudwatch_metric_alarm" "CPUAlarmHigh" {
  alarm_name          = "CPUAlarmHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_group.name
  }

  alarm_description = "Scale-up if CPU > 90% for 5 minutes"
  alarm_actions     = [aws_autoscaling_policy.WebServerScaleUpPolicy.arn]
}

#  create cloudwatch alarm based on which autoscaling - ScaleDown will occur
resource "aws_cloudwatch_metric_alarm" "CPUAlarmLow" {
  alarm_name          = "CPUAlarmLow"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_group.name
  }

  alarm_description = "Scale-down if CPU < 3% for 5 minutes"
  alarm_actions     = [aws_autoscaling_policy.WebServerScaleDownPolicy.arn]
}

# create target group 
resource "aws_lb_target_group" "target_group" {
  name        = "webapp-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.portfolio_vpc.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = 200
  }
}

# create listner for loadbalancer
resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.webapp_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}

# create listner for HTTPS
resource "aws_lb_listener" "https_listner" {
  load_balancer_arn = aws_lb.webapp_elb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
#create application load balancer
resource "aws_lb" "webapp_elb" {
  name = "webapp-elb"

  security_groups            = [aws_security_group.elb_security_group.id]
  load_balancer_type         = "application"
  internal                   = false
  enable_deletion_protection = false
  subnets                    = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]
  tags = {
    Name = "webapp-loadbalancer"
  }
}

# get certificate from Aws certificate manager
data "aws_acm_certificate" "certificate" {
  domain = var.route53_record_name
  tags = {
    Name = "NewCert"
  }
}

# get  route53 zone pointing to existing record name
data "aws_route53_zone" "primary" {
  name = var.route53_record_name
}

# create DNS Record
resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.route53_record_name
  type    = "A"
  alias {
    name                   = aws_lb.webapp_elb.dns_name
    zone_id                = aws_lb.webapp_elb.zone_id
    evaluate_target_health = false
  }
}

#################### SNS & LAMBDA #####################

#create SNS topic
resource "aws_sns_topic" "email_topic" {
  name = var.topicname
}

#create Lambda 
resource "aws_lambda_function" "lambda_for_email" {
  filename      = "lambda_function1.zip"
  function_name = "lambda_for_email"
  role          = aws_iam_role.lambda_service_role.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  memory_size   = 512
  timeout       = 25
}

#subscribe to the topic
resource "aws_sns_topic_subscription" "subscribe_lambda_sns" {
  topic_arn = aws_sns_topic.email_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_for_email.arn
}

# IAM role for Lambda 
resource "aws_iam_role" "lambda_service_role" {
  name = "lambda_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#IAM ROLE policy For Lambda to access SES Domain
resource "aws_iam_role_policy" "lambda_ses_policy" {
  name = "lambda_ses_policy"
  role = aws_iam_role.lambda_service_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "ses:SendEmail",
        "Resource": "arn:aws:ses:us-east-1:384467288578:identity/deepakgopalan.me"
      }
    ]
  }  
  EOF
}



#IAM Policy for Lambda to allow SNS event to trigger it
resource "aws_iam_policy" "lambda_sns_policy" {
  name = "lambda_sns_policy"

  policy = <<-EOF
{
  "Statement":[
    {"Condition":
      {"ArnLike":{"AWS:SourceArn":"${aws_sns_topic.email_topic.arn}"}},
      "Resource":"${aws_lambda_function.lambda_for_email.arn}",
      "Action":"lambda:invokeFunction",
      "Sid":"",
      "Effect":"Allow"
    }],
  "Id":"default",
  "Version":"2012-10-17"
}
  EOF
}



#Policy to be attached with Lambda role
resource "aws_iam_role_policy_attachment" "lambda_snsinvokepolicy_attacher" {
  role       = aws_iam_role.lambda_service_role.name
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
}

#
resource "aws_iam_role_policy_attachment" "BasicExecutionAccessToLambdaFunctionRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_service_role.name
}

#IAM Policy for EC2 to publish to SNS Topic
resource "aws_iam_role_policy" "ec2_sns_policy" {
  name = "ec2_sns_policy"
  role = aws_iam_role.EC2ServiceRole.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": ["sns:Publish","sns:CreateTopic"],
        "Effect": "Allow",
        "Resource": "${aws_sns_topic.email_topic.arn}"
      }
    ]
  }
  EOF
}

resource "aws_lambda_permission" "allow_sns" {
  action        = "lambda:*"
  function_name = aws_lambda_function.lambda_for_email.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.email_topic.arn
}

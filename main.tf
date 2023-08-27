terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket12345"
    key     = "myproject-${var.aws_region}.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
}

provider "aws" {
  region = var.aws_region
}

resource "aws_elastic_beanstalk_application" "elasticapp" {
  name = "myapp-unique1234-${var.aws_region}"
}

resource "aws_iam_role" "elasticbeanstalk_ec2_role" {
  name = "aws-elasticbeanstalk-ec2-role-${var.aws_region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "elasticbeanstalk_webtier_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.elasticbeanstalk_ec2_role.name
}

resource "aws_iam_instance_profile" "elasticbeanstalk_ec2_instance_profile" {
  name = "aws-elasticbeanstalk-ec2-role-${var.aws_region}"
  role = aws_iam_role.elasticbeanstalk_ec2_role.name
}

resource "aws_elastic_beanstalk_environment" "beanstalkappenv" {
  name                = "myenv-${var.aws_region}"
  application         = aws_elastic_beanstalk_application.elasticapp.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.0 running Docker"
  tier                = "WebServer" # Please adjust this to either 'WebServer' or 'Worker' based on your needs

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role-${var.aws_region}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = "200"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.medium"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "2"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
}

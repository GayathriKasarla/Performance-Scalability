provider "aws" {
    region = var.region
}

resource "aws_vpc" "uda_test" {
    cidr_block = "80.0.0.0/16"
    tags = {
        Name = "uda_test"
    }
}

resource "aws_subnet" "uda_subnet_pub_test"{
    vpc_id = "${aws_vpc.uda_test.id}"
    cidr_block = "80.0.1.0/24"

    tags = {
        Name = "Uda_subnet"
    }
}

resource "aws_security_group" "uda_secgrp" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.uda_test.id}"

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.uda_test.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "uda_test_sec_grp"
  }
}
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

  tags = {
    Name = "IAM for Lambda"
  }
}

resource "aws_iam_policy" "policy" {
  name        = "Lambda-VPC-policy"
  description = "Lambda policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
             "Effect": "Allow",
             "Action": [
                 "logs:CreateLogGroup",
                 "logs:CreateLogStream",
                 "logs:PutLogEvents",
                 "ec2:CreateNetworkInterface",
                 "ec2:DescribeNetworkInterfaces",
                 "ec2:DeleteNetworkInterface"
             ],
             "Resource": "*"
         }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}
 

data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "greet_lambda.py"
    output_path   = "lambda_function.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function.zip"
  function_name = "Udacity_lambda"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "greet_lambda.lambda_handler"

  runtime = "python3.7"

  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = ["${aws_subnet.uda_subnet_pub_test.id}"]
    security_group_ids = ["${aws_security_group.uda_secgrp.id}"]
  }

  environment {
    variables = {
      foo = "bar"
    }
  }
}
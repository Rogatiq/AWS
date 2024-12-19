terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# All VPC subnets and network configuration
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.az1
  tags = {
    Name = "${var.prefix}-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.az2
  tags = {
    Name = "${var.prefix}-public-subnet-2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public_rta_1" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "public_rta_2" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet_2.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Creation of Security Groups
resource "aws_security_group" "web_sg" {
  name        = "${var.prefix}-web-sg"
  description = "ec2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "default" {
  key_name   = "${var.prefix}-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "ssh_sg" {
  name        = "${var.prefix}-ssh-sg"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"] # Public ip changes constantly, so left it open
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.default.key_name

  # Attach IAM instance profile for permissions
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  # Networking: Assign a public IP and configure security groups
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet_1.id


  security_groups = [aws_security_group.web_sg.id]


  # User data for configuring the instance at launch
  user_data = base64encode(templatefile("userdata.tpl", {
    bucket_name = aws_s3_bucket.files_bucket.bucket
    region      = var.region
  }))

  # Tags for identification and tracking
  tags = {
    Name        = "${var.prefix}-ec2-instance"
    Environment = var.region
  }
}


# S3 Bucket deplyoment 
resource "aws_s3_bucket" "files_bucket" {
  bucket = "${var.prefix}-files-bucket-${random_integer.bucket_rand.result}"
  
  tags = {
    Name = "${var.prefix}-files-bucket"
  }
}

resource "aws_s3_bucket_versioning" "files_versioning" {
  bucket = aws_s3_bucket.files_bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "random_integer" "bucket_rand" {
  min = 10000
  max = 99999
}



# DynamoDB creation
resource "aws_dynamodb_table" "filenames_table" {
  name           = "${var.prefix}-filenames"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "filename"
  attribute {
    name = "filename"
    type = "S"
  }
  tags = {
    Name = "${var.prefix}-filenames"
  }
}



# IAM Roles & Policies for Lambda and EC2
data "aws_iam_policy_document" "lambda_s3_access" {
  statement {
    actions = ["dynamodb:PutItem"]
    resources = [
      aws_dynamodb_table.filenames_table.arn
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

data "aws_iam_policy_document" "ec2_s3_access" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.files_bucket.arn,
      "${aws_s3_bucket.files_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.prefix}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "${var.prefix}-ec2-s3-policy"
  description = "Policy for EC2 to access S3"
  policy      = data.aws_iam_policy_document.ec2_s3_access.json
}

resource "aws_iam_role_policy_attachment" "ec2_role_s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}



resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action: "sts:AssumeRole",
      Effect: "Allow",
      Principal: {
        Service: "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.prefix}-lambda-policy"
  description = "IAM policy for Lambda to access DynamoDB"
  policy      = data.aws_iam_policy_document.lambda_s3_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda Function triggered by S3
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "file_handler" {
  function_name    = "${var.prefix}-file-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      DYNAMO_TABLE = aws_dynamodb_table.filenames_table.name
    }
  }
}

resource "aws_s3_bucket_notification" "files_notification" {
  bucket = aws_s3_bucket.files_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.file_handler.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ""
  }

  depends_on = [aws_lambda_function.file_handler, aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_handler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.files_bucket.arn
}


# Output
output "instance_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "owner-id"
    values = ["137112412989"] # Amazon Linux owner ID
  }

  owners = ["137112412989"] # Amazon Linux AMI owner
}

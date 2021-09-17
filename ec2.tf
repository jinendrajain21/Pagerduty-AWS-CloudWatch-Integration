/*terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
*/
# Configure the AWS Provider
#########################PROVIDER##############
/*provider "aws" {
  region = "ap-south-1"
}*/
######################VPC######################

resource "aws_vpc" "pager-vpc" {
  cidr_block       = "10.30.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Pager-VPC"
  }
}


############################Internet-Gateway#################
resource "aws_internet_gateway" "Pagerinternet-gw" {
  vpc_id = aws_vpc.pager-vpc.id

  tags = {
    Name = "PagerInternet-GW"
  }
}

##################ROUTE-TABLE###############
resource "aws_route_table" "Pager-public" {
  vpc_id = aws_vpc.pager-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Pagerinternet-gw.id
  }
  tags = {
    Name = "PagerPublicRoute"
  }
}

resource "aws_route_table_association" "Pager-public-subnet" {
  subnet_id      = aws_subnet.public-subnet-Pager.id
  route_table_id = aws_route_table.Pager-public.id
}

########################SUBNET#########
resource "aws_subnet" "public-subnet-Pager" {
  vpc_id                  = aws_vpc.pager-vpc.id
  cidr_block              = "10.30.1.0/24"
  map_public_ip_on_launch = "true"
  #availability_zone       = "eu-west-1a"

  tags = {
    Name = "Public-Subnet-Pager"
  }
}

##################Security-Group###############
variable "sg-ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [22, 80]
}

variable "SG-ports" {
  type        = list(number)
  description = "list of Egress ports"
  default     = [0]
}
resource "aws_security_group" "Pager-SG" {
  vpc_id      = aws_vpc.pager-vpc.id
  name        = "Pager-SG"
  description = "security group that allows ssh and all egress traffic"
  /*ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }*/

  dynamic "ingress" {
    for_each = var.sg-ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "egress" {
    for_each = var.SG-ports
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

#####################EC2with nginx server ######################

data "aws_ami" "test_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
resource "aws_instance" "PagerDuty-instance" {
  ami           = data.aws_ami.test_ami.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public-subnet-Pager.id

  vpc_security_group_ids = [aws_security_group.Pager-SG.id]

  key_name = aws_key_pair.mykeypair.key_name

  /*provisioner "remote-exec" {
    inline = [<<-EOF
    sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo yum install firewalld -y
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --reload
    sudo touch /etc/httpd/conf.d/lb.conf
    sudo bash -c 'echo "<Proxy balancer://linuxhelp>
              BalancerMember http://"${aws_instance.PagerDuty-instance.private_ip}":80
              ProxySet lbmethod=byrequests
      </Proxy>
      <Location /balancer-manager>
              SetHandler balancer-manager
      </Location>
      ProxyPass /balancer-manager !
      ProxyPass / balancer://linuxhelp/" >> /etc/httpd/conf.d/lb.conf '
    sudo systemctl start firewalld
    EOF
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./accenture.pem")
      host        = self.public_ip
    }
  }
*/

  tags = {
    Name = "website-instance"
  }
}
resource "aws_key_pair" "mykeypair" {
  key_name   = "accenture"
  public_key = "ssh-rsa AAAAB3NAAABAQC5ywk5MTcBnXihu1UcB2bBgZ5Jbo8ZBPno18Ie4xSrOkUClg+fp+I1zIK28nNv3OhJ6qsM1qTomHbrJbpbtoQhKCaAvuB2IMy1+RUcVTOLHWLpUWDLhWgj6a9I+Rv7gQ4KDyHWxt3RWdHR8wu7GDh7nZ9TG2xSgE2LtBmiHhrBhkUZypqIVtHG8pMR6D3LuRzT3MGi2WRK0bv1DxKlCfwLzF1pyb8cRGRHsFHYLq+bIN58tvAzqQQde2AiHbPt0hVsDqV7znfgH5T1lKVU7bLKOOZRAO/S0eVl7cCKi5XJTuDR1TExKxXQYyQu6ErsDsScdx+O+i+tY2j64PcR+p6r"
}



provider "aws" {
    region = "${var.region}"
}

resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Custom VPC"
  }
}

resource "aws_subnet" "public_subnet1a" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public Subnet 1A"
  }
}
resource "aws_subnet" "public_subnet2a" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet 2A"
  }
}

resource "aws_internet_gateway" "custom_ig" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name =" Custom Internet Gateway"
  }
}

resource "aws_route_table" "public_rt1A" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_ig.id
  }

  
  tags = {
    Name = "Public Route Table1A"
  }
}

resource "aws_route_table" "public_rt2A" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_ig.id
  }

  
  tags = {
    Name = "Public Route Table2A"
  }
}
resource "aws_route_table_association" "public_2_rt_a" {
  subnet_id      = aws_subnet.public_subnet2a.id
  route_table_id = aws_route_table.public_rt2A.id
}
resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.public_subnet1a.id
  route_table_id = aws_route_table.public_rt1A.id
}

resource "aws_security_group" "sg_alb" {
  name   = "sg_alb"
  vpc_id = aws_vpc.custom_vpc.id
  
  ingress {
    description      = "Allow http request from anywhere"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
  
  ingress {
    description      = "Allow https request from anywhere"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "nginx_sg" {
  name   = "HTTP and SSH"


  vpc_id = aws_vpc.custom_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 
   ingress {
    description = "Allow Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_instance" {
  ami           = "ami-079db87dc4c10ac91"
  instance_type = "t2.micro"
  key_name      = "Nginx"

  subnet_id                   = aws_subnet.public_subnet1a.id
  vpc_security_group_ids      = [aws_security_group.nginx_sg.id]
  associate_public_ip_address = true


provisioner remote-exec{
 
   connection {
   type = "ssh"
   user= "ec2-user"
  private_key = "${file("/home/cloudshell-user/Task9/Nginx.pem")}"
  host = self.public_ip
  }
  
    
    inline = [
        "sudo yum install -y nginx",
        "sudo systemctl start nginx",
	"sudo chown ec2-user /usr/share/nginx/html/index.html",
        "sudo echo 'Hello from EC2#1'  >  /usr/share/nginx/html/index.html" 
    ]
   }
  tags = {
    Name = "Public1a"
  }

} 
resource "aws_eip" "Publc" {
instance        = aws_instance.web_instance.id
vpc = true
   }


resource "aws_instance" "web_instance2" {
  ami           = "ami-079db87dc4c10ac91"
  instance_type = "t2.micro"
  key_name      = "Nginx"

  subnet_id                   = aws_subnet.public_subnet2a.id
  vpc_security_group_ids      = [aws_security_group.nginx_sg.id]
  associate_public_ip_address = true

 
 
provisioner remote-exec{
 
    connection {
    type = "ssh"
    user= "ec2-user"
    private_key = "${file("/home/cloudshell-user/Task9/Nginx.pem")}"
    host = self.public_ip
   }
    
    
    inline = [
        "sudo yum install -y nginx",
        "sudo systemctl start nginx",
        "sudo echo 'Hello From EC2#2' >  /usr/share/nginx/html/index.html "
    ]
   }
 
  }
  resource "aws_eip" "Publc2" {
  instance        = aws_instance.web_instance2.id
  vpc = true

  tags = {
    Name = "Public2"
  }
}



#target group
resource "aws_lb_target_group" "alb_tg" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.custom_vpc.id

    health_check {
    enabled             = true
    interval            = 10
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets	     = [aws_subnet.public_subnet1a.id, aws_subnet.public_subnet2a.id]
  depends_on         = [aws_internet_gateway.custom_ig]
}

# Attach the target group for "EC2#1" ALB
resource "aws_lb_target_group_attachment" "tg_attachment_1" {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    target_id        = aws_instance.web_instance.id
    port             = 80
}
# Attach the target group for "EC2#2" ALB
resource "aws_lb_target_group_attachment" "tg_attachment_2" {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    target_id        = aws_instance.web_instance2.id 
    port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}


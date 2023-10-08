resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr
 }

 resource "aws_subnet" "subnet1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "172.20.0.0/27"
    availability_zone = "eu-west-2a" 
    map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "172.20.0.32/27"
    availability_zone = "eu-west-2b"
    map_public_ip_on_launch = true  
}

resource "aws_internet_gateway" "my-igw" {
    vpc_id = aws_vpc.myvpc.id 
}

resource "aws_route_table" "my-route-table" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-igw.id
    }
}

resource "aws_route_table_association" "route-table-associateion-1" {
    route_table_id = aws_route_table.my-route-table.id
    subnet_id = aws_subnet.subnet1.id  
}

resource "aws_route_table_association" "route-table-associateion-2" {
    route_table_id = aws_route_table.my-route-table.id
    subnet_id = aws_subnet.subnet2.id  
}

resource "aws_security_group" "web-sg" {
    name = "web-sec-group"
    vpc_id = aws_vpc.myvpc.id

    ingress {
        description = "HTTP Traffic from VPC"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "SSH Traffic"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

     egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    
    tags = {
        name = "web-server-sg"
    }
}

# create s3 bucket and allow public read
resource "aws_s3_bucket" "mybucket" {
    depends_on = [ 
        aws_s3_bucket_ownership_controls.mybucket,
        aws_s3_bucket_public_access_block.mybucket,
     ]

    bucket = "website-storage-bucket"
    acl = "public-read"
}

# create 1st instance (first web server)
resource "aws_instance" "web-server-1" {
    ami = "ami-0eb260c4d5475b901"
    instance_type = "t2.micro"
    key_name = "server"
    subnet_id = aws_subnet.subnet1.id
    vpc_security_group_ids = [aws_security_group.web-sg.id]
    user_data = base64encode(file("userdata1.sh"))
    tags = {
      Name = "webserver1"
    }
}

# create 2nd instance (second web server)
resource "aws_instance" "web-server-2" {
    
    ami = "ami-0eb260c4d5475b901"
    instance_type = "t2.micro"
    key_name = "server"
    subnet_id = aws_subnet.subnet2.id
    vpc_security_group_ids = [aws_security_group.web-sg.id]
    user_data = base64encode(file("userdata2.sh"))

    tags = {
      Name = "webserver2"
    }
}

#create alb
resource "aws_alb" "myalb" {
    name = "myalb"
    internal = false
    load_balancer_type = "application"

    security_groups = [ aws_security_group.web-sg.id ]
    subnets = [ aws_subnet.subnet1.id, aws_instance.web-server-2.id ]

    tags = {
      Name = "Web-ALB"
    }
}

resource "aws_alb_target_group" "tg" {
    name = "myTG"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id

    health_check {
      path = "/"
      port = "traffic-port"
    }
}

resource "aws_lb_target_group_attachment" "attach1" {
    target_id =aws_instance.web-server-1.id
    target_group_arn = aws_alb_target_group.tg.arn
    port = 80 
 }

 resource "aws_lb_target_group_attachment" "attach2" {
    target_id =aws_instance.web-server-2.id
    target_group_arn = aws_alb_target_group.tg.arn
    port = 80 
 }

resource "aws_alb_listener" "label" {
    load_balancer_arn = aws_alb.myalb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      target_group_arn = aws_alb_target_group.tg.arn
      type = "forward"
    }
}

 output "loadbalancerdns" {
    value = "aws_lb.myalb.dns_name"
  }

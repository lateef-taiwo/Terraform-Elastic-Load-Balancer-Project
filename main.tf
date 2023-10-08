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

resource "aws_internet_gatewat" "my-igw" {
    vpc_id = aws_vpc.myvpc.id 
}

resource "aws_route_table" "my-route-table" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gatewat.my-igw.id
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

resource "aws_security_groug" "web-sg" {
    name = "web-sec-group"
    vpc_id = aws_vpc.myvpc.id

    ingress {
        description = "HTTP Traffic from VPC"
        from_port = 80
        to_port = 80
        protocol = tcp
        cidr_block = ["0.0.0.0/0"]
    }
    ingress {
        description = "SSH Traffic"
        from_port = 22
        to_port = 22
        protocol = tcp
        cidr_block = ["0.0.0.0/0"]
    }

}

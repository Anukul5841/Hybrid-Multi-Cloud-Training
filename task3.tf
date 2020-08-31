provider "aws" {
  region = "ap-south-1"
  profile = "Ayush"
}

resource "aws_vpc" "coolvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "coolvpc"
  }
}


resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.coolvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public_subnet"
  }
}


resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.coolvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.coolvpc.id

  tags = {
    Name = "cool_gateway"
  }
}

resource "aws_route_table" "coolroutingtable" {
  vpc_id = aws_vpc.coolvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

 
  tags = {
    Name = "cool_routingtable"
  }
}

resource "aws_route_table_association" "cool" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.coolroutingtable.id
}

resource "aws_security_group" "wordpressSG" {
  name = "wordpressSG"
  vpc_id = aws_vpc.coolvpc.id   

  ingress {
    
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_key_pair"   "task3key" {
   key_name = "task3-key"
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCHrt8EnqH9ymF2oDm9qNykz3iLIFiwbkaM0nwK47K+ffZMWxGFmETo3O2uGu4GEbOIje8NrewyM5Ac/uP5jXKSFErhcRNQYPBWIqVirYr3hfOB7VEDZFMXA1TeTgG1wpHPEAl3TUH4cRXSKs0TFrQqNQ9Y6XfycTBfsi7Tc+pIRzHeM3Rasu2XTdfuY5fGDblUOjENdjS558+mlMUQRz91JT6JsVGMI1ZCbduTHe/rbF0uYkHBTwmw/8HqOcU4iMsqhzFXdAX3PpPdQvKyvPF0kO/H0/ywIJfXJ0Ti/FvFxv9OLtZc8zhe+SH7epsSVQAUhdX6z/Ye221dj/povtg7 imported-openssh-key"
}

resource "aws_instance"  "webpage"  {
  ami           = "ami-00116985822eb866a"
  instance_type = "t2.micro"
  key_name = aws_key_pair.task3key.key_name
  vpc_security_group_ids = [ aws_security_group.wordpressSG.id ]
  subnet_id = aws_subnet.public.id
  

 tags = {
  Name = "wpOS"
 }
}


resource "aws_security_group" "mysqlSG" {
  name = "mysqlSG"
  vpc_id = aws_vpc.coolvpc.id
   

  ingress {
    
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance"  "webserver"  {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name = aws_key_pair.task3key.key_name
  vpc_security_group_ids = [ aws_security_group.mysqlSG.id ]
  subnet_id = aws_subnet.private.id

 tags = {
  Name = "mysqlOS"
 }
}





  provider "aws" {
  region = "ap-south-1"
  profile = "Ayush"
}



resource "aws_key_pair"   "task2key" {
   key_name = "task2-key"
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCHrt8EnqH9ymF2oDm9qNykz3iLIFiwbkaM0nwK47K+ffZMWxGFmETo3O2uGu4GEbOIje8NrewyM5Ac/uP5jXKSFErhcRNQYPBWIqVirYr3hfOB7VEDZFMXA1TeTgG1wpHPEAl3TUH4cRXSKs0TFrQqNQ9Y6XfycTBfsi7Tc+pIRzHeM3Rasu2XTdfuY5fGDblUOjENdjS558+mlMUQRz91JT6JsVGMI1ZCbduTHe/rbF0uYkHBTwmw/8HqOcU4iMsqhzFXdAX3PpPdQvKyvPF0kO/H0/ywIJfXJ0Ti/FvFxv9OLtZc8zhe+SH7epsSVQAUhdX6z/Ye221dj/povtg7 imported-openssh-key"
}

output"MykeyName"{
 	value = aws_key_pair.task2key.key_name
}



resource "aws_security_group" "http" {
  name = "task2Security"
  vpc_id = "vpc-139a877b"
  description = "Allow http and ssh"
   

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
 
resource "aws_instance"  "webpage"  {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = aws_key_pair.task2key.key_name
  security_groups = [ "task2Security" ]

 tags = {
  Name = "Task2OS"
 }
}
resource "null_resource" "remote1"  {

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/pc1/Downloads/Mykey1.pem")
    host     = aws_instance.webpage.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git  -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
}


resource "aws_efs_file_system" "efs" {
  creation_token = "my-efs"

  tags = {
    Name = "MyEFS"
  }
}

resource "aws_efs_mount_target" "efsMount" {

depends_on = [
   aws_efs_file_system.efs,
  ]

  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = "subnet-e3e7dd8b"
  security_groups = [ aws_security_group.http.id]
  
}

output"EfsMount-dns-name"{
 	value = aws_efs_file_system.efs.dns_name
}



resource "null_resource" "remoteconnect2"  {


depends_on = [
   
    null_resource.remote1,
  ]



 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/pc1/Downloads/Mykey1.pem")
    host     = aws_instance.webpage.public_ip
  }

provisioner "remote-exec" {
    inline = [
      " sudo yum  install nfs-utils -y",
      "sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport  ${aws_efs_file_system.efs.dns_name}:/   /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Anukul5841/Task-2.git  /var/www/html/"
    ]
  }
}



resource "aws_s3_bucket" "task2bucket" {
  bucket = "anukul5841"
  acl    = "public-read"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = "anukul5841"
}

resource "aws_s3_bucket_object" "object" {
  bucket = "anukul5841"
  key    = "image.jpg"
  source = "C:/Users/pc1/Downloads/image.jpg"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.task2bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.task2bucket.id
  }
  enabled             = true
  is_ipv6_enabled     = true
default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id =  aws_s3_bucket.task2bucket.id


    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
       
    viewer_protocol_policy = "allow-all"
     min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    
  }

 restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
 tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "domain-name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}






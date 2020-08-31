provider "aws" {
  region = "ap-south-1"
  profile = "Ayush"
}



resource "aws_key_pair"   "taskkey" {
   key_name = "task-key"
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCHrt8EnqH9ymF2oDm9qNykz3iLIFiwbkaM0nwK47K+ffZMWxGFmETo3O2uGu4GEbOIje8NrewyM5Ac/uP5jXKSFErhcRNQYPBWIqVirYr3hfOB7VEDZFMXA1TeTgG1wpHPEAl3TUH4cRXSKs0TFrQqNQ9Y6XfycTBfsi7Tc+pIRzHeM3Rasu2XTdfuY5fGDblUOjENdjS558+mlMUQRz91JT6JsVGMI1ZCbduTHe/rbF0uYkHBTwmw/8HqOcU4iMsqhzFXdAX3PpPdQvKyvPF0kO/H0/ywIJfXJ0Ti/FvFxv9OLtZc8zhe+SH7epsSVQAUhdX6z/Ye221dj/povtg7 imported-openssh-key"
}

output"MykeyName"{
 	value = aws_key_pair.taskkey.key_name
}



resource "aws_security_group" "http" {
  name = "task security"
  vpc_id = "vpc-139a877b"
   

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
  key_name = aws_key_pair.taskkey.key_name
  security_groups = [ "task security" ]

 tags = {
  Name = "terraOS"
 }
}
resource "null_resource" "remote4"  {

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

 resource "aws_ebs_volume" "ebs1"{
   availability_zone = aws_instance.webpage.availability_zone
   size                        = 1
 
  tags = {
    Name = " myebs1"
 }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
   volume_id   = aws_ebs_volume.ebs1.id
  instance_id = aws_instance.webpage.id
  force_detach = true
}

resource "null_resource" "remoteconnect5"  {

depends_on = [
   
    aws_volume_attachment.ebs_att,
  ]


 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/pc1/Downloads/Mykey1.pem")
    host     = aws_instance.webpage.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Anukul5841/task1.git  /var/www/html/"
    ]
  }
}

resource "aws_s3_bucket" "taskbucket" {
  bucket = "anukul1234"
  acl    = "public-read"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = "anukul1234"
}

resource "aws_s3_bucket_object" "object" {
  bucket = "anukul1234"
  key    = "car.jpg"
  source = "C:/Users/pc1/Pictures/car.jpg"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.taskbucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.taskbucket.id
  }
  enabled             = true
  is_ipv6_enabled     = true
default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id =  aws_s3_bucket.taskbucket.id


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






  provider "aws" {
  region  = "ap-south-1"
  profile = "Deepak"

  }


  resource "tls_private_key" "key-pair" {
  algorithm = "RSA"
  }

  resource "aws_key_pair" "key" {
  key_name = "DeepakT1"
  public_key = tls_private_key.key-pair.public_key_openssh

  depends_on = [ tls_private_key.key-pair ,]
  }

  resource "local_file" "save_key" {
      content =tls_private_key.key-pair.private_key_pem
      filename = "DeepakT1.pem"
  }







  resource "aws_security_group" "task2-securitygroup" {
  name        = "task2-securitygroup"


  ingress {
    
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }





  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "task2-securitygroup"
  }
  }







  resource "aws_instance" "firstos1" {
  ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "DeepakT1"
  security_groups = ["task2-securitygroup"]





  connection {
  type = "ssh"
  user = "ec2-user"
  private_key = tls_private_key.key-pair.private_key_pem
  host = aws_instance.firstos1.public_ip

  }

  provisioner "remote-exec" {
  inline = [
  "sudo yum install httpd php git -y",
  "sudo systemctl restart httpd",
  "sudo systemctl enable httpd",
  ]
  }
    tags = {
      Name= "webserver"
  }
  }




  resource "aws_ebs_volume" "ebs" {
  availability_zone = aws_instance.firstos1.availability_zone
  size = 1
  tags = {
  Name = "task2_ebs"
  }
  }




  resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdd"
  volume_id = "${aws_ebs_volume.ebs.id}"
  instance_id = "${aws_instance.firstos1.id}"
    force_detach = true
  }



  resource "null_resource" "remote1" {

  depends_on = [
  aws_volume_attachment.ebs_attach,
  ]

  connection {
  type ="ssh"
  user = "ec2-user"
  private_key = tls_private_key.key-pair.private_key_pem
  host = aws_instance.firstos1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdd",
      "sudo mount /dev/xvdd /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/jaiswaldj/aws-task-2.git /var/www/html/"
  ]
  } 
  }


  resource "aws_s3_bucket" "terratask2bucket" {
  bucket ="terra-task2-bucket-deepak"
  acl ="public-read"

  tags= {
    Name ="terra-task2-bucket-deepak"
  }
  }


  resource "aws_s3_bucket_object" "terratask2object" {
  depends_on = [aws_s3_bucket.terratask2bucket,]
  bucket = "terra-task2-bucket-deepak"
  key   = "ab.jpg"
  source = "C:/Users/Jarvis/Desktop/tera/task1/ab.jpg"
  acl = "public-read"
  }




  locals {
  s3_origin_id = "myS3Origin"
  }

  resource "aws_cloudfront_origin_access_identity" "taskoai" {
  comment = "OAI"
  }


resource "aws_cloudfront_distribution" "terratask2_cloudfront_distribution" {
  origin {
    domain_name =aws_s3_bucket.terratask2bucket.bucket_regional_domain_name
    origin_id = local.s3_origin_id
    # s3_origin_config {
    #   origin_access_identity = aws_cloudfront_origin_access_identity.taskoai.cloudfront_access_identity_path
    # }
  }


  enabled =true
  is_ipv6_enabled = true
  # comment = "First task with Terraform"
  # default_root_object = "index.php"
 
  default_cache_behavior {
    allowed_methods = ["DELETE","GET","HEAD","OPTIONS","PATCH","POST","PUT"]
    cached_methods = ["GET","HEAD"]
    target_origin_id = local.s3_origin_id
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }



  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate= true
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key =tls_private_key.key-pair.private_key_pem
    host =aws_instance.firstos1.public_ip
  }
}








resource "null_resource" "local1" {
      provisioner "local-exec" {
          command="echo ${aws_instance.firstos1.public_ip}>publicip.txt"
 }
}
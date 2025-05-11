resource "aws_security_group" "jenkins" {
  name        = "Jenkins-SG"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    "Name" = "Jenkins Security Group"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_8080" {
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  security_group_id = aws_security_group.jenkins.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTP traffic on port 8080"
}
resource "aws_vpc_security_group_ingress_rule" "allow_9000" {
  ip_protocol       = "tcp"
  from_port         = 9000
  to_port           = 9000
  security_group_id = aws_security_group.jenkins.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTP traffic on port 9000"
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  security_group_id = aws_security_group.jenkins.id
  cidr_ipv4         = "${chomp(data.http.icanhazip.response_body)}/32"
  description       = "Allow SSH access from my IP"
}
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_ipv4" {
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.jenkins.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow IPv4 all outbound traffic"
}
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_ipv6" {
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.jenkins.id
  cidr_ipv6         = "::/0"
  description       = "Allow IPv6 all outbound traffic"
}
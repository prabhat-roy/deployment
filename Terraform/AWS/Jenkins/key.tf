resource "aws_key_pair" "existing_key" {
  key_name   = var.key_name  # e.g., "jenkins-key"
  public_key = file(var.public_key_path)
}

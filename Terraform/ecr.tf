# Define the microservices
locals {
  microservices = [
    "adservice",
    "cartservice",
    "checkoutservice",
    "currencyservice",
    "emailservice",
    "frontend",
    "loadgenerator",
    "paymentservice",
    "productcatalogservice",
    "recommendationservice",
    "shippingservice"
  ]
}

# Create an ECR repository for each microservice with best practices
resource "aws_ecr_repository" "microservices" {
  for_each = toset(local.microservices)

  name = "microservices-repo-${each.value}"

  image_tag_mutability = "MUTABLE"  # Use mutable tags (you can set to IMMUTABLE if preferred)
  
  image_scanning_configuration {
    scan_on_push = true  # Enable vulnerability scanning on push (recommended for security)
  }

  lifecycle {
    prevent_destroy = false  # Allow deletion of the repository
    ignore_changes = [
      image_tag_mutability,  # Ignore changes to image_tag_mutability (optional)
    ]
  }

  tags = {
    "Environment" = "production"  # Tag the repositories with environment (adjust as needed)
    "Owner"       = "your-team-name"  # Replace with the relevant team or owner
  }
}
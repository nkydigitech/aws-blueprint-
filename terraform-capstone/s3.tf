resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "static" {
  bucket = "${var.my_name}-capstone-static-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_website_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.static]
}

# Upload static website files
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<-EOF
<!DOCTYPE html>
<html>
<head>
    <title>${var.my_name} - Capstone App</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; background: #f5f5f5; }
        h1 { color: #ff9900; }
        .card { background: white; padding: 40px; border-radius: 10px; display: inline-block; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
    </style>
</head>
<body>
    <div class="card">
        <h1>🚀 AWS Capstone Application</h1>
        <p>Built by: <strong>${var.my_name}</strong></p>
        <p>This static site is hosted on Amazon S3</p>
        <p>Backend API: <a href="http://${aws_lb.main.dns_name}">http://${aws_lb.main.dns_name}</a></p>
    </div>
</body>
</html>
EOF
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.static.id
  key          = "error.html"
  content_type = "text/html"
  content      = <<-EOF
<!DOCTYPE html>
<html>
<head><title>Error</title></head>
<body style="text-align:center;margin-top:100px;font-family:Arial;">
    <h1>😕 Oops! Page not found</h1>
    <p>This is a custom error page from S3</p>
</body>
</html>
EOF
}

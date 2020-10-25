# Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.env}-${var.project}-logs"
}

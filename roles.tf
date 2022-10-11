resource "aws_iam_role" "gtd_execution_role" {
  name = "gtdECSTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

// resource "aws_iam_role" "gtd_task_role" {
//   name = "gtdCanAccessDbRole"
// }


resource "aws_iam_policy" "access_db" {
  name = "accessRdsPolicy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "rds-db:*"
        ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy" {
  role = aws_iam_role.gtd_execution_role.id
  policy_arn = aws_iam_policy.access_db.arn
}

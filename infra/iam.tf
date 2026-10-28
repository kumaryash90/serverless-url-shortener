data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "create_lambda_role" {
    name = "url-shortener-create-lambda-role"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "create_lambda_logs" {
    role = aws_iam_role.create_lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "create_lambda_dynamodb" {
    statement {
        actions = ["dynamodb:PutItem"]
        resources = [aws_dynamodb_table.links.arn]
    }
}

resource "aws_iam_role_policy" "create_lambda_dynamodb" {
    name = "put-item-on-links-table"
    role = aws_iam_role.create_lambda_role.id
    policy = data.aws_iam_policy_document.create_lambda_dynamodb.json
}
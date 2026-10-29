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

resource "aws_iam_role" "redirect_lambda_role" {
    name = "url-shortener-redirect-lambda-role"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "redirect_lambda_logs" {
    role = aws_iam_role.redirect_lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "redirect_lambda_permissions" {
    statement {
        actions = ["dynamodb:GetItem"]
        resources = [aws_dynamodb_table.links.arn]
    }
    statement {
        actions = ["sqs:SendMessage"]
        resources = [aws_sqs_queue.clicks.arn]
    }
}

resource "aws_iam_role_policy" "redirect_lambda_permissions" {
    name = "redirect-permissions"
    role = aws_iam_role.redirect_lambda_role.id
    policy = data.aws_iam_policy_document.redirect_lambda_permissions.json
}

resource "aws_iam_role" "click_consumer_role" {
    name = "url-shortener-click-consumer-role"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "click_consumer_logs" {
    role = aws_iam_role.click_consumer_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "click_consumer_permissions" {
    statement {
        actions = ["dynamodb:UpdateItem"]
        resources = [aws_dynamodb_table.links.arn] 
    }
    statement {
        actions = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        resources = [aws_sqs_queue.clicks.arn]
    }
}

resource "aws_iam_role_policy" "click_consumer_permissions" {
    name = "click-consumer-permissions"
    role = aws_iam_role.click_consumer_role.id
    policy = data.aws_iam_policy_document.click_consumer_permissions.json
}

resource "aws_iam_role" "stats_lambda_role" {
    name = "stats-lambda-role"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "stats_lambda_logs" {
    role = aws_iam_role.stats_lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "stats_lambda_permissions" {
    statement {
        actions = ["dynamodb:GetItem"]
        resources = [aws_dynamodb_table.links.arn]
    }
}

resource "aws_iam_role_policy" "stats_lambda_permissions" {
    name = "stats-lambda-permissions"
    role = aws_iam_role.stats_lambda_role.id
    policy = data.aws_iam_policy_document.stats_lambda_permissions.json
}
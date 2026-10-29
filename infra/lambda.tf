data "archive_file" "create" {
    type = "zip"
    source_dir = "${path.module}/../src/create"
    output_path = "${path.module}/builds/create.zip"
}

resource "aws_lambda_function" "create" {
    function_name = "url-shortener-create"
    filename = data.archive_file.create.output_path
    source_code_hash = data.archive_file.create.output_base64sha256
    role = aws_iam_role.create_lambda_role.arn
    handler = "index.handler"
    runtime = "nodejs20.x"

    environment {
        variables = {
            TABLE_NAME = aws_dynamodb_table.links.name
        }
    }
}

data "archive_file" "redirect" {
    type = "zip"
    source_dir = "${path.module}/../src/redirect"
    output_path = "${path.module}/builds/redirect.zip"
}

resource "aws_lambda_function" "redirect" {
    function_name = "url-shortener-redirect"
    filename = data.archive_file.redirect.output_path
    source_code_hash = data.archive_file.redirect.output_base64sha256
    role = aws_iam_role.redirect_lambda_role.arn
    handler = "index.handler"
    runtime = "nodejs20.x"

    environment {
        variables = {
            TABLE_NAME = aws_dynamodb_table.links.name
            QUEUE_URL = aws_sqs_queue.clicks.url
        }
    }
}

data "archive_file" "click_consumer" {
    type = "zip"
    source_dir = "${path.module}/../src/click-consumer"
    output_path = "${path.module}/builds/click-consumer.zip"
}

resource "aws_lambda_function" "click_consumer" {
    function_name = "url-shortener-click-consumer"
    filename = data.archive_file.click_consumer.output_path
    source_code_hash = data.archive_file.click_consumer.output_base64sha256
    role = aws_iam_role.click_consumer_role.arn
    handler = "index.handler"
    runtime = "nodejs20.x"

    environment {
        variables = {
            TABLE_NAME = aws_dynamodb_table.links.name
        }
    }
}
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
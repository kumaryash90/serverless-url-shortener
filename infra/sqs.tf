resource "aws_sqs_queue" "clicks" {
    name = "url-shortener-clicks"
}

resource "aws_lambda_event_source_mapping" "click_consumer" {
    event_source_arn = aws_sqs_queue.clicks.arn
    function_name = aws_lambda_function.click_consumer.arn
    batch_size = 10
    function_response_types = ["ReportBatchItemFailures"]
}
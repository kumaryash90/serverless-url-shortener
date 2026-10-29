import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const sqsClient = new SQSClient({});

export async function handler(event, context) {
  const slug = event.pathParameters.slug;
  const now = Math.floor(Date.now() / 1000);

  try {
    const { Item: item } = await docClient.send(
      new GetCommand({
        TableName: process.env.TABLE_NAME,
        Key: { slug },
      }),
    );

    if (!item) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: "not found" }),
      };
    }

    if (now > item.expires_at) {
      return {
        statusCode: 410,
        body: JSON.stringify({ error: "expired" }),
      };
    }

    try {
      await sqsClient.send(
        new SendMessageCommand({
          QueueUrl: process.env.QUEUE_URL,
          MessageBody: JSON.stringify({ slug }),
        }),
      );
    } catch (err) {
      // we don't fail the redirect for the click tracking failure, just log the error

      console.error(`failed to emit click event for slug "${slug}": `, err);
    }

    return {
      statusCode: 302,
      headers: { Location: item.original_url },
      body: "",
    };
  } catch (err) {
    console.error(`redirect failed for slug "${slug}":`, err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "internal error" }),
    };
  }
}

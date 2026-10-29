import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export async function handler(event, context) {
  const slug = event.pathParameters.slug;
  const now = Math.floor(Date.now() / 1000);

  const { Item } = await docClient.send(
    new GetCommand({
      TableName: process.env.TABLE_NAME,
      Key: { slug },
    }),
  );

  if (!Item) {
    return {
      statusCode: 404,
      body: JSON.stringify({ error: "not found" }),
    };
  }

  if (now > Item.expires_at) {
    return {
      statusCode: 410,
      body: JSON.stringify({ error: "expired" }),
    };
  }

  return {
    statusCode: 200,
    body: JSON.stringify({
      slug,
      click_count: Item.click_count,
      original_url: Item.original_url,
      expires_at: Item.expires_at,
    }),
  };
}

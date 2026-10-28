import crypto from "crypto";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const DEFAULT_TTL_SECONDS = 30 * 24 * 60 * 60; // 30 days
const MAX_ATTEMPTS = 5;

function generateSlug() {
  return crypto.randomBytes(6).toString("base64url");
}

export async function handler(event, context) {
  const { original_url, ttl_seconds } = JSON.parse(event.body);

  if (!original_url) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "original_url is required" }),
    };
  }

  let parsed;
  try {
    parsed = new URL(original_url);
  } catch {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "original_url not valid" }),
    };
  }

  if (!["http:", "https:"].includes(parsed.protocol)) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "original_url must use http or https" }),
    };
  }

  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const slug = generateSlug();
    const now = Math.floor(Date.now() / 1000);
    const expires_at = now + (ttl_seconds ?? DEFAULT_TTL_SECONDS);

    try {
      await docClient.send(
        new PutCommand({
          TableName: process.env.TABLE_NAME,
          Item: {
            slug,
            original_url,
            created_at: now,
            expires_at,
            click_count: 0,
          },
          ConditionExpression: "attribute_not_exists(slug)",
        }),
      );

      return { statusCode: 201, body: JSON.stringify({ slug, expires_at }) };
    } catch (err) {
      if (err.name !== "ConditionalCheckFailedException") throw err;

      // slug collision. loop again with a new slug.
    }
  }

  return {
    statusCode: 500,
    body: JSON.stringify({ error: "could not generate a unique slug" }),
  };
}

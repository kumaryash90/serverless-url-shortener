import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export async function handler(event, context) {
  const bySlug = {};

  for (const record of event.Records) {
    const { slug } = JSON.parse(record.body);

    if (!bySlug[slug]) bySlug[slug] = { count: 0, messageIds: [] };

    bySlug[slug].count += 1;
    bySlug[slug].messageIds.push(record.messageId);
  }

  const batchItemFailures = [];

  for (const [slug, { count, messageIds }] of Object.entries(bySlug)) {
    try {
      await docClient.send(
        new UpdateCommand({
          TableName: process.env.TABLE_NAME,
          Key: { slug },
          UpdateExpression: "ADD click_count :incr",
          ExpressionAttributeValues: { ":incr": count },
        }),
      );
    } catch (err) {
      console.error(`failed to update click_count for slug "${slug}": `, err);

      for (const id of messageIds)
        batchItemFailures.push({ itemIdentifier: id });
    }
  }

  return { batchItemFailures };
}

# Design Decisions

This project is a URL shortener on AWS (API Gateway + Lambda + DynamoDB + SQS, provisioned with Terraform). The app itself is simple on purpose. The point of this doc is to serve as a guide / walk-through of the AWS-specific mechanisms behind it.

## `slug` as the partition key

Every access pattern this app has is a direct lookup by slug: create one, read one, read its stats. There's no query that needs a sort key or a secondary index. Can be extended later if needed.

## TTL

`expires_at` is the table's native TTL attribute, checked on every read and an expired response is returned if it's past (regardless of whether DynamoDB has gotten around to deleting it yet).

## Collision prevention

Create writes use `ConditionExpression: attribute_not_exists(slug)` — atomically rejecting the write if the slug's already taken (no separate check needed). On failure, we can just retry with a new slug.

## Click tracking isn't on the read path

Incrementing a counter on every redirect would put a write-operation on the hot read path, and concentrate it on one partition key for popular links. Instead, a "click happened" event will be sent to SQS, and a separate Lambda consumes the queue in batches and does the actual increment.

## No cache in front of DynamoDB (for now)

DynamoDB can already handle single-key lookups at scale. A potential issue is hot-partition reads on a viral link. We can solve it with a cache. Skipped for now. Can add DAX first if real hot-key traffic ever showed up.

## REST API (v1), not HTTP API (v2) (for now)

HTTP API (v2) is the better fit here (cheaper, faster, less Terraform). But, for now, we're going with REST API (v1) for the larger learning surface (usage plans, request validation, stage caching, the full `resource`/`method`/`integration`/`deployment`/`stage` wiring). Plan: rebuild the API layer as v2 later, same backend, as a direct comparison.

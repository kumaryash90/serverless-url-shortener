# serverless-url-shortener

This project is a URL shortener on AWS (API Gateway + Lambda + DynamoDB + SQS, provisioned with Terraform). TTL-based link expiry, collision-safe slug generation, and click analytics decoupled off the hot read path via SQS.

The app itself is simple on purpose. The point of this guide is to serve as a walk-through of the AWS-specific mechanisms behind it.

See [`architecture/diagram.md`](architecture/diagram.md) for the request flow, and [`docs/design-decisions.md`](docs/design-decisions.md) for the reasoning behind each of those.

**Status:** WIP

# Architecture

```mermaid
flowchart LR
    Client

    subgraph AWS
        APIGW[API Gateway<br/>REST API]
        Create[Lambda: create]
        Redirect[Lambda: redirect]
        Stats[Lambda: stats]
        Consumer[Lambda: click-consumer]
        DDB[(DynamoDB<br/>links table)]
        Queue[[SQS<br/>click events]]
    end

    Client -- "POST /shorten" --> APIGW --> Create
    Create -- "PutItem\n(conditional on slug)" --> DDB

    Client -- "GET /{slug}" --> APIGW --> Redirect
    Redirect -- "GetItem" --> DDB
    Redirect -- "302 redirect" --> Client
    Redirect -- "click event" --> Queue
    Queue --> Consumer
    Consumer -- "UpdateItem\n(ADD click_count)" --> DDB

    Client -- "GET /{slug}/stats" --> APIGW --> Stats
    Stats -- "GetItem" --> DDB
```

The redirect path and the click-count increment are deliberately separate: the redirect Lambda only reads and responds, the counter update happens asynchronously via the consumer Lambda off the SQS queue. See [`../docs/design-decisions.md`](../docs/design-decisions.md).

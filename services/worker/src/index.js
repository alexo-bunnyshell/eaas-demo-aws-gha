const http = require("http");
const {
  SQSClient,
  ReceiveMessageCommand,
  DeleteMessageCommand,
} = require("@aws-sdk/client-sqs");

const sqs = new SQSClient({ region: process.env.AWS_REGION });
const QUEUE_URL = process.env.SQS_QUEUE_URL;
const HEALTH_PORT = process.env.PORT || 3001;

// Health check endpoint for K8s probes
http
  .createServer((_req, res) => {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", service: "worker" }));
  })
  .listen(HEALTH_PORT, () => {
    console.log(`[Worker] Health check on port ${HEALTH_PORT}`);
  });

async function pollMessages() {
  console.log(`[Worker] Polling SQS: ${QUEUE_URL}`);

  while (true) {
    try {
      const response = await sqs.send(
        new ReceiveMessageCommand({
          QueueUrl: QUEUE_URL,
          MaxNumberOfMessages: 10,
          WaitTimeSeconds: 20,
        })
      );

      if (response.Messages) {
        for (const msg of response.Messages) {
          const body = JSON.parse(msg.Body);
          console.log(
            `[Worker] Received: ${JSON.stringify(body)} at ${new Date().toISOString()}`
          );

          await sqs.send(
            new DeleteMessageCommand({
              QueueUrl: QUEUE_URL,
              ReceiptHandle: msg.ReceiptHandle,
            })
          );
        }
      }
    } catch (err) {
      console.error(`[Worker] Error: ${err.message}`);
      await new Promise((r) => setTimeout(r, 5000));
    }
  }
}

pollMessages();

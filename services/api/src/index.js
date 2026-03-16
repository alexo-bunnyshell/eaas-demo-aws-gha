const express = require("express");
const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");

const app = express();
app.use(express.json());

const sqs = new SQSClient({ region: process.env.AWS_REGION });
const QUEUE_URL = process.env.SQS_QUEUE_URL;
const PORT = process.env.PORT || 3000;

app.get("/health", (_req, res) => {
  res.json({ status: "ok", version: "1.0.0" });
});

app.get("/status", (_req, res) => {
  res.json({
    service: "api",
    sqs_queue: QUEUE_URL,
    region: process.env.AWS_REGION,
    environment: process.env.NODE_ENV,
  });
});

app.post("/messages", async (req, res) => {
  const { body } = req.body;
  if (!body) {
    return res.status(400).json({ error: "body is required" });
  }

  const message = {
    body,
    source: "api",
    timestamp: new Date().toISOString(),
    request: {
      ip: req.ip,
      userAgent: req.get("user-agent"),
      contentType: req.get("content-type"),
      host: req.get("host"),
      method: req.method,
      path: req.originalUrl,
    },
  };

  const command = new SendMessageCommand({
    QueueUrl: QUEUE_URL,
    MessageBody: JSON.stringify(message),
  });

  const result = await sqs.send(command);
  console.log(`[API] Sent message ${result.MessageId}`);
  res.json({ messageId: result.MessageId, message });
});

app.listen(PORT, () => {
  console.log(`[API] Listening on port ${PORT}`);
  console.log(`[API] SQS Queue: ${QUEUE_URL}`);
});

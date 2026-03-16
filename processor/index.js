exports.handler = async (event) => {
  for (const record of event.Records) {
    const body = JSON.parse(record.body);
    console.log(`[Processor] Received: ${JSON.stringify(body)}`);

    const result = {
      ...body,
      processed: true,
      processedAt: new Date().toISOString(),
      environment: process.env.ENVIRONMENT,
    };

    console.log(`[Processor] Result: ${JSON.stringify(result)}`);
  }

  return { statusCode: 200, body: "OK" };
};

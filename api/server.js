const express = require("express");
const { createClient } = require("redis");

const app = express();
const PORT = Number(process.env.PORT || 3000);
const REDIS_URL = process.env.REDIS_URL || "redis://redis:6379";

let redis;
async function connectRedis() {
  redis = createClient({ url: REDIS_URL });
  redis.on("error", (error) => console.error("Redis error:", error.message));
  await redis.connect();
}
app.get("/health", (_req, res) => res.status(200).json({ status: "healthy" }));
app.get("/", async (_req, res) => {
  const payload = {
    message: "Hello from Flashbox API",
    greating: process.env.GREATING || "hello Sthita",
    environment: process.env.APP_ENV || "local",
    timestamp: new Date().toISOString()
  };
  try {
    await redis.lPush("messages", JSON.stringify(payload));
    res.status(200).json(payload);
  } catch (error) {
    console.error("Could not enqueue message:", error.message);
    res.status(503).json({ error: "Queue unavailable" });
  }
});
async function start() {
  await connectRedis();
  app.listen(PORT, "0.0.0.0", () => console.log(`API listening on ${PORT}`));
}
if (require.main === module) start().catch((error) => {
  console.error("API startup failed:", error.message);
  process.exit(1);
});
module.exports = app;

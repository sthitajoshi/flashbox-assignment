const { createClient } = require("redis");
const redis = createClient({ url: process.env.REDIS_URL || "redis://redis:6379" });
redis.on("error", (error) => console.error("Redis error:", error.message));
async function main() {
  await redis.connect();
  console.log("Worker connected; waiting for messages...");
  while (true) {
    const result = await redis.brPop("messages", 0);
    if (result) console.log("Received:", result.element);
  }
}
main().catch((error) => {
  console.error("Worker failed:", error.message);
  process.exit(1);
});

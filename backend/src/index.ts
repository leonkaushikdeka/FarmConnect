import Fastify from "fastify";
import cors from "@fastify/cors";
import jwt from "@fastify/jwt";
import rateLimit from "@fastify/rate-limit";
import { config } from "./config/index.js";
import { prisma } from "./services/prisma.js";
import { authRoutes } from "./routes/auth.js";
import { productRoutes } from "./routes/products.js";
import { farmerRoutes } from "./routes/farmers.js";
import { orderRoutes } from "./routes/orders.js";
import { cartRoutes } from "./routes/cart.js";
import { notificationRoutes } from "./routes/notifications.js";

const app = Fastify({ logger: true });

await app.register(cors, { origin: true, credentials: true });
await app.register(jwt, { secret: config.JWT_SECRET });
await app.register(rateLimit, { max: 100, timeWindow: "1 minute" });

await app.register(authRoutes, { prefix: "/api/auth" });
await app.register(productRoutes, { prefix: "/api/products" });
await app.register(farmerRoutes, { prefix: "/api/farmers" });
await app.register(orderRoutes, { prefix: "/api/orders" });
await app.register(cartRoutes, { prefix: "/api/cart" });
await app.register(notificationRoutes, { prefix: "/api/notifications" });

app.get("/api/health", async () => ({
  status: "ok",
  timestamp: new Date().toISOString(),
}));

try {
  await prisma.$connect();
  app.log.info("DB connected");
  await app.listen({ port: config.PORT, host: "0.0.0.0" });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}

export default app;

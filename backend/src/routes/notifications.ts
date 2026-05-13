import type { FastifyInstance } from "fastify";
import { prisma } from "../services/prisma.js";
import { authenticate } from "../middleware/auth.js";
import { z } from "zod";

// ============================================================
// POST /api/notifications/token
// Register or update a user's FCM device token
// ============================================================
const registerTokenBody = z.object({
  fcmToken: z.string().min(10),
});

export async function notificationRoutes(app: FastifyInstance) {
  app.post(
    "/token",
    { preHandler: [authenticate] },
    async (request, reply) => {
      const body = registerTokenBody.parse(request.body);
      const userId = request.userId;

      try {
        await prisma.user.update({
          where: { id: userId },
          data: { fcmToken: body.fcmToken },
        });

        app.log.info(`FCM token registered for user ${userId}`);
        return reply.status(200).send({ success: true, message: "Token registered" });
      } catch (error) {
        app.log.error({ error, userId }, "Failed to save FCM token");
        return reply.status(500).send({ error: "Failed to save token" });
      }
    }
  );

  // ============================================================
  // DELETE /api/notifications/token
  // Unregister / clear the user's FCM token (e.g., on logout)
  // ============================================================
  app.delete(
    "/token",
    { preHandler: [authenticate] },
    async (request, reply) => {
      const userId = request.userId;

      try {
        await prisma.user.update({
          where: { id: userId },
          data: { fcmToken: null },
        });

        app.log.info(`FCM token cleared for user ${userId}`);
        return reply.status(200).send({ success: true, message: "Token cleared" });
      } catch (error) {
        app.log.error({ error, userId }, "Failed to clear FCM token");
        return reply.status(500).send({ error: "Failed to clear token" });
      }
    }
  );
}
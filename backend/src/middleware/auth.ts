import type { FastifyRequest, FastifyReply } from "fastify";

export interface JwtPayload {
  id: string;
  email: string;
  role: string;
}

declare module "fastify" {
  interface FastifyRequest {
    userId: string;
    userRole: string;
    userEmail: string;
  }
}

export async function authenticate(request: FastifyRequest, reply: FastifyReply) {
  try {
    const decoded = await request.jwtVerify<JwtPayload>();
    request.userId = decoded.id;
    request.userRole = decoded.role;
    request.userEmail = decoded.email;
  } catch {
    reply.status(401).send({ error: "Unauthorized" });
  }
}

export function requireRole(...roles: string[]) {
  return (request: FastifyRequest, reply: FastifyReply) => {
    if (!roles.includes(request.userRole)) {
      reply.status(403).send({ error: "Forbidden" });
    }
  };
}

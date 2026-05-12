import type { FastifyInstance } from "fastify";
import { prisma } from "../services/prisma.js";
import { z } from "zod";
import bcrypt from "bcryptjs";
import type { JwtPayload } from "../middleware/auth.js";

const registerCustomer = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  name: z.string().min(1),
  phone: z.string().optional(),
  location: z.string().optional(),
});

const registerFarmer = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  name: z.string().min(1),
  phone: z.string(),
  farmName: z.string().min(1),
  description: z.string().min(10),
  story: z.string().optional(),
  address: z.string().min(5),
  lat: z.number().optional(),
  lng: z.number().optional(),
  certifications: z.array(z.string()).default([]),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export async function authRoutes(app: FastifyInstance) {
  app.post("/register/customer", async (request, reply) => {
    const body = registerCustomer.parse(request.body);
    const existing = await prisma.user.findUnique({ where: { email: body.email } });
    if (existing) return reply.status(409).send({ error: "Email already registered" });

    const hashed = await bcrypt.hash(body.password, 10);
    const user = await prisma.user.create({
      data: {
        email: body.email,
        password: hashed,
        name: body.name,
        phone: body.phone,
        location: body.location,
        role: "CUSTOMER",
      },
    });

    const token = app.jwt.sign({ id: user.id, email: user.email, role: user.role });
    return {
      token,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    };
  });

  app.post("/register/farmer", async (request, reply) => {
    const body = registerFarmer.parse(request.body);
    const existing = await prisma.user.findUnique({ where: { email: body.email } });
    if (existing) return reply.status(409).send({ error: "Email already registered" });

    const hashed = await bcrypt.hash(body.password, 10);
    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: body.email,
          password: hashed,
          name: body.name,
          phone: body.phone,
          role: "FARMER",
        },
      });
      const farmer = await tx.farmer.create({
        data: {
          userId: user.id,
          farmName: body.farmName,
          description: body.description,
          story: body.story,
          address: body.address,
          phone: body.phone,
          lat: body.lat,
          lng: body.lng,
          certifications: body.certifications,
        },
      });
      return { user, farmer };
    });

    const token = app.jwt.sign({
      id: result.user.id,
      email: result.user.email,
      role: result.user.role,
    });

    return {
      token,
      user: {
        id: result.user.id,
        name: result.user.name,
        email: result.user.email,
        role: result.user.role,
      },
      farmer: result.farmer,
    };
  });

  app.post("/login", async (request, reply) => {
    const body = loginSchema.parse(request.body);
    const user = await prisma.user.findUnique({
      where: { email: body.email },
      include: { farmer: true },
    });
    if (!user) return reply.status(401).send({ error: "Invalid email or password" });

    const valid = await bcrypt.compare(body.password, user.password);
    if (!valid) return reply.status(401).send({ error: "Invalid email or password" });

    const token = app.jwt.sign({ id: user.id, email: user.email, role: user.role });
    return {
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        location: user.location,
        imageUrl: user.imageUrl,
      },
      farmer: user.farmer,
    };
  });

  app.get("/me", async (request, reply) => {
    try {
      const decoded = await request.jwtVerify<JwtPayload>();
      const user = await prisma.user.findUnique({
        where: { id: decoded.id },
        include: { farmer: true },
      });
      if (!user) return reply.status(404).send({ error: "User not found" });
      return {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          phone: user.phone,
          location: user.location,
          imageUrl: user.imageUrl,
        },
        farmer: user.farmer,
      };
    } catch {
      reply.status(401).send({ error: "Unauthorized" });
    }
  });
}

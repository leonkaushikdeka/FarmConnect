// ============================================================
// Notification Service
// ============================================================
// Sends FCM push notifications to customers and farmers.
//
// Setup instructions:
// 1. Ensure firebase-admin is initialized (see firebase.ts)
// 2. Users must have an `fcmToken` stored in the database
// 3. Call sendOrderNotification or sendFarmerNotification from route handlers
// ============================================================

import type { FastifyInstance } from "fastify";
import { prisma } from "./prisma.js";

// Re-import from firebase service (will be null if not initialized)
async function getMessaging() {
  // Dynamic import to avoid crash at module load if Firebase isn't configured
  try {
    const { fcm } = await import("./firebase.js");
    return fcm;
  } catch {
    return null;
  }
}

// ============================================================
// Helper: Look up a user's FCM token from the database
// ============================================================
async function getUserFcmToken(userId: string): Promise<string | null> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { fcmToken: true },
  });
  return user?.fcmToken ?? null;
}

// ============================================================
// Helper: Build a standard FCM message payload
// ============================================================
interface FcmMessagePayload {
  title: string;
  body: string;
  orderNo?: string;
  orderId?: string;
  orderStatus?: string;
  screen?: string;
  [key: string]: string | undefined;
}

function buildFcmMessage(
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
) {
  return {
    token,
    notification: { title, body },
    data: data
      ? Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        )
      : undefined,
  };
}

// ============================================================
// PUBLIC: Send notification to a customer about their order
// ============================================================
// Called when:
//   - An order is placed (status = PENDING)
//   - Order status changes (CONFIRMED, PACKING, OUT_FOR_DELIVERY, DELIVERED)
// ============================================================
export async function sendOrderNotification(
  userId: string,
  orderData: {
    orderNo: string;
    orderId: string;
    status: string;
    totalAmount: number;
  }
): Promise<boolean> {
  const fcm = await getMessaging();
  if (!fcm) {
    console.warn("FCM not available — skipping order notification");
    return false;
  }

  const token = await getUserFcmToken(userId);
  if (!token) {
    console.warn(`No FCM token for user ${userId} — skipping notification`);
    return false;
  }

  const statusLabel = orderData.status.charAt(0) + orderData.status.slice(1).toLowerCase();
  const title = `Order ${statusLabel}`;
  const body =
    orderData.status === "PENDING"
      ? `Your order ${orderData.orderNo} has been placed successfully!`
      : orderData.status === "CONFIRMED"
      ? `Your order ${orderData.orderNo} has been confirmed by the farmer.`
      : orderData.status === "PACKING"
      ? `Your order ${orderData.orderNo} is being packed.`
      : orderData.status === "OUT_FOR_DELIVERY"
      ? `Your order ${orderData.orderNo} is out for delivery!`
      : orderData.status === "DELIVERED"
      ? `Your order ${orderData.orderNo} has been delivered!`
      : `Your order ${orderData.orderNo} status: ${statusLabel}`;

  const message = buildFcmMessage(token, title, body, {
    orderNo: orderData.orderNo,
    orderId: orderData.orderId,
    orderStatus: orderData.status,
    screen: "order_detail",
  });

  try {
    const response = await fcm.send(message);
    console.log(`Order notification sent to user ${userId}: ${response}`);
    return true;
  } catch (error) {
    console.error(`Failed to send order notification to ${userId}:`, error);
    return false;
  }
}

// ============================================================
// PUBLIC: Send notification to a farmer about a new order
// ============================================================
// Called when:
//   - A customer places a new order assigned to this farmer
// ============================================================
export async function sendFarmerNotification(
  farmerId: string,
  orderData: {
    orderNo: string;
    orderId: string;
    customerName: string;
    totalAmount: number;
    itemCount: number;
  }
): Promise<boolean> {
  const fcm = await getMessaging();
  if (!fcm) {
    console.warn("FCM not available — skipping farmer notification");
    return false;
  }

  // Look up the farmer's associated user and their FCM token
  const farmer = await prisma.farmer.findUnique({
    where: { id: farmerId },
    select: {
      user: { select: { id: true, fcmToken: true, name: true } },
    },
  });

  const token = farmer?.user?.fcmToken ?? null;
  if (!token) {
    console.warn(`No FCM token for farmer ${farmerId} — skipping notification`);
    return false;
  }

  const title = "New Order Received";
  const body = `${orderData.customerName} placed an order (${orderData.itemCount} item${
    orderData.itemCount !== 1 ? "s" : ""
  }) — ₹${orderData.totalAmount.toFixed(0)}`;

  const message = buildFcmMessage(token, title, body, {
    orderNo: orderData.orderNo,
    orderId: orderData.orderId,
    orderStatus: "PENDING",
    screen: "order_detail",
  });

  try {
    const response = await fcm.send(message);
    console.log(`Farmer notification sent for order ${orderData.orderNo}: ${response}`);
    return true;
  } catch (error) {
    console.error(`Failed to send farmer notification for order ${orderData.orderNo}:`, error);
    return false;
  }
}

// ============================================================
// PUBLIC: Send a broadcast notification to all users
//        (useful for announcements, promotions)
// ============================================================
export async function sendBroadcastNotification(
  title: string,
  body: string,
  topic?: string
): Promise<boolean> {
  const fcm = await getMessaging();
  if (!fcm) {
    console.warn("FCM not available — skipping broadcast notification");
    return false;
  }

  const message = topic
    ? {
        topic,
        notification: { title, body },
      }
    : {
        notification: { title, body },
      };

  try {
    const response = await fcm.send(message);
    console.log(`Broadcast notification sent: ${response}`);
    return true;
  } catch (error) {
    console.error("Failed to send broadcast notification:", error);
    return false;
  }
}

// ============================================================
// PUBLIC: Hook notifications into the order lifecycle
// Call this after an order is created or its status changes
// ============================================================
export async function notifyOrderPlaced(order: {
  id: string;
  orderNo: string;
  customerId: string;
  farmerId: string;
  customerName: string;
  totalAmount: number;
  itemCount: number;
  status: string;
}): Promise<void> {
  // Notify the farmer about the new order
  await sendFarmerNotification(order.farmerId, {
    orderNo: order.orderNo,
    orderId: order.id,
    customerName: order.customerName,
    totalAmount: order.totalAmount,
    itemCount: order.itemCount,
  });

  // Notify the customer that the order was placed
  await sendOrderNotification(order.customerId, {
    orderNo: order.orderNo,
    orderId: order.id,
    status: order.status,
    totalAmount: order.totalAmount,
  });
}

export async function notifyOrderStatusChanged(order: {
  id: string;
  orderNo: string;
  customerId: string;
  status: string;
  totalAmount: number;
}): Promise<void> {
  // Notify the customer about the status change
  await sendOrderNotification(order.customerId, {
    orderNo: order.orderNo,
    orderId: order.id,
    status: order.status,
    totalAmount: order.totalAmount,
  });
}
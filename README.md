# FarmConnect

> Direct farmer-to-citizen marketplace — fresh produce straight from the farm, no middlemen.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.27-02569B?logo=flutter)](https://flutter.dev)
[![Fastify](https://img.shields.io/badge/Fastify-4.x-000000?logo=fastify)](https://fastify.dev)
[![Prisma](https://img.shields.io/badge/Prisma-5.x-2D3748?logo=prisma)](https://prisma.io)
[![Android](https://img.shields.io/badge/Android-Kotlin-3DDC84?logo=android)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-Swift-000000?logo=apple)](https://developer.apple.com)

---

## Overview

FarmConnect connects urban consumers directly with local farmers. Customers browse fresh produce, learn about the farmer behind each product, and place orders for delivery. Farmers manage their inventory, receive orders, and build a direct customer base — all without intermediaries taking a cut.

**Design:** Organic Biophilic — warm terracotta (#9A3412) primary, fresh green (#059669) accent, Lora headings, Raleway body.

## Features

- **Browse produce** by category, search, or farmer
- **Farmer profiles** with story, certifications, rating, and location
- **Direct ordering** with quantity controls and multiple payment methods
- **Order tracking** with status updates (Pending → Confirmed → Packing → Out for Delivery → Delivered)
- **Farmer accounts** — farmers register, list products, manage orders
- **Customer accounts** — login/register, order history, saved addresses
- **Optimistic UI** — instant feedback, smooth transitions, proper error/loading states
- **Mobile-first** — built with Flutter for Android, iOS, and Web

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile/Web | [Flutter](https://flutter.dev) 3.27, Dart 3.6, [Provider](https://pub.dev/packages/provider) |
| Backend | [Node.js](https://nodejs.org) 22+, [Fastify](https://fastify.dev) 4, [TypeScript](https://www.typescriptlang.org) 5.4 |
| Database | [PostgreSQL](https://postgresql.org) 16, [Prisma](https://prisma.io) 5 ORM |
| Auth | JWT (bcrypt + @fastify/jwt) |
| Fonts | [Google Fonts](https://fonts.google.com) — Lora (headings), Raleway (body) |
| API | REST over HTTP, JSON payloads |

## Project Structure

```
farmconnect/
├── lib/                          Flutter app
│   ├── main.dart                 App entry + AuthGate + MainShell (3-tab nav)
│   ├── services/api_service.dart HTTP client with JWT, error handling
│   ├── providers/
│   │   ├── auth_provider.dart    Login, register (customer + farmer), logout
│   │   ├── cart_provider.dart    Cart items, orders, placeOrder
│   │   └── products_provider.dart Products, farmers, categories from API
│   ├── models/                   Data classes (product, farmer, cart_item, order)
│   ├── screens/
│   │   ├── auth_screen.dart      3-tab auth (Login / Customer Register / Farmer Register)
│   │   ├── home_screen.dart      Search, category chips, farmers carousel, product grid
│   │   ├── product_detail_screen.dart Product info, farmer card, add to cart
│   │   ├── cart_screen.dart      Quantity controls, total, proceed to checkout
│   │   ├── checkout_screen.dart  Delivery form, payment method (COD/UPI/Card), place order
│   │   ├── orders_screen.dart    Order history with status badges
│   │   └── farmer_profile_screen.dart  Farmer bio, certifications, product listing
│   ├── widgets/
│   │   ├── product_card.dart     Grid card with organic/in-season badges
│   │   ├── farmer_card.dart      Horizontal card with rating
│   │   ├── category_chip.dart    Filter chip with animated selection
│   │   └── cart_badge.dart       AppBar cart icon with count
│   └── theme/
│       └── app_theme.dart        Terracotta + green palette, Lora/Raleway, Material 3
├── backend/                      Fastify API server
│   ├── prisma/
│   │   ├── schema.prisma         8 models: User, Farmer, Product, CartItem, Order, OrderItem
│   │   └── seed.ts               4 farmers, 17 products, demo accounts
│   └── src/
│       ├── index.ts              Server entry
│       ├── config/index.ts       Zod-validated env
│       ├── middleware/auth.ts    JWT verify + role guard
│       ├── routes/
│       │   ├── auth.ts           Register (customer/farmer), login, me
│       │   ├── products.ts       CRUD, search, filter by category/farmer
│       │   ├── farmers.ts        List, profile, update, location search
│       │   ├── orders.ts         Place, list, track, update status
│       │   └── cart.ts           Add, update, remove items
│       └── services/prisma.ts    DB client
├── android/                      Android platform (ready to build)
├── ios/                          iOS platform (ready to build)
├── web/                          Web platform (ready to build)
└── test/widget_test.dart         Basic smoke test
```

## Quick Start

### Prerequisites

- Flutter 3.27+ ([install](https://docs.flutter.dev/get-started/install))
- Node.js 22+
- PostgreSQL 16+ (Docker recommended)

### Backend Setup

```bash
cd backend
cp .env.example .env
npm install
npx prisma generate
npx prisma db push
npm run db:seed
npm run dev
```

### Flutter App

```bash
# Install deps
flutter pub get

# Run on Web
flutter run -d chrome

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

### Demo Accounts

| Role | Email | Password |
|---|---|---|
| Customer | `demo@farmconnect.in` | `demo123` |
| Farmer | `ramesh@farmconnect.in` | `demo123` |
| Farmer | `lakshmi@farmconnect.in` | `demo123` |
| Farmer | `gurpreet@farmconnect.in` | `demo123` |
| Farmer | `meena@farmconnect.in` | `demo123` |

## API Overview

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register/customer` | No | Register as customer |
| POST | `/api/auth/register/farmer` | No | Register as farmer |
| POST | `/api/auth/login` | No | Login, returns JWT |
| GET | `/api/auth/me` | JWT | Current user profile |
| GET | `/api/products` | No | List products (filter: category, search, farmerId, organic, inSeason) |
| GET | `/api/products/categories` | No | List unique categories |
| GET | `/api/products/:id` | No | Product detail with farmer info |
| POST | `/api/products` | Farmer | Create product |
| PUT | `/api/products/:id` | Farmer | Update product |
| DELETE | `/api/products/:id` | Farmer | Deactivate product |
| GET | `/api/farmers` | No | List farmers (search, location radius) |
| GET | `/api/farmers/:id` | No | Farmer profile with products |
| PUT | `/api/farmers/profile` | Farmer | Update profile |
| POST | `/api/orders` | JWT | Place order |
| GET | `/api/orders` | JWT | List orders (customer sees own, farmer sees received) |
| GET | `/api/orders/:id` | JWT | Order detail |
| PATCH | `/api/orders/:id/status` | Farmer | Update order status |
| GET/POST/PUT/DELETE | `/api/cart/*` | JWT | Cart CRUD |

## Seed Farmers

| Farmer | Farm | Location | Specialty |
|---|---|---|---|
| Ramesh Patel | Patel Organic Farm | Nashik, Maharashtra | Vegetables, dairy, herbs |
| Lakshmi Devi | Devi Fresh Produce | Kodaikanal, Tamil Nadu | Eggs, spices, exotic produce |
| Gurpreet Singh | Singh Wheat & Grains | Patiala, Punjab | Grains, pulses, cold-pressed oil |
| Meena Kumari | Meena's Mango Grove | Ratnagiri, Maharashtra | Mangoes, coconuts, bananas |

## Architecture

```
Flutter App (Android / iOS / Web)
        │
        │ HTTP / JSON (JWT auth)
        ▼
   Fastify API Server
        │
        ├── Auth (JWT + bcrypt)
        ├── Products CRUD
        ├── Farmers CRUD
        ├── Orders + Status
        └── Cart
        │
        ▼
   PostgreSQL (Prisma ORM)
```

## Verification

```bash
# Backend
cd backend
npm run typecheck       # TypeScript check

# Flutter
cd ..
flutter analyze         # Dart analysis (0 issues)
flutter test            # Widget tests
flutter build web       # Web build
```

## License

MIT

import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
import "dotenv/config";

const prisma = new PrismaClient();

async function main() {
  const hash = await bcrypt.hash("demo123", 10);

  const customer = await prisma.user.upsert({
    where: { email: "demo@farmconnect.in" },
    update: {},
    create: {
      email: "demo@farmconnect.in",
      password: hash,
      name: "Ananya Sharma",
      phone: "+91-9876543210",
      location: "Bangalore, Karnataka",
      role: "CUSTOMER",
    },
  });

  const farmers = [
    {
      email: "ramesh@farmconnect.in",
      name: "Ramesh Patel",
      farmName: "Patel Organic Farm",
      phone: "+91-9876543211",
      address: "Village Bhadgaon, Nashik, Maharashtra 422001",
      lat: 20.0,
      lng: 73.78,
      description: "Third-generation farmer growing organic vegetables using traditional methods. Certified organic since 2018.",
      story: "My grandfather started this farm in 1965 with just 2 acres. Today we've grown to 15 acres of pure organic produce. Every morning at 5 AM, I walk through the fields to check on my vegetables. The soil here is rich and our water comes from natural springs.",
      certifications: ["Organic India", "FSSAI"],
      products: [
        { name: "Fresh Organic Tomatoes", category: "Vegetables", description: "Vine-ripened, pesticide-free tomatoes. Perfect for salads, curries, and ketchup. Harvested fresh every morning.", price: 40, unit: "kg", quantity: 100, emoji: "🍅", inSeason: true },
        { name: "Organic Spinach", category: "Leafy Greens", description: "Rich in iron and vitamins. Washed and ready to cook. Grown in nutrient-rich soil with natural compost.", price: 25, unit: "bundle", quantity: 60, emoji: "🥬", inSeason: true },
        { name: "Green Chillies", category: "Vegetables", description: "Spicy, organically grown chillies. No pesticides. Freshly picked.", price: 20, unit: "250g", quantity: 40, emoji: "🌶️", inSeason: true },
        { name: "Desi Cow Milk", category: "Dairy", description: "Fresh A2 milk from grass-fed Gir cows. No hormones, no antibiotics. Delivered chilled within 2 hours of milking.", price: 60, unit: "litre", quantity: 30, emoji: "🥛", inSeason: true },
        { name: "Organic Coriander", category: "Herbs", description: "Aromatic, freshly cut coriander leaves. Essential for every Indian kitchen.", price: 10, unit: "bundle", quantity: 80, emoji: "🌿", inSeason: true },
      ],
    },
    {
      email: "lakshmi@farmconnect.in",
      name: "Lakshmi Devi",
      farmName: "Devi Fresh Produce",
      phone: "+91-9876543212",
      address: "Kodaikanal Road, Dindigul, Tamil Nadu 624001",
      lat: 10.24,
      lng: 77.48,
      description: "Small-scale farmer specializing in exotic vegetables and fresh herbs. Women-led farm cooperative member.",
      story: "I started farming 8 years ago after losing my husband. Today I manage 5 acres of diverse crops and employ 4 women from my village. We grow everything from exotic lettuce to traditional greens.",
      certifications: ["Organic India"],
      products: [
        { name: "Farm Fresh Eggs", category: "Dairy", description: "Free-range eggs from organically fed hens. Deep orange yolks, rich flavor.", price: 8, unit: "piece", quantity: 300, emoji: "🥚", inSeason: true },
        { name: "Fresh Turmeric Root", category: "Spices", description: "Organic fresh turmeric root. High curcumin content. Great for cooking and wellness.", price: 60, unit: "kg", quantity: 30, emoji: "🫚", inSeason: true },
        { name: "Organic Ginger", category: "Spices", description: "Freshly harvested organic ginger. Aromatic and flavorful.", price: 80, unit: "kg", quantity: 25, emoji: "🫚", inSeason: true },
        { name: "Lemon (Organic)", category: "Fruits", description: "Juicy organic lemons grown in the Kodaikanal hills. No chemicals.", price: 5, unit: "piece", quantity: 200, emoji: "🍋", inSeason: true },
      ],
    },
    {
      email: "gurpreet@farmconnect.in",
      name: "Gurpreet Singh",
      farmName: "Singh Wheat & Grains",
      phone: "+91-9876543213",
      address: "Village Ghudani, Patiala, Punjab 147001",
      lat: 30.34,
      lng: 76.38,
      description: "Chemical-free wheat and grain farmer. Part of the Punjab organic farming collective.",
      story: "Punjab is the breadbasket of India, and I'm proud to contribute to that legacy. I converted my 25-acre farm to organic methods in 2019. It was tough at first, but now my soil is healthier than ever.",
      certifications: ["FSSAI", "India Organic"],
      products: [
        { name: "Organic Brown Rice", category: "Grains", description: "Unpolished, organically farmed brown rice. High in fiber.", price: 80, unit: "kg", quantity: 150, emoji: "🌾", inSeason: true },
        { name: "Organic Wheat Flour", category: "Grains", description: "Stone-ground whole wheat flour. No additives or preservatives.", price: 45, unit: "kg", quantity: 200, emoji: "🌾", inSeason: true },
        { name: "Toor Dal (Arhar)", category: "Pulses", description: "Organic pigeon peas. Directly from farm, sun-dried.", price: 120, unit: "kg", quantity: 60, emoji: "🫘", inSeason: true },
        { name: "Mustard Oil (Cold Pressed)", category: "Oils", description: "Cold-pressed organic mustard oil. Pure and aromatic.", price: 250, unit: "litre", quantity: 40, emoji: "🫒", inSeason: true },
      ],
    },
    {
      email: "meena@farmconnect.in",
      name: "Meena Kumari",
      farmName: "Meena's Mango Grove",
      phone: "+91-9876543214",
      address: "Harnai Beach Road, Ratnagiri, Maharashtra 415612",
      lat: 17.0,
      lng: 73.29,
      description: "Alphonso mango specialist. Family-owned orchard with 200+ trees.",
      story: "My family has been growing Alphonso mangoes for four generations. Our orchard is just 2 km from the Arabian Sea — the saline breeze gives our mangoes their unique flavor.",
      certifications: [],
      products: [
        { name: "Alphonso Mangoes", category: "Fruits", description: "Premium Ratnagiri Alphonso. Naturally ripened on the tree. Sweet and aromatic.", price: 120, unit: "dozen", quantity: 25, emoji: "🥭", inSeason: false },
        { name: "Raw Mango (Kairi)", category: "Fruits", description: "Green, tangy raw mangoes. Perfect for pickles and chutneys.", price: 60, unit: "kg", quantity: 40, emoji: "🥭", inSeason: true },
        { name: "Coconut (Young)", category: "Fruits", description: "Tender young coconuts from the farm. Sweet water inside.", price: 30, unit: "piece", quantity: 50, emoji: "🥥", inSeason: true },
        { name: "Banana (Organic)", category: "Fruits", description: "Organic Robusta bananas. Naturally ripened, no chemicals.", price: 40, unit: "dozen", quantity: 60, emoji: "🍌", inSeason: true },
      ],
    },
  ];

  for (const data of farmers) {
    const user = await prisma.user.upsert({
      where: { email: data.email },
      update: {},
      create: {
        email: data.email,
        password: hash,
        name: data.name,
        phone: data.phone,
        role: "FARMER",
      },
    });

    await prisma.farmer.upsert({
      where: { userId: user.id },
      update: {},
      create: {
        userId: user.id,
        farmName: data.farmName,
        phone: data.phone,
        address: data.address,
        lat: data.lat,
        lng: data.lng,
        description: data.description,
        story: data.story,
        certifications: data.certifications,
        rating: 4.5 + Math.random() * 0.5,
        reviewCount: 50 + Math.floor(Math.random() * 200),
      },
    });

    const farmer = await prisma.farmer.findUnique({ where: { userId: user.id } });

    for (const product of data.products) {
      await prisma.product.create({
        data: {
          farmerId: farmer!.id,
          ...product,
        },
      });
    }
  }

  console.log("Seed complete!");
  console.log("Customer: demo@farmconnect.in / demo123");
  console.log("Farmers:  ramesh@farmconnect.in / demo123");
  console.log("          lakshmi@farmconnect.in / demo123");
  console.log("          gurpreet@farmconnect.in / demo123");
  console.log("          meena@farmconnect.in / demo123");
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());

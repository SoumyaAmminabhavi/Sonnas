import Razorpay from "razorpay";
import { env } from "~/env";

if (!env.RAZORPAY_KEY_ID || !env.RAZORPAY_KEY_SECRET) {
  console.warn("[Razorpay] Environment variables RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET are missing.");
}

export const razorpay =
  env.RAZORPAY_KEY_ID && env.RAZORPAY_KEY_SECRET
    ? new Razorpay({
        key_id: env.RAZORPAY_KEY_ID,
        key_secret: env.RAZORPAY_KEY_SECRET,
      })
    : null;

export async function createPaymentLink(options: {
  orderNumber: string;
  amount: number; // in rupees
  phone: string;
  name: string;
}) {
  if (!razorpay) {
    throw new Error("Razorpay is not configured. Please check your environment variables.");
  }
  try {
    // Razorpay expects amount in paise (Rupees * 100)
    const amountInPaise = Math.round(options.amount * 100);

    const paymentLink = await razorpay.paymentLink.create({
      amount: amountInPaise,
      currency: "INR",
      accept_partial: false,
      reference_id: options.orderNumber,
      description: `Cake Order #${options.orderNumber} from Sonna's Patisserie`,
      customer: {
        name: options.name,
        contact: options.phone.replace(/\D/g, ""), // Ensure clean phone number
      },
      notify: {
        sms: false,
        email: false,
        whatsapp: false, // We handle notification ourselves via our bot
      },
      reminder_enable: true,
      notes: {
        orderNumber: options.orderNumber,
      },
      callback_url: `https://sonnaspatisserie.com/order-confirmed?id=${options.orderNumber}`,
      callback_method: "get",
    });

    return paymentLink;
  } catch (error) {
    console.error("[Razorpay] Error creating payment link:", error);
    throw error;
  }
}

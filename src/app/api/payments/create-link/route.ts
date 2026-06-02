import { NextResponse } from "next/server";
import { createPaymentLink } from "~/server/razorpay";

interface PaymentLinkRequestBody {
  orderNumber?: string;
  amount?: number;
  phone?: string;
  name?: string;
}

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as PaymentLinkRequestBody;
    const { orderNumber, amount, phone, name } = body;

    if (!orderNumber || !amount || !phone || !name) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    const paymentLink = await createPaymentLink({
      orderNumber,
      amount,
      phone,
      name,
    });

    return NextResponse.json({ short_url: paymentLink.short_url });
  } catch (error) {
    const err = error as Error;
    console.error("[API Create Payment Link Error]:", err);
    return NextResponse.json({ error: err.message ?? "Failed to create payment link" }, { status: 500 });
  }
}

import { formatPrice } from "~/lib/format";

export function formatItemTotal(price: number, quantity: number): string {
  if (price === 0) return "Pending Quote";
  return formatPrice(price * quantity);
}

export function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error("DB Timeout")), timeoutMs)
    ),
  ]);
}

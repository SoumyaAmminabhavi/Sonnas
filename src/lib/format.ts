/**
 * Formats a price in paise to a rupee string with currency symbol.
 * Example: 67500 -> "₹675"
 */
export const formatPrice = (paise: number | string): string => {
  const amount = typeof paise === "string" ? parseInt(paise, 10) : paise;
  if (isNaN(amount)) return typeof paise === "string" ? paise : "₹0";
  
  // For Sonna's, we usually show whole numbers if possible, or 2 decimal places if needed.
  // Using en-IN for Indian Rupee comma placement.
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(amount / 100);
};

import { formatPrice } from "~/lib/format";

/**
 * High-performance, safe regex template compiler for WhatsApp dynamic messages.
 * Replaces {{variable_name}} with contextual state data and handles currency/date formatting.
 */
export function compileTemplate(templateStr: string, context: Record<string, any>): string {
  if (!templateStr) return "";
  return templateStr.replace(/\{\{\s*([a-zA-Z0-9_]+)\s*\}\}/g, (match, variableName) => {
    if (variableName in context) {
      const val = context[variableName];
      if (val === null || val === undefined) return "";

      // Auto-format currency types (if number) when the variable denotes price, amount, or total
      if (
        typeof val === "number" &&
        (variableName.toLowerCase().includes("price") ||
          variableName.toLowerCase().includes("amount") ||
          variableName.toLowerCase().includes("total"))
      ) {
        return formatPrice(val);
      }

      // Auto-format Date objects to Indian locale
      if (val instanceof Date) {
        return val.toLocaleDateString("en-IN", {
          day: "numeric",
          month: "short",
          year: "numeric",
        });
      }

      return String(val);
    }
    return ""; // Fallback: replace missing variables with empty string
  });
}

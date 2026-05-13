import { z } from "zod";
import sanitizeHtml from "sanitize-html";

/**
 * Strips all HTML tags and trims whitespace from a string.
 */
export function sanitizeInput(input: string | null | undefined): string {
  if (!input) return "";
  return sanitizeHtml(input, {
    allowedTags: [], // Strip ALL tags
    allowedAttributes: {},
  }).trim();
}

/**
 * Validation schemas for different WhatsApp inputs
 */
export const WhatsAppValidators = {
  // Name validation (2-50 characters)
  name: z
    .string()
    .min(2, "Name must be at least 2 characters")
    .max(50, "Name must be less than 50 characters")
    .transform(sanitizeInput),

  // Address validation (10-255 characters)
  address: z
    .string()
    .min(10, "Please provide a more detailed address (at least 10 characters)")
    .max(255, "Address is too long (max 255 characters)")
    .transform(sanitizeInput),

  // Notes validation (max 500 characters)
  notes: z
    .string()
    .max(500, "Notes must be less than 500 characters")
    .transform(sanitizeInput)
    .optional(),

  // Quantity validation (1-20)
  quantity: z.preprocess(
    (val) => parseInt(val as string, 10),
    z.number().int().min(1, "Quantity must be at least 1").max(20, "Quantity must be 20 or less")
  ),
};

/**
 * Generic helper to validate and sanitize input
 */
export function validateAndSanitize<T extends keyof typeof WhatsAppValidators>(
  key: T,
  input: any
) {
  try {
    const schema = WhatsAppValidators[key];
    const result = schema.parse(input);
    return { success: true as const, data: result };
  } catch (error) {
    if (error instanceof z.ZodError) {
      return { success: false as const, error: error.errors[0]?.message ?? "Invalid input" };
    }
    return { success: false as const, error: "Validation failed" };
  }
}

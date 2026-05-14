import { validateAndSanitize as libValidateAndSanitize } from "~/lib/validators";

export function validateAndSanitize(field: any, value: any) {
  return libValidateAndSanitize(field as any, value);
}

// Add specialized validations here if needed

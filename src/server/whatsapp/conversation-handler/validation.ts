import { validateAndSanitize as libValidateAndSanitize, type ValidatorKey } from "~/lib/validators";

export function validateAndSanitize(field: ValidatorKey, value: unknown) {
  return libValidateAndSanitize(field, value);
}

// Add specialized validations here if needed

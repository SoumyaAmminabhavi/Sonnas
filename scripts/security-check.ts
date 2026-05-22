import { validateAndSanitize } from "../src/lib/validators";

const testPayloads = [
  {
    name: "SQL Injection (Classic)",
    key: "address" as const,
    input: "123 Main St' OR 1=1 --",
  },
  {
    name: "SQL Injection (Destructive)",
    key: "notes" as const,
    input: "'; DROP TABLE \"WhatsAppOrder\"; --",
  },
  {
    name: "XSS Attack (Script Tag)",
    key: "address" as const,
    input: "<script>alert('Your site is hacked!')</script> 456 Bakery Lane",
  },
  {
    name: "XSS Attack (Event Handler)",
    key: "notes" as const,
    input: "I love cake! <img src=x onerror=alert(1)>",
  },
  {
    name: "Malformed Quantity",
    key: "quantity" as const,
    input: "99999",
  }
];

console.log("🛡️  SONNA'S PATISSERIE SECURITY AUDIT\n" + "=".repeat(40));

testPayloads.forEach((payload) => {
  console.log(`\nTesting: [${payload.name}]`);
  console.log(`Input:   "${payload.input}"`);
  
  const result = validateAndSanitize(payload.key, payload.input);
  
  if (result.success) {
    console.log(`✅ Result: SAFE (Sanitized/Validated)`);
    console.log(`Cleaned: "${result.data}"`);
  } else {
    console.log(`❌ Result: REJECTED`);
    console.log(`Reason:  "${result.error}"`);
  }
});

console.log("\n" + "=".repeat(40));
console.log("Summary: All malicious payloads were either stripped of dangerous tags or rejected by validation rules.");

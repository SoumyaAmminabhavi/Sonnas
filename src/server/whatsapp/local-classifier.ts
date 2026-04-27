
import natural from 'natural';

// Define categories
export type MessageCategory = 'ADDRESS' | 'INSTRUCTIONS' | 'CAKE_SELECTION' | 'GREETING' | 'UNKNOWN';

const classifier = new natural.BayesClassifier();

// ─── Training Data ──────────────────────────────────────────────────────────

// GREETINGS
classifier.addDocument('hi hello hey help hi there', 'GREETING');
classifier.addDocument('good morning good evening', 'GREETING');

// ADDRESS PATTERNS
classifier.addDocument('house number building floor apartment society street road area colony', 'ADDRESS');
classifier.addDocument('delivered to my address is near the park behind mall', 'ADDRESS');
classifier.addDocument('123 street lane block phase sector', 'ADDRESS');
classifier.addDocument('H-42 Blue Apartments Green Valley', 'ADDRESS');

// INSTRUCTIONS & WRITINGS
classifier.addDocument('write happy birthday on cake name wish message', 'INSTRUCTIONS');
classifier.addDocument('make it eggless less sugar extra cream no nuts', 'INSTRUCTIONS');
classifier.addDocument('please call on arrival gate code do not ring bell', 'INSTRUCTIONS');
classifier.addDocument('put a candle keep it cold', 'INSTRUCTIONS');

// CAKE SELECTION
classifier.addDocument('i want chocolate truffle cake classic chocolate', 'CAKE_SELECTION');
classifier.addDocument('almond brittle salted caramel hazelnut coffee', 'CAKE_SELECTION');
classifier.addDocument('pina colada pineapple mawa persian butter cake', 'CAKE_SELECTION');
classifier.addDocument('strawberry vanilla chocolate seasonal cakes', 'CAKE_SELECTION');
classifier.addDocument('what is the price of cakes show me menu', 'CAKE_SELECTION');
classifier.addDocument('order a 600g 1kg cake', 'CAKE_SELECTION');

// ─── Training ──────────────────────────────────────────────────────────────

console.log('[Classifier] Training local model...');
classifier.train();
console.log('[Classifier] Training complete.');

// ─── Classification Logic ──────────────────────────────────────────────────

export function classifyMessage(text: string): MessageCategory {
  const result = classifier.classify(text.toLowerCase()) as MessageCategory;
  
  // High-confidence overrides (Regex for addresses)
  const hasAddressKeywords = /(house|building|flat|apt|street|road|near|behind|sector|block)\s+\w+/i.test(text);
  if (hasAddressKeywords && result !== 'ADDRESS') return 'ADDRESS';

  // Writing detection
  if (text.toLowerCase().includes('write') || text.toLowerCase().includes('wish')) return 'INSTRUCTIONS';

  return result || 'UNKNOWN';
}

/**
 * Advanced: Extract potential entities (Simple logic)
 */
export function extractPotentialData(text: string, category: MessageCategory) {
  if (category === 'ADDRESS') {
    return { address: text };
  }
  if (category === 'INSTRUCTIONS') {
    return { notes: text };
  }
  return {};
}

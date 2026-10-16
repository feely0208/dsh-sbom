import pino from 'pino';
import { z } from 'zod';

const log = pino({ level: process.env.LOG_LEVEL || 'info' });

const entrySchema = z.object({
  account: z.string().min(1),
  amount: z.number(),
  currency: z.string().length(3),
});

export function parseEntry(raw) {
  const entry = entrySchema.parse(raw);
  log.info({ account: entry.account }, 'ledger entry accepted');
  return entry;
}

import express from 'express';
import { queryStock } from './db.js';

const app = express();
app.use(express.json());

app.get('/health', (req, res) => res.json({ ok: true }));

app.get('/stock/:sku', async (req, res) => {
  const rows = await queryStock(req.params.sku);
  res.json({ sku: req.params.sku, rows });
});

const port = Number(process.env.PORT || 8080);
app.listen(port, () => console.log(`inventory api listening on ${port}`));

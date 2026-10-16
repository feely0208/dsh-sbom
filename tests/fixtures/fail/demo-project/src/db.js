import pg from 'pg';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://localhost:5432/inventory',
  max: 10,
});

export async function queryStock(sku) {
  const { rows } = await pool.query(
    'select sku, warehouse, qty from stock where sku = $1 order by warehouse',
    [sku],
  );
  return rows;
}

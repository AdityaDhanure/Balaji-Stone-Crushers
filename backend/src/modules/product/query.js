import db from '../../config/db.js';
import { IST_DATE_SQL, IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

export const productQueries = {
  getAll: async () => {
    const result = await db.query(`
      SELECT p.*, 
             pc.name as category_name,
             cr.selling_rate_per_brass as current_rate,
             cr.production_rate_per_brass as current_production_rate
      FROM products p
      LEFT JOIN product_categories pc ON p.category_id = pc.id
      LEFT JOIN LATERAL (
        SELECT selling_rate_per_brass, production_rate_per_brass FROM crushing_rates 
        WHERE product_id = p.id AND (effective_to IS NULL OR effective_to >= ${IST_DATE_SQL})
        ORDER BY effective_from DESC LIMIT 1
      ) cr ON true
      ORDER BY pc.name, p.size_mm DESC NULLS LAST
    `);
    return result.rows;
  },

  getById: async (id) => {
    const result = await db.query(`
      SELECT p.*, 
             pc.name as category_name,
             cr.selling_rate_per_brass as current_rate
      FROM products p
      LEFT JOIN product_categories pc ON p.category_id = pc.id
      LEFT JOIN LATERAL (
        SELECT selling_rate_per_brass, production_rate_per_brass FROM crushing_rates 
        WHERE product_id = p.id AND (effective_to IS NULL OR effective_to >= ${IST_DATE_SQL})
        ORDER BY effective_from DESC LIMIT 1
      ) cr ON true
      WHERE p.id = $1
    `, [id]);
    return result.rows[0];
  },

  getActive: async () => {
    const result = await db.query(`
      SELECT p.*, 
             pc.name as category_name,
             cr.selling_rate_per_brass as current_rate
      FROM products p
      LEFT JOIN product_categories pc ON p.category_id = pc.id
      LEFT JOIN LATERAL (
        SELECT selling_rate_per_brass, production_rate_per_brass FROM crushing_rates 
        WHERE product_id = p.id AND (effective_to IS NULL OR effective_to >= ${IST_DATE_SQL})
        ORDER BY effective_from DESC LIMIT 1
      ) cr ON true
      WHERE p.is_active = true
      ORDER BY pc.name, p.size_mm DESC NULLS LAST
    `);
    return result.rows;
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO products (
        product_code, name, category_id, size_mm, description, is_active
      ) VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [
      data.product_code,
      data.name,
      data.category_id,
      data.size_mm,
      data.description,
      data.is_active !== false
    ]);
    return result.rows[0];
  },

  update: async (id, data) => {
    const result = await db.query(`
      UPDATE products SET
        name = COALESCE($1, name),
        category_id = COALESCE($2, category_id),
        size_mm = COALESCE($3, size_mm),
        description = COALESCE($4, description),
        is_active = $5,
        updated_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $6
      RETURNING *
    `, [
      data.name,
      data.category_id,
      data.size_mm,
      data.description,
      data.is_active,
      id
    ]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM products WHERE id = $1', [id]);
    return { deleted: true };
  },

  getNextProductCode: async () => {
    const result = await db.query(`
      SELECT COALESCE(MAX(CAST(SUBSTRING(product_code FROM '[0-9]+$') AS INTEGER)), 0) + 1 as next_number
      FROM products
      WHERE product_code LIKE 'PRD-%'
    `);
    return `PRD-${String(result.rows[0].next_number).padStart(4, '0')}`;
  }
};

export const categoryQueries = {
  getAll: async () => {
    const result = await db.query(`
      SELECT pc.*, 
             COUNT(p.id) as product_count
      FROM product_categories pc
      LEFT JOIN products p ON p.category_id = pc.id
      GROUP BY pc.id
      ORDER BY pc.name
    `);
    return result.rows;
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO product_categories (name, description)
      VALUES ($1, $2)
      RETURNING *
    `, [data.name, data.description]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM product_categories WHERE id = $1', [id]);
    return { deleted: true };
  }
};

export const rateQueries = {
  getByProductId: async (productId) => {
    const result = await db.query(`
      SELECT * FROM crushing_rates
      WHERE product_id = $1
      ORDER BY effective_from DESC
    `, [productId]);
    return result.rows;
  },

  create: async (data) => {
    if (data.effective_to) {
      await db.query(`
        UPDATE crushing_rates SET effective_to = COALESCE($1::date, ${IST_DATE_SQL})
        WHERE product_id = $2 AND effective_to IS NULL
      `, [data.effective_from || null, data.product_id]);
    }

    const result = await db.query(`
      INSERT INTO crushing_rates (product_id, selling_rate_per_brass, production_rate_per_brass, effective_from, effective_to)
      VALUES ($1, $2, $3, COALESCE($4::date, ${IST_DATE_SQL}), $5)
      RETURNING *
    `, [
      data.product_id,
      data.selling_rate_per_brass,
      data.production_rate_per_brass || 0,
      data.effective_from || null,
      data.effective_to
    ]);
    return result.rows[0];
  },

  update: async (id, data) => {
    const result = await db.query(`
      UPDATE crushing_rates SET
        selling_rate_per_brass = COALESCE($1, selling_rate_per_brass),
        production_rate_per_brass = COALESCE($2, production_rate_per_brass),
        effective_to = COALESCE($3, effective_to)
      WHERE id = $4
      RETURNING *
    `, [data.selling_rate_per_brass, data.production_rate_per_brass, data.effective_to, id]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM crushing_rates WHERE id = $1', [id]);
    return { deleted: true };
  }
};

export const productionQueries = {
  getAll: async (filters = {}) => {
    let query = `
      SELECT dp.*, 
             p.name as product_name,
             p.product_code,
             p.size_mm,
             COALESCE(s.production_rate_per_brass, 0) as rate_per_brass,
             COALESCE(s.production_rate_per_brass, 0) as production_rate_per_brass,
             COALESCE(s.total_value, 0) as total_value
      FROM daily_production dp
      JOIN products p ON dp.product_id = p.id
      LEFT JOIN production_rate_snapshots s ON dp.id = s.production_id
      WHERE 1=1
    `;
    
    const params = [];
    let paramIndex = 1;

    if (filters.startDate) {
      query += ` AND dp.production_date >= $${paramIndex++}`;
      params.push(filters.startDate);
    }
    if (filters.endDate) {
      query += ` AND dp.production_date <= $${paramIndex++}`;
      params.push(filters.endDate);
    }
    if (filters.productId) {
      query += ` AND dp.product_id = $${paramIndex++}`;
      params.push(filters.productId);
    }

    query += ' ORDER BY dp.production_date DESC, dp.created_at DESC';

    const result = await db.query(query, params);
    return result.rows;
  },

  getByDate: async (date) => {
    const result = await db.query(`
      SELECT dp.*, 
             p.name as product_name,
             p.product_code,
             p.size_mm,
             COALESCE(s.production_rate_per_brass, 0) as rate_per_brass,
             COALESCE(s.production_rate_per_brass, 0) as production_rate_per_brass,
             COALESCE(s.total_value, 0) as total_value
      FROM daily_production dp
      JOIN products p ON dp.product_id = p.id
      LEFT JOIN production_rate_snapshots s ON dp.id = s.production_id
      WHERE dp.production_date = $1
      ORDER BY p.name
    `, [date]);
    return result.rows;
  },

  getDailySummary: async (date) => {
    const result = await db.query(`
      SELECT 
        COUNT(*) as entry_count,
        CAST(SUM(quantity_tons) AS DECIMAL(10,2)) as total_tons,
        CAST(SUM(royalty_amount) AS DECIMAL(10,2)) as total_royalty,
        CAST(SUM(transportation_cost) AS DECIMAL(10,2)) as total_transport,
        CAST(SUM(COALESCE(s.total_value, 0)) AS DECIMAL(10,2)) as total_value
      FROM daily_production dp
      LEFT JOIN production_rate_snapshots s ON dp.id = s.production_id
      WHERE dp.production_date = $1
    `, [date]);
    return result.rows[0];
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO daily_production (
        production_date, product_id, quantity_tons, royalty_amount,
        transportation_cost, notes, created_by
      ) VALUES (COALESCE($1::date, ${IST_DATE_SQL}), $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [
      data.production_date || null,
      data.product_id,
      data.quantity_tons || 0,
      data.royalty_amount || 0,
      data.transportation_cost || 0,
      data.notes,
      data.created_by
    ]);

    const production = result.rows[0];

    if (production) {
      let productionRate = data.production_rate_per_brass;
      if (!productionRate) {
        const rateResult = await db.query(`
          SELECT production_rate_per_brass FROM crushing_rates
          WHERE product_id = $1 AND effective_from <= COALESCE($2::date, ${IST_DATE_SQL})
          ORDER BY effective_from DESC LIMIT 1
        `, [data.product_id, data.production_date || null]);
        productionRate = rateResult.rows[0]?.production_rate_per_brass || 0;
      }
      const totalValue = (data.quantity_tons * productionRate) + (data.royalty_amount || 0) + (data.transportation_cost || 0);
      await db.query(`
        INSERT INTO production_rate_snapshots (production_id, production_rate_per_brass, total_value)
        VALUES ($1, $2, $3)
      `, [production.id, productionRate, totalValue]);
    }

    return production;
  },

  updateSnapshot: async (productionId, productionRatePerBrass, totalValue) => {
    await db.query(`
      UPDATE production_rate_snapshots 
      SET production_rate_per_brass = $1, total_value = $2
      WHERE production_id = $3
    `, [productionRatePerBrass, totalValue, productionId]);
  },

  update: async (id, data) => {
    const result = await db.query(`
      UPDATE daily_production SET
        product_id = COALESCE($1, product_id),
        quantity_tons = COALESCE($2, quantity_tons),
        royalty_amount = COALESCE($3, royalty_amount),
        transportation_cost = COALESCE($4, transportation_cost),
        notes = COALESCE($5, notes),
        updated_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $6
      RETURNING *
    `, [
      data.product_id,
      data.quantity_tons,
      data.royalty_amount,
      data.transportation_cost,
      data.notes,
      id
    ]);
    return result.rows[0];
  },

  updateSnapshot: async (productionId, productionRatePerBrass, totalValue) => {
    const existing = await db.query('SELECT id FROM production_rate_snapshots WHERE production_id = $1', [productionId]);
    if (existing.rows.length > 0) {
      await db.query(`
        UPDATE production_rate_snapshots 
        SET production_rate_per_brass = $1, total_value = $2
        WHERE production_id = $3
      `, [productionRatePerBrass, totalValue, productionId]);
    } else {
      await db.query(`
        INSERT INTO production_rate_snapshots (production_id, production_rate_per_brass, total_value)
        VALUES ($1, $2, $3)
      `, [productionId, productionRatePerBrass, totalValue]);
    }
  },

  createRate: async (data) => {
    const result = await db.query(`
      INSERT INTO crushing_rates (product_id, selling_rate_per_brass, production_rate_per_brass, effective_from)
      VALUES ($1, $2, $3, COALESCE($4::date, ${IST_DATE_SQL}))
      RETURNING *
    `, [
      data.product_id,
      data.selling_rate_per_brass,
      data.production_rate_per_brass || 0,
      data.effective_from || null
    ]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM production_rate_snapshots WHERE production_id = $1', [id]);
    await db.query('DELETE FROM daily_production WHERE id = $1', [id]);
    return { deleted: true };
  },

  getMonthlyStats: async (year, month) => {
    const result = await db.query(`
      SELECT 
        EXTRACT(DAY FROM dp.production_date) as day,
        CAST(SUM(dp.quantity_tons) AS DECIMAL(10,2)) as total_tons,
        p.name as product_name
      FROM daily_production dp
      JOIN products p ON dp.product_id = p.id
      WHERE EXTRACT(YEAR FROM dp.production_date) = $1
        AND EXTRACT(MONTH FROM dp.production_date) = $2
      GROUP BY EXTRACT(DAY FROM dp.production_date), p.name
      ORDER BY day, p.name
    `, [year, month]);
    return result.rows;
  },

  getGroupedByDate: async () => {
    const result = await db.query(`
      SELECT 
        dp.production_date,
        COUNT(*) as entry_count,
        CAST(SUM(dp.quantity_tons) AS DECIMAL(10,2)) as total_quantity,
        CAST(SUM(COALESCE(s.total_value, 0)) AS DECIMAL(10,2)) as total_value,
        CAST(SUM(dp.royalty_amount) AS DECIMAL(10,2)) as total_royalty,
        CAST(SUM(dp.transportation_cost) AS DECIMAL(10,2)) as total_transport,
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', dp.id,
            'product_id', dp.product_id,
            'product_name', p.name,
            'product_code', p.product_code,
            'size_mm', p.size_mm,
            'quantity_tons', dp.quantity_tons,
            'rate_per_brass', COALESCE(s.production_rate_per_brass, 0),
            'production_rate_per_brass', COALESCE(s.production_rate_per_brass, 0),
            'total_value', COALESCE(s.total_value, 0),
            'royalty_amount', dp.royalty_amount,
            'transportation_cost', dp.transportation_cost,
            'notes', dp.notes,
            'created_at', dp.created_at
          ) ORDER BY dp.id DESC
        ) as entries
      FROM daily_production dp
      JOIN products p ON dp.product_id = p.id
      LEFT JOIN production_rate_snapshots s ON dp.id = s.production_id
      GROUP BY dp.production_date
      ORDER BY dp.production_date DESC
    `);
    return result.rows;
  }
};

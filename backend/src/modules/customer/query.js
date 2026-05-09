import db from '../../config/db.js';
import { IST_DATE_SQL, IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

export const customerQueries = {
  // Get all customers with calculated wallet balance
  getAll: async () => {
    const result = await db.query(`
      SELECT c.*,
             COALESCE(SUM(CASE WHEN cw.transaction_type = 'credit' THEN cw.amount ELSE -cw.amount END), 0) as current_balance
      FROM customers c
      LEFT JOIN customer_wallets cw ON c.id = cw.customer_id
      GROUP BY c.id
      ORDER BY c.name ASC
    `);
    return result.rows;
  },

  // Get single customer by ID
  getById: async (id) => {
    const result = await db.query(`
      SELECT * FROM customers WHERE id = $1
    `, [id]);
    return result.rows[0];
  },

  // Find customer by code
  getByCode: async (code) => {
    const result = await db.query(`
      SELECT * FROM customers WHERE customer_code = $1
    `, [code]);
    return result.rows[0];
  },

  // Get only active customers
  getActive: async () => {
    const result = await db.query(`
      SELECT * FROM customers WHERE is_active = true ORDER BY name ASC
    `);
    return result.rows;
  },

  // Create new customer
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO customers (
        customer_code, name, customer_type, email, phone, alternate_phone,
        gst_number, pan_number, billing_address, shipping_address,
        city, district, state, pincode, credit_limit, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
      RETURNING *
    `, [
      data.customer_code,
      data.name,
      data.customer_type || 'individual',
      data.email,
      data.phone,
      data.alternate_phone,
      data.gst_number,
      data.pan_number,
      data.billing_address,
      data.shipping_address,
      data.city,
      data.district,
      data.state,
      data.pincode,
      data.credit_limit || 0,
      data.notes
    ]);
    return result.rows[0];
  },

  // Update customer (partial update using COALESCE)
  update: async (id, data) => {
    const result = await db.query(`
      UPDATE customers SET
        name = COALESCE($1, name),
        customer_type = COALESCE($2, customer_type),
        email = COALESCE($3, email),
        phone = COALESCE($4, phone),
        alternate_phone = COALESCE($5, alternate_phone),
        gst_number = COALESCE($6, gst_number),
        pan_number = COALESCE($7, pan_number),
        billing_address = COALESCE($8, billing_address),
        shipping_address = COALESCE($9, shipping_address),
        city = COALESCE($10, city),
        district = COALESCE($11, district),
        state = COALESCE($12, state),
        pincode = COALESCE($13, pincode),
        credit_limit = COALESCE($14, credit_limit),
        is_active = COALESCE($15, is_active),
        notes = COALESCE($16, notes),
        updated_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $17
      RETURNING *
    `, [
      data.name,
      data.customer_type,
      data.email,
      data.phone,
      data.alternate_phone,
      data.gst_number,
      data.pan_number,
      data.billing_address,
      data.shipping_address,
      data.city,
      data.district,
      data.state,
      data.pincode,
      data.credit_limit,
      data.is_active,
      data.notes,
      id
    ]);
    return result.rows[0];
  },

  // Delete customer
  delete: async (id) => {
    await db.query('DELETE FROM customers WHERE id = $1', [id]);
    return { deleted: true };
  },

  // Generate next customer code (format: CUST-001)
  getNextCode: async () => {
    const result = await db.query(`
      SELECT COALESCE(MAX(CAST(SUBSTRING(customer_code FROM '[0-9]+$') AS INTEGER)), 0) + 1 as next_number
      FROM customers
      WHERE customer_code LIKE 'CUST-%'
    `);
    return `CUST-${String(result.rows[0].next_number).padStart(3, '0')}`;
  },

  // Search customers by name, phone, code, or city
  search: async (query) => {
    const result = await db.query(`
      SELECT * FROM customers 
      WHERE is_active = true AND (
        LOWER(name) LIKE LOWER($1) OR 
        phone LIKE $1 OR 
        customer_code LIKE $1 OR 
        city LIKE $1
      )
      ORDER BY name ASC
      LIMIT 20
    `, [`%${query}%`]);
    return result.rows;
  }
};

// Contact person queries
export const contactQueries = {
  // Get contacts for a customer
  getByCustomerId: async (customerId) => {
    const result = await db.query(`
      SELECT * FROM customer_contacts 
      WHERE customer_id = $1 
      ORDER BY is_primary DESC, contact_name ASC
    `, [customerId]);
    return result.rows;
  },

  // Create contact person
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO customer_contacts (
        customer_id, contact_name, designation, phone, email, is_primary
      ) VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [
      data.customer_id,
      data.contact_name,
      data.designation,
      data.phone,
      data.email,
      data.is_primary || false
    ]);
    return result.rows[0];
  },

  // Delete contact
  delete: async (id) => {
    await db.query('DELETE FROM customer_contacts WHERE id = $1', [id]);
    return { deleted: true };
  }
};

// Wallet/ledger queries for tracking customer payments
export const walletQueries = {
  // Get all transactions for a customer
  getByCustomerId: async (customerId) => {
    const result = await db.query(`
      SELECT cw.*, u.username as created_by_name
      FROM customer_wallets cw
      LEFT JOIN users u ON cw.created_by = u.id
      WHERE cw.customer_id = $1
      ORDER BY cw.transaction_date DESC, cw.created_at DESC
    `, [customerId]);
    return result.rows;
  },

  // Get current balance for customer
  getBalance: async (customerId) => {
    const result = await db.query(`
      SELECT 
        COALESCE(SUM(CASE WHEN transaction_type = 'credit' THEN amount ELSE -amount END), 0) as balance
      FROM customer_wallets
      WHERE customer_id = $1
    `, [customerId]);
    return result.rows[0].balance;
  },

  // Create wallet transaction (credit = payment received, debit = amount owed)
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO customer_wallets (
        customer_id, transaction_type, amount, payment_mode,
        reference_number, transaction_date, description, created_by
      ) VALUES ($1, $2, $3, $4, $5, COALESCE($6::date, ${IST_DATE_SQL}), $7, $8)
      RETURNING *
    `, [
      data.customer_id,
      data.transaction_type,
      data.amount,
      data.payment_mode,
      data.reference_number,
      data.transaction_date || null,
      data.description,
      data.created_by
    ]);

    // Update customer's current_balance
    await db.query(`
      UPDATE customers SET current_balance = (
        SELECT COALESCE(SUM(CASE WHEN transaction_type = 'credit' THEN amount ELSE -amount END), 0)
        FROM customer_wallets WHERE customer_id = $1
      )
      WHERE id = $1
    `, [data.customer_id]);

    return result.rows[0];
  },

  // Delete transaction and recalculate balance
  delete: async (id) => {
    const wallet = await db.query('SELECT customer_id FROM customer_wallets WHERE id = $1', [id]);
    const customerId = wallet.rows[0]?.customer_id;
    
    await db.query('DELETE FROM customer_wallets WHERE id = $1', [id]);
    
    if (customerId) {
      await db.query(`
        UPDATE customers SET current_balance = (
          SELECT COALESCE(SUM(CASE WHEN transaction_type = 'credit' THEN amount ELSE -amount END), 0)
          FROM customer_wallets WHERE customer_id = $1
        )
        WHERE id = $1
      `, [customerId]);
    }
    
    return { deleted: true };
  }
};

import db from '../../config/db.js';
import { IST_DATE_SQL, IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

const billingDate = (col) => `(${col})::date`;
const istDate = IST_DATE_SQL;
const istTimestamp = IST_TIMESTAMP_SQL;
const istYear = () => new Date(Date.now() + 330 * 60 * 1000).getUTCFullYear();

export const invoiceQueries = {
  // Get all invoices with optional filters (status, customerId, startDate, endDate)
  getAll: async (filters = {}) => {
    let query = `
      SELECT i.*,
             i.bill_no,
             c.name as customer_name,
             c.phone as customer_phone,
             c.gst_number as customer_gst,
             c.city as customer_city,
             u.username as created_by_name,
             CAST(SUM(ii.quantity * ii.selling_rate_per_unit) AS DECIMAL(12,2)) as calculated_subtotal
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      LEFT JOIN users u ON i.created_by = u.id
      LEFT JOIN invoice_items ii ON i.id = ii.invoice_id
      WHERE 1=1
    `;
    
    const params = [];
    let paramIndex = 1;

    if (filters.status) {
      query += ` AND i.status = $${paramIndex++}`;
      params.push(filters.status);
    }
    if (filters.customerId) {
      query += ` AND i.customer_id = $${paramIndex++}`;
      params.push(filters.customerId);
    }
    if (filters.startDate) {
      query += ` AND ${billingDate('i.invoice_date')} >= $${paramIndex++}::date`;
      params.push(filters.startDate);
    }
    if (filters.endDate) {
      query += ` AND ${billingDate('i.invoice_date')} <= $${paramIndex++}::date`;
      params.push(filters.endDate);
    }

    query += ' GROUP BY i.id, c.name, c.phone, c.gst_number, c.city, u.username ORDER BY i.invoice_date DESC, i.id DESC';

    const result = await db.query(query, params);
    return result.rows;
  },

  // Get single invoice by ID with customer details
  getById: async (id) => {
    const result = await db.query(`
      SELECT i.*, 
             c.name as customer_name,
             c.phone as customer_phone,
             c.gst_number as customer_gst,
             c.billing_address as customer_address,
             c.city as customer_city,
             c.state as customer_state,
             c.pincode as customer_pincode,
             u.username as created_by_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      LEFT JOIN users u ON i.created_by = u.id
      WHERE i.id = $1
    `, [id]);
    return result.rows[0];
  },

  // Find invoice by invoice number
  getByNumber: async (number) => {
    const result = await db.query(`
      SELECT * FROM invoices WHERE invoice_number = $1
    `, [number]);
    return result.rows[0];
  },

  // Create new invoice
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO invoices (
        invoice_number, bill_no, customer_id, invoice_date, due_date,
        subtotal, tax_amount, discount_amount, total_amount,
        status, notes, terms, created_by, created_at, updated_at
      ) VALUES ($1, $2, $3, COALESCE($4::date, ${istDate}), $5::date, $6, $7, $8, $9, $10, $11, $12, $13, ${istTimestamp}, ${istTimestamp})
      RETURNING *
    `, [
      data.invoice_number,
      data.bill_no || null,
      data.customer_id,
      data.invoice_date || null,
      data.due_date,
      data.subtotal || 0,
      data.tax_amount || 0,
      data.discount_amount || 0,
      data.total_amount || 0,
      data.status || 'draft',
      data.notes,
      data.terms,
      data.created_by
    ]);
    return result.rows[0];
  },

  // Update invoice (partial update using COALESCE)
  update: async (id, data) => {
    const result = await db.query(`
      UPDATE invoices SET
        bill_no = COALESCE($1, bill_no),
        customer_id = COALESCE($2, customer_id),
        invoice_date = COALESCE($3::date, invoice_date),
        due_date = COALESCE($4::date, due_date),
        subtotal = COALESCE($5, subtotal),
        tax_amount = COALESCE($6, tax_amount),
        discount_amount = COALESCE($7, discount_amount),
        total_amount = COALESCE($8, total_amount),
        amount_paid = COALESCE($9, amount_paid),
        status = COALESCE($10, status),
        notes = COALESCE($11, notes),
        terms = COALESCE($12, terms),
        updated_at = ${istTimestamp}
      WHERE id = $13
      RETURNING *
    `, [
      data.bill_no,
      data.customer_id,
      data.invoice_date,
      data.due_date,
      data.subtotal,
      data.tax_amount,
      data.discount_amount,
      data.total_amount,
      data.amount_paid,
      data.status,
      data.notes,
      data.terms,
      id
    ]);
    return result.rows[0];
  },

  // Update only invoice status
  updateStatus: async (id, status) => {
    const result = await db.query(`
      UPDATE invoices SET status = $1, updated_at = ${istTimestamp}
      WHERE id = $2 RETURNING *
    `, [status, id]);
    return result.rows[0];
  },

  // Delete invoice by ID
  delete: async (id) => {
    await db.query('DELETE FROM invoices WHERE id = $1', [id]);
    return { deleted: true };
  },

  // Generate next invoice number (format: INV-YYYY-0001)
  getNextNumber: async () => {
    const year = istYear();
    const prefix = `INV-${year}-`;
    const result = await db.query(`
      SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM '${prefix}([0-9]+)$') AS INTEGER)), 0) + 1 as next_number
      FROM invoices
      WHERE invoice_number LIKE $1
    `, [`${prefix}%`]);
    return `${prefix}${String(result.rows[0].next_number).padStart(4, '0')}`;
  },

  // Get billing stats for current month
  getStats: async () => {
    const result = await db.query(`
      SELECT 
        COUNT(*) as total_invoices,
        CAST(SUM(total_amount) AS DECIMAL(12,2)) as total_value,
        CAST(SUM(amount_paid) AS DECIMAL(12,2)) as total_collected,
        CAST(SUM(total_amount - amount_paid) AS DECIMAL(12,2)) as total_pending,
        COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_count,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
        COUNT(CASE WHEN status = 'partial' THEN 1 END) as partial_count
      FROM invoices
      WHERE ${billingDate('invoice_date')} >= DATE_TRUNC('month', ${istDate})::date
        AND ${billingDate('invoice_date')} < (DATE_TRUNC('month', ${istDate}) + INTERVAL '1 month')::date
    `);
    return result.rows[0];
  }
};

export const itemQueries = {
  // Get all items for an invoice
  getByInvoiceId: async (invoiceId) => {
    const result = await db.query(`
      SELECT ii.*, p.name as product_name, p.product_code, p.size_mm
      FROM invoice_items ii
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE ii.invoice_id = $1
      ORDER BY ii.id ASC
    `, [invoiceId]);
    return result.rows;
  },

  // Create invoice item
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO invoice_items (
        invoice_id, product_id, description, quantity, unit, selling_rate_per_unit, amount, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, ${istTimestamp})
      RETURNING *
    `, [
      data.invoice_id,
      data.product_id,
      data.description,
      data.quantity,
      data.unit || 'brass',
      data.selling_rate_per_unit,
      data.amount
    ]);
    return result.rows[0];
  },

  // Batch create multiple items for an invoice — transactional: all items insert or none.
  createBatch: async (invoiceId, items) => {
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      const results = [];
      for (const item of items) {
        const result = await client.query(`
          INSERT INTO invoice_items (
            invoice_id, product_id, description, quantity, unit, selling_rate_per_unit, amount, created_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, ${istTimestamp})
          RETURNING *
        `, [
          invoiceId,
          item.product_id,
          item.description,
          item.quantity,
          item.unit || 'brass',
          item.selling_rate_per_unit,
          item.amount
        ]);
        results.push(result.rows[0]);
      }
      await client.query('COMMIT');
      return results;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  },

  // Update invoice item
  update: async (id, data) => {
    const result = await db.query(`
      UPDATE invoice_items SET
        product_id = COALESCE($1, product_id),
        description = COALESCE($2, description),
        quantity = COALESCE($3, quantity),
        unit = COALESCE($4, unit),
        selling_rate_per_unit = COALESCE($5, selling_rate_per_unit),
        amount = COALESCE($6, amount)
      WHERE id = $7
      RETURNING *
    `, [
      data.product_id,
      data.description,
      data.quantity,
      data.unit,
      data.selling_rate_per_unit,
      data.amount,
      id
    ]);
    return result.rows[0];
  },

  // Delete single item
  delete: async (id) => {
    await db.query('DELETE FROM invoice_items WHERE id = $1', [id]);
    return { deleted: true };
  },

  // Delete all items for an invoice
  deleteByInvoiceId: async (invoiceId) => {
    await db.query('DELETE FROM invoice_items WHERE invoice_id = $1', [invoiceId]);
    return { deleted: true };
  }
};

export const paymentQueries = {
  // Get all payments for an invoice
  getByInvoiceId: async (invoiceId) => {
    const result = await db.query(`
      SELECT ip.*, u.username as created_by_name
      FROM invoice_payments ip
      LEFT JOIN users u ON ip.created_by = u.id
      WHERE ip.invoice_id = $1
      ORDER BY ip.payment_date DESC
    `, [invoiceId]);
    return result.rows;
  },

  // Create payment and auto-update invoice status based on amount paid.
  // Transactional: INSERT payment + recalculate totals + UPDATE invoice must be atomic.
  create: async (data) => {
    const client = await db.connect();
    try {
      await client.query('BEGIN');

      const result = await client.query(`
        INSERT INTO invoice_payments (
          invoice_id, amount, payment_mode, reference_number, payment_date, notes, created_by, created_at
        ) VALUES ($1, $2, $3, $4, COALESCE($5::date, ${istDate}), $6, $7, ${istTimestamp})
        RETURNING *
      `, [
        data.invoice_id,
        data.amount,
        data.payment_mode,
        data.reference_number,
        data.payment_date || null,
        data.notes,
        data.created_by
      ]);

      // Recalculate totals and update invoice status
      const payments = await client.query(`
        SELECT COALESCE(SUM(amount), 0) as total FROM invoice_payments WHERE invoice_id = $1
      `, [data.invoice_id]);

      const invoice = await client.query(`
        SELECT total_amount FROM invoices WHERE id = $1
      `, [data.invoice_id]);

      const totalPaid = parseFloat(payments.rows[0].total);
      const totalAmount = parseFloat(invoice.rows[0].total_amount);

      let status = 'partial';
      if (totalPaid >= totalAmount) status = 'paid';
      else if (totalPaid === 0) status = 'pending';

      await client.query(`
        UPDATE invoices SET amount_paid = $1, status = $2, updated_at = ${istTimestamp}
        WHERE id = $3
      `, [totalPaid, status, data.invoice_id]);

      await client.query('COMMIT');
      return result.rows[0];
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  },

  // Delete payment and recalculate invoice status.
  // Transactional: DELETE payment + recalculate totals + UPDATE invoice must be atomic.
  delete: async (id) => {
    const client = await db.connect();
    try {
      await client.query('BEGIN');

      const payment = await client.query('SELECT invoice_id FROM invoice_payments WHERE id = $1', [id]);
      const invoiceId = payment.rows[0]?.invoice_id;

      await client.query('DELETE FROM invoice_payments WHERE id = $1', [id]);

      if (invoiceId) {
        const payments = await client.query(`
          SELECT COALESCE(SUM(amount), 0) as total FROM invoice_payments WHERE invoice_id = $1
        `, [invoiceId]);

        const invoice = await client.query(`
          SELECT total_amount FROM invoices WHERE id = $1
        `, [invoiceId]);

        const totalPaid = parseFloat(payments.rows[0].total);
        const totalAmount = parseFloat(invoice.rows[0].total_amount);

        let status = 'partial';
        if (totalAmount === 0) status = 'draft';
        else if (totalPaid >= totalAmount) status = 'paid';
        else if (totalPaid === 0) status = 'pending';

        await client.query(`
          UPDATE invoices SET amount_paid = $1, status = $2, updated_at = ${istTimestamp}
          WHERE id = $3
        `, [totalPaid, status, invoiceId]);
      }

      await client.query('COMMIT');
      return { deleted: true };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
};

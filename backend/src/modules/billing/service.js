import { invoiceQueries, itemQueries, paymentQueries } from './query.js';
import { withCache, invalidateBillingCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';

export const invoiceService = {
  // Get all invoices with optional filters and caching
  async getAllInvoices(filters = {}) {
    const cacheKey = `billing:invoices:${JSON.stringify(filters)}`;
    return await withCache.get(cacheKey, async () => await invoiceQueries.getAll(filters));
  },

  // Get single invoice by ID with caching
  async getInvoiceById(id) {
    return await withCache.get(CACHE_KEYS.BILLING_DETAIL(id), async () => await invoiceQueries.getById(id));
  },

  // Create new invoice with items
  async createInvoice(data) {
    if (!data.customer_id) {
      throw new Error('Customer is required');
    }
    if (!data.items || data.items.length === 0) {
      throw new Error('At least one item is required');
    }

    // Always validate/generate invoice number fresh from DB to avoid stale cache issues
    if (!data.invoice_number) {
      data.invoice_number = await invoiceQueries.getNextNumber();
    } else {
      // If caller supplied a number, verify it's not already taken
      const existing = await invoiceQueries.getByNumber(data.invoice_number);
      if (existing) {
        // Auto-increment to next available number
        data.invoice_number = await invoiceQueries.getNextNumber();
      }
    }

    // Calculate invoice totals
    const subtotal = data.items.reduce((sum, item) => sum + (item.amount || 0), 0);
    const taxAmount = data.tax_amount || 0;
    const discountAmount = data.discount_amount || 0;
    const totalAmount = subtotal + taxAmount - discountAmount;

    data.subtotal = subtotal;
    data.total_amount = totalAmount;

    // Create invoice header
    const invoice = await invoiceQueries.create(data);
    
    // Create invoice items
    for (const item of data.items) {
      await itemQueries.create({
        ...item,
        invoice_id: invoice.id
      });
    }

    await invalidateBillingCache();
    return invoice;
  },

  // Update invoice and optionally replace items
  async updateInvoice(id, data) {
    if (data.items) {
      // Delete existing items and add new ones
      await itemQueries.deleteByInvoiceId(id);
      for (const item of data.items) {
        await itemQueries.create({
          ...item,
          invoice_id: id
        });
      }

      // Recalculate totals
      const subtotal = data.items.reduce((sum, item) => sum + (item.amount || 0), 0);
      data.subtotal = subtotal;
      data.total_amount = subtotal + (data.tax_amount || 0) - (data.discount_amount || 0);
    }

    const result = await invoiceQueries.update(id, data);
    await invalidateBillingCache();
    return result;
  },

  // Update invoice status (draft, pending, paid, partial, cancelled)
  async updateInvoiceStatus(id, status) {
    const validStatuses = ['draft', 'pending', 'paid', 'partial', 'cancelled'];
    if (!validStatuses.includes(status)) {
      throw new Error('Invalid status');
    }
    const result = await invoiceQueries.updateStatus(id, status);
    await invalidateBillingCache();
    return result;
  },

  // Delete invoice
  async deleteInvoice(id) {
    const result = await invoiceQueries.delete(id);
    await invalidateBillingCache();
    return result;
  },

  // Get next invoice number — always queries DB directly, never cached
  async getNextInvoiceNumber() {
    return await invoiceQueries.getNextNumber();
  },

  // Get billing stats for current month with caching
  async getInvoiceStats() {
    return await withCache.get(CACHE_KEYS.BILLING_STATS, async () => await invoiceQueries.getStats());
  }
};

export const itemService = {
  // Get all items for invoice with caching
  async getItemsByInvoice(invoiceId) {
    return await withCache.get(`billing:items:${invoiceId}`, async () => await itemQueries.getByInvoiceId(invoiceId));
  },

  // Add item to invoice
  async addItem(data) {
    if (!data.product_id && !data.description) {
      throw new Error('Product or description is required');
    }
    if (!data.quantity || data.quantity <= 0) {
      throw new Error('Valid quantity is required');
    }
    if (!data.selling_rate_per_unit || data.selling_rate_per_unit <= 0) {
      throw new Error('Valid rate is required');
    }
    data.amount = data.quantity * data.selling_rate_per_unit;
    const result = await itemQueries.create(data);
    await invalidateBillingCache();
    return result;
  },

  // Update invoice item
  async updateItem(id, data) {
    if (data.quantity && data.selling_rate_per_unit) {
      data.amount = data.quantity * data.selling_rate_per_unit;
    }
    const result = await itemQueries.update(id, data);
    await invalidateBillingCache();
    return result;
  },

  // Delete invoice item
  async deleteItem(id) {
    const result = await itemQueries.delete(id);
    await invalidateBillingCache();
    return result;
  }
};

export const paymentService = {
  // Get payments for invoice with caching
  async getPaymentsByInvoice(invoiceId) {
    return await withCache.get(`billing:payments:${invoiceId}`, async () => await paymentQueries.getByInvoiceId(invoiceId));
  },

  // Record payment and auto-update invoice status
  async createPayment(data) {
    if (!data.invoice_id) {
      throw new Error('Invoice ID is required');
    }
    if (!data.amount || data.amount <= 0) {
      throw new Error('Valid amount is required');
    }
    const result = await paymentQueries.create(data);
    await invalidateBillingCache();
    return result;
  },

  // Delete payment and recalculate invoice
  async deletePayment(id) {
    const result = await paymentQueries.delete(id);
    await invalidateBillingCache();
    return result;
  }
};
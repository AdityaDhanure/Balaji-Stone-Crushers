import { invoiceService, itemService, paymentService } from './service.js';

export const invoiceController = {
  // Get all invoices with filters from query params
  async getAll(req, res) {
    try {
      const filters = {
        status: req.query.status,
        customerId: req.query.customerId ? parseInt(req.query.customerId) : null,
        startDate: req.query.startDate,
        endDate: req.query.endDate
      };
      const invoices = await invoiceService.getAllInvoices(filters);
      res.json(invoices);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get single invoice by ID with items included
  async getById(req, res) {
    try {
      const invoice = await invoiceService.getInvoiceById(req.params.id);
      if (!invoice) {
        return res.status(404).json({ error: 'Invoice not found' });
      }
      const items = await itemService.getItemsByInvoice(req.params.id);
      res.json({ ...invoice, items });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Create new invoice
  async create(req, res) {
    try {
      const data = { ...req.body, created_by: req.user?.id };
      const invoice = await invoiceService.createInvoice(data);
      res.status(201).json(invoice);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Update invoice
  async update(req, res) {
    try {
      const invoice = await invoiceService.updateInvoice(req.params.id, req.body);
      res.json(invoice);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Update invoice status only
  async updateStatus(req, res) {
    try {
      const invoice = await invoiceService.updateInvoiceStatus(req.params.id, req.body.status);
      res.json(invoice);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete invoice
  async delete(req, res) {
    try {
      await invoiceService.deleteInvoice(req.params.id);
      res.json({ message: 'Invoice deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get next invoice number
  async getNextNumber(req, res) {
    try {
      const number = await invoiceService.getNextInvoiceNumber();
      res.json({ invoice_number: number });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get billing stats for current month
  async getStats(req, res) {
    try {
      const stats = await invoiceService.getInvoiceStats();
      res.json(stats);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const itemController = {
  // Get all items for an invoice
  async getByInvoice(req, res) {
    try {
      const items = await itemService.getItemsByInvoice(req.params.invoiceId);
      res.json(items);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Add item to invoice
  async create(req, res) {
    try {
      const item = await itemService.addItem(req.body);
      res.status(201).json(item);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Update invoice item
  async update(req, res) {
    try {
      const item = await itemService.updateItem(req.params.id, req.body);
      res.json(item);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete invoice item
  async delete(req, res) {
    try {
      await itemService.deleteItem(req.params.id);
      res.json({ message: 'Item deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const paymentController = {
  // Get all payments for an invoice
  async getByInvoice(req, res) {
    try {
      const payments = await paymentService.getPaymentsByInvoice(req.params.invoiceId);
      res.json(payments);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Record payment for invoice
  async create(req, res) {
    try {
      const data = { ...req.body, created_by: req.user?.id };
      const payment = await paymentService.createPayment(data);
      res.status(201).json(payment);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete payment
  async delete(req, res) {
    try {
      await paymentService.deletePayment(req.params.id);
      res.json({ message: 'Payment deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};
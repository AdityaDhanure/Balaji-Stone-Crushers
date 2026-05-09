import { customerService, contactService, walletService } from './service.js';

export const customerController = {
  // Get all customers
  async getAll(req, res) {
    try {
      const customers = await customerService.getAllCustomers();
      res.json(customers);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get single customer by ID
  async getById(req, res) {
    try {
      const customer = await customerService.getCustomerById(req.params.id);
      if (!customer) {
        return res.status(404).json({ error: 'Customer not found' });
      }
      res.json(customer);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get only active customers
  async getActive(req, res) {
    try {
      const customers = await customerService.getActiveCustomers();
      res.json(customers);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Create new customer
  async create(req, res) {
    try {
      const customer = await customerService.createCustomer(req.body);
      res.status(201).json(customer);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Update customer
  async update(req, res) {
    try {
      const customer = await customerService.updateCustomer(req.params.id, req.body);
      res.json(customer);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete customer
  async delete(req, res) {
    try {
      await customerService.deleteCustomer(req.params.id);
      res.json({ message: 'Customer deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get next customer code
  async getNextCode(req, res) {
    try {
      const code = await customerService.getNextCode();
      res.json({ customer_code: code });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Search customers
  async search(req, res) {
    try {
      const customers = await customerService.searchCustomers(req.query.q || '');
      res.json(customers);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const contactController = {
  // Get contacts for customer
  async getByCustomer(req, res) {
    try {
      const contacts = await contactService.getContactsByCustomer(req.params.customerId);
      res.json(contacts);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Create contact person
  async create(req, res) {
    try {
      const contact = await contactService.createContact({
        ...req.body,
        customer_id: req.params.customerId
      });
      res.status(201).json(contact);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete contact
  async delete(req, res) {
    try {
      await contactService.deleteContact(req.params.id);
      res.json({ message: 'Contact deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const walletController = {
  // Get wallet transactions and balance for customer
  async getByCustomer(req, res) {
    try {
      const transactions = await walletService.getTransactionsByCustomer(req.params.customerId);
      const balance = await walletService.getBalance(req.params.customerId);
      res.json({ transactions, balance });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Create wallet transaction
  async create(req, res) {
    try {
      const data = { ...req.body, created_by: req.user?.id };
      const transaction = await walletService.createTransaction(data);
      res.status(201).json(transaction);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete wallet transaction
  async delete(req, res) {
    try {
      await walletService.deleteTransaction(req.params.id);
      res.json({ message: 'Transaction deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};
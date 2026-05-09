import { customerQueries, contactQueries, walletQueries } from './query.js';
import { withCache, invalidateCustomerCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';

export const customerService = {
  // Get all customers with caching
  async getAllCustomers() {
    return await withCache.get(CACHE_KEYS.CUSTOMERS, async () => await customerQueries.getAll());
  },

  // Get single customer by ID with caching
  async getCustomerById(id) {
    return await withCache.get(CACHE_KEYS.CUSTOMER_DETAIL(id), async () => await customerQueries.getById(id));
  },

  // Get only active customers with caching
  async getActiveCustomers() {
    return await withCache.get(CACHE_KEYS.CUSTOMERS_ACTIVE, async () => await customerQueries.getActive());
  },

  // Create new customer with auto-generated code
  async createCustomer(data) {
    if (!data.name) {
      throw new Error('Customer name is required');
    }
    if (!data.customer_code) {
      data.customer_code = await customerQueries.getNextCode();
    }
    const result = await customerQueries.create(data);
    await invalidateCustomerCache();
    return result;
  },

  // Update customer
  async updateCustomer(id, data) {
    const result = await customerQueries.update(id, data);
    await invalidateCustomerCache();
    return result;
  },

  // Delete customer
  async deleteCustomer(id) {
    const result = await customerQueries.delete(id);
    await invalidateCustomerCache();
    return result;
  },

  // Get next customer code with caching
  async getNextCode() {
    return await withCache.get(CACHE_KEYS.CUSTOMER_NEXT_CODE, async () => await customerQueries.getNextCode());
  },

  // Search customers with caching
  async searchCustomers(query) {
    return await withCache.get(CACHE_KEYS.CUSTOMERS_SEARCH(query), async () => await customerQueries.search(query));
  }
};

export const contactService = {
  // Get contacts for customer with caching
  async getContactsByCustomer(customerId) {
    return await withCache.get(CACHE_KEYS.CONTACTS_BY_CUSTOMER(customerId), async () => await contactQueries.getByCustomerId(customerId));
  },

  // Create contact person
  async createContact(data) {
    if (!data.contact_name) {
      throw new Error('Contact name is required');
    }
    const result = await contactQueries.create(data);
    await invalidateCustomerCache();
    return result;
  },

  // Delete contact
  async deleteContact(id) {
    const result = await contactQueries.delete(id);
    await invalidateCustomerCache();
    return result;
  }
};

export const walletService = {
  // Get wallet transactions with caching
  async getTransactionsByCustomer(customerId) {
    return await withCache.get(CACHE_KEYS.WALLET_TRANSACTIONS(customerId), async () => await walletQueries.getByCustomerId(customerId));
  },

  // Get customer balance with caching
  async getBalance(customerId) {
    return await withCache.get(CACHE_KEYS.WALLET_BALANCE(customerId), async () => await walletQueries.getBalance(customerId));
  },

  // Create wallet transaction (credit/debit)
  async createTransaction(data) {
    if (!data.customer_id) {
      throw new Error('Customer ID is required');
    }
    if (!data.amount || data.amount <= 0) {
      throw new Error('Valid amount is required');
    }
    if (!['credit', 'debit'].includes(data.transaction_type)) {
      throw new Error('Transaction type must be credit or debit');
    }
    const result = await walletQueries.create(data);
    await invalidateCustomerCache();
    return result;
  },

  // Delete transaction
  async deleteTransaction(id) {
    const result = await walletQueries.delete(id);
    await invalidateCustomerCache();
    return result;
  }
};
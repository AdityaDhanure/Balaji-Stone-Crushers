import { dieselQueries, consumptionQueries } from './query.js';
import { withCache, invalidateDieselCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';

export const dieselService = {
  // Get all diesel purchases with caching
  async getAllPurchases() {
    return await withCache.get(CACHE_KEYS.DIESEL, async () => await dieselQueries.getAllPurchases());
  },

  // Get single purchase with caching
  async getPurchaseById(id) {
    return await withCache.get(CACHE_KEYS.DIESEL_DETAIL(id), async () => await dieselQueries.getPurchaseById(id));
  },

  // Create diesel purchase
  async createPurchase(data) {
    const result = await dieselQueries.createPurchase(data);
    await invalidateDieselCache();
    return result;
  },

  // Update purchase
  async updatePurchase(id, data) {
    const existing = await dieselQueries.getPurchaseById(id);
    if (!existing) {
      throw new Error('Purchase not found');
    }
    const result = await dieselQueries.updatePurchase(id, data);
    await invalidateDieselCache();
    return result;
  },

  // Delete purchase
  async deletePurchase(id) {
    const existing = await dieselQueries.getPurchaseById(id);
    if (!existing) {
      throw new Error('Purchase not found');
    }
    const result = await dieselQueries.deletePurchase(id);
    await invalidateDieselCache();
    return result;
  },

  // Get stock overview with caching
  async getStockOverview() {
    return await withCache.get(CACHE_KEYS.DIESEL_STOCK, async () =>
      await dieselQueries.getStockOverview()
    );
  }
};

export const consumptionService = {
  // Get all consumption records with caching
  async getAllConsumption() {
    return await withCache.get('diesel:consumption:all', async () => await consumptionQueries.getAll());
  },

  // Get consumption for vehicle with caching
  async getConsumptionByVehicleId(vehicleId) {
    return await withCache.get(`diesel:consumption:vehicle:${vehicleId}`, async () => await consumptionQueries.getByVehicleId(vehicleId));
  },

  // Get consumption in date range with caching
  async getConsumptionByDateRange(startDate, endDate) {
    const cacheKey = `diesel:consumption:range:${startDate}:${endDate}`;
    return await withCache.get(cacheKey, async () => await consumptionQueries.getByDateRange(startDate, endDate));
  },

  // Create consumption record
  async createConsumption(data) {
    if (!data.vehicle_id) {
      throw new Error('Vehicle ID is required');
    }
    const result = await consumptionQueries.create(data);
    await invalidateDieselCache();
    return result;
  },

  // Delete consumption record
  async deleteConsumption(id) {
    const result = await consumptionQueries.delete(id);
    await invalidateDieselCache();
    return result;
  },

  // Update consumption
  async updateConsumption(id, data) {
    const existing = await consumptionQueries.getAll();
    if (!existing.find(c => c.id == id)) {
      throw new Error('Consumption not found');
    }
    const result = await consumptionQueries.update(id, data);
    await invalidateDieselCache();
    return result;
  },

  // Get consumption grouped by date with caching
  async getConsumptionGroupedByDate() {
    return await withCache.get('diesel:consumption:grouped', async () => await consumptionQueries.getGroupedByDate());
  },

  // Get vehicle-wise consumption with caching
  async getVehicleWiseConsumption(startDate, endDate) {
    const cacheKey = `diesel:vehicle-wise:${startDate}:${endDate}`;
    return await withCache.get(cacheKey, async () => await consumptionQueries.getVehicleWiseConsumption(startDate, endDate));
  },

  // Get pump-wise payments with caching
  async getPumpWisePayments() {
    return await withCache.get('diesel:pump-payments', async () => await consumptionQueries.getPumpWisePayments());
  }
};
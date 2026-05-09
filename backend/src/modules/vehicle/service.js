import { vehicleQueries, usageQueries } from './query.js';
import { withCache, invalidateVehicleCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';
import { addDaysToDateString, todayIst } from '../../utils/istDateTime.js';

export const vehicleService = {
  async getAllVehicles() {
    return await vehicleQueries.getAll();
  },

  async getVehicleById(id) {
    const vehicle = await vehicleQueries.getById(id);

    if (!vehicle) {
      throw new Error('Vehicle not found');
    }

    const stats = await usageQueries.getVehicleStats(id);

    return { ...vehicle, stats };
  },

  async createVehicle(data) {
    const result = await vehicleQueries.create(data);
    await invalidateVehicleCache();
    return result;
  },

  async updateVehicle(id, data) {
    const existing = await vehicleQueries.getById(id);
    if (!existing) {
      throw new Error('Vehicle not found');
    }
    const result = await vehicleQueries.update(id, data);
    await invalidateVehicleCache();
    return result;
  },

  async deleteVehicle(id) {
    const existing = await vehicleQueries.getById(id);
    if (!existing) {
      throw new Error('Vehicle not found');
    }
    const result = await vehicleQueries.delete(id);
    await invalidateVehicleCache();
    return result;
  },

  async getVehiclesByType(type) {
    return await withCache.get(CACHE_KEYS.VEHICLES_BY_TYPE(type), async () => await vehicleQueries.getByType(type));
  },

  async updateOdometer(id, reading) {
    const existing = await vehicleQueries.getById(id);
    if (!existing) {
      throw new Error('Vehicle not found');
    }
    const result = await vehicleQueries.updateOdometer(id, reading);
    await invalidateVehicleCache();
    return result;
  },

  async getUpcomingExpiries() {
    return await withCache.get('vehicles:expiries', async () => {
      const vehicles = await vehicleQueries.getAll();
      const today = todayIst();
      const in30Days = addDaysToDateString(today, 30);
      
      return vehicles.filter(v => {
        const expiries = [
          { type: 'Insurance', date: v.insurance_expiry },
          { type: 'PUC', date: v.puc_expiry },
          { type: 'Passing', date: v.passing_expiry },
          { type: 'Road Tax', date: v.road_tax_expiry },
        ];
        
        return expiries.some(e => {
          if (!e.date) return false;
          const expiryDate = String(e.date).split('T')[0];
          return expiryDate >= today && expiryDate <= in30Days;
        });
      });
    });
  }
};

export const usageService = {
  async getUsageByVehicleId(vehicleId) {
    return await withCache.get(`usage:vehicle:${vehicleId}`, async () => await usageQueries.getByVehicleId(vehicleId));
  },

  async getUsageByVehicleIdGroupedByDate(vehicleId) {
    return await withCache.get(`usage:vehicle:${vehicleId}:by-date`, async () => await usageQueries.getByVehicleIdGroupedByDate(vehicleId));
  },

  async getDistinctDatesByVehicleId(vehicleId) {
    return await withCache.get(`usage:vehicle:${vehicleId}:dates`, async () => await usageQueries.getDistinctDatesByVehicleId(vehicleId));
  },

  async getDailyUsage(date) {
    return await withCache.get(`usage:daily:${date}`, async () => await usageQueries.getDailyUsage(date));
  },

  async getUsageByDateRange(vehicleId, startDate, endDate) {
    const cacheKey = `usage:${vehicleId}:${startDate}:${endDate}`;
    return await withCache.get(cacheKey, async () => await usageQueries.getByDateRange(vehicleId, startDate, endDate));
  },

  async createUsage(data) {
    if (!data.vehicle_id) {
      throw new Error('Vehicle ID is required');
    }

    const result = await usageQueries.create(data);

    await invalidateVehicleCache(); // full clear

    return result;
  },

  async updateUsage(id, data) {
    const result = await usageQueries.update(id, data);

    await invalidateVehicleCache(); // full clear

    return result;
  },

  async deleteUsage(id) {
    const result = await usageQueries.delete(id);

    await invalidateVehicleCache(); // full clear

    return result;
  },

  async getVehicleStats(vehicleId) {
    return await withCache.get(`usage:stats:${vehicleId}`, async () => await usageQueries.getVehicleStats(vehicleId));
  }
};

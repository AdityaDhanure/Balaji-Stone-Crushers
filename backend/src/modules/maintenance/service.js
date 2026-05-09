import { equipmentQueries, maintenanceQueries, scheduleQueries, vendorQueries, partsQueries, maintenancePartQueries } from './query.js';
import { withCache, invalidateMaintenanceCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';

export const equipmentService = {
  async getAllEquipment() {
    return await withCache.get('equipment:all', async () => await equipmentQueries.getAll());
  },

  async getEquipmentById(id) {
    return await withCache.get(`equipment:${id}`, async () => await equipmentQueries.getById(id));
  },

  async getActiveEquipment() {
    return await withCache.get('equipment:active', async () => await equipmentQueries.getActive());
  },

  async createEquipment(data) {
    if (!data.name) {
      throw new Error('Equipment name is required');
    }
    if (!data.code) {
      data.code = await equipmentQueries.getNextCode(data.equipment_type || 'equip');
    }
    const result = await equipmentQueries.create(data);
    await invalidateMaintenanceCache();
    return result;
  },

  async updateEquipment(id, data) {
    const result = await equipmentQueries.update(id, data);
    await invalidateMaintenanceCache(id);
    return result;
  },

  async deleteEquipment(id) {
    const result = await equipmentQueries.delete(id);
    await invalidateMaintenanceCache(id);
    return result;
  },

  async getNextCode(type) {
    return await withCache.get(`equipment:next-code:${type}`, async () => await equipmentQueries.getNextCode(type));
  }
};

export const maintenanceService = {
  async getAllMaintenance(filters = {}) {
    const cacheKey = `maintenance:all:${JSON.stringify(filters)}`;
    return await withCache.get(cacheKey, async () => await maintenanceQueries.getAll(filters));
  },

  async getMaintenanceById(id) {
    return await withCache.get(CACHE_KEYS.MAINTENANCE_DETAIL(id), async () => await maintenanceQueries.getById(id));
  },

  async getMaintenanceByEquipment(equipmentId) {
    return await withCache.get(`maintenance:equipment:${equipmentId}`, async () => await maintenanceQueries.getByEquipmentId(equipmentId));
  },

  async getMaintenanceByVehicle(vehicleId) {
    return await withCache.get(`maintenance:vehicle:${vehicleId}`, async () => await maintenanceQueries.getByVehicleId(vehicleId));
  },

  async getMaintenanceDueSoon(days = 7) {
    return await withCache.get(`maintenance:due-soon:${days}`, async () => await maintenanceQueries.getDueSoon(days));
  },

  async createMaintenance(data) {
    if (!data.maintenance_type) {
      throw new Error('Maintenance type is required');
    }
    if (!data.description) {
      throw new Error('Description is required');
    }
    if (!data.equipment_id && !data.vehicle_id) {
      throw new Error('Either equipment or vehicle must be selected');
    }
    const result = await maintenanceQueries.create(data);

    if (data.parts_used && data.parts_used.length > 0) {
      await maintenancePartQueries.addRecordParts(
        result.id,
        data.parts_used
      );
      await maintenancePartQueries.deductPartsStock(data.parts_used);
    }

    await invalidateMaintenanceCache();
    return result;
  },

  async updateMaintenance(id, data) {
    const result = await maintenanceQueries.update(id, data);
    await invalidateMaintenanceCache(id);
    return result;
  },

  async deleteMaintenance(id, recoverParts = false) {
    if (recoverParts) {
      await maintenancePartQueries.restorePartsStock(id);
    }
    const result = await maintenanceQueries.delete(id);
    await invalidateMaintenanceCache(id);
    return result;
  },

  async getRecordParts(recordId) {
    return await maintenancePartQueries.getByRecordId(recordId);
  },

  async getMaintenanceStats() {
    return await withCache.get('maintenance:stats', async () => await maintenanceQueries.getStats());
  }
};

export const scheduleService = {
  async getAllSchedules() {
    return await withCache.get('maintenance:schedules:all', async () => await scheduleQueries.getAll());
  },

  async getDueSchedules() {
    return await withCache.get('maintenance:schedules:due', async () => await scheduleQueries.getDue());
  },

  async createSchedule(data) {
    if (!data.equipment_id) {
      throw new Error('Equipment is required');
    }
    if (!data.schedule_type) {
      throw new Error('Schedule type is required');
    }
    const result = await scheduleQueries.create(data);
    await invalidateMaintenanceCache();
    return result;
  },

  async markScheduleComplete(id) {
    const result = await scheduleQueries.markComplete(id);
    await invalidateMaintenanceCache();
    return result;
  },

  async deleteSchedule(id) {
    const result = await scheduleQueries.delete(id);
    await invalidateMaintenanceCache();
    return result;
  }
};

export const vendorService = {
  async getAllVendors() {
    return await withCache.get('maintenance:vendors:all', async () => await vendorQueries.getAll());
  },

  async getActiveVendors() {
    return await withCache.get('maintenance:vendors:active', async () => await vendorQueries.getActive());
  },

  async getVendorById(id) {
    return await withCache.get(`maintenance:vendors:${id}`, async () => await vendorQueries.getById(id));
  },

  async createVendor(data) {
    if (!data.name) {
      throw new Error('Vendor name is required');
    }
    const result = await vendorQueries.create(data);
    await invalidateMaintenanceCache();
    return result;
  },

  async updateVendor(id, data) {
    const result = await vendorQueries.update(id, data);
    await invalidateMaintenanceCache(id);
    return result;
  },

  async deleteVendor(id) {
    const result = await vendorQueries.delete(id);
    await invalidateMaintenanceCache(id);
    return result;
  }
};

export const partsService = {
  async getAllParts() {
    return await withCache.get('maintenance:parts:all', async () => await partsQueries.getAll());
  },

  async getActiveParts() {
    return await withCache.get('maintenance:parts:active', async () => await partsQueries.getActive());
  },

  async getPartById(id) {
    return await withCache.get(`maintenance:parts:${id}`, async () => await partsQueries.getById(id));
  },

  async createPart(data) {
    if (!data.part_number) {
      throw new Error('Part number is required');
    }
    if (!data.name) {
      throw new Error('Part name is required');
    }
    const result = await partsQueries.create(data);
    await invalidateMaintenanceCache();
    return result;
  },

  async updatePart(id, data) {
    const result = await partsQueries.update(id, data);
    await invalidateMaintenanceCache(id);
    return result;
  },

  async deletePart(id) {
    const result = await partsQueries.delete(id);
    await invalidateMaintenanceCache(id);
    return result;
  },

  async getNextPartNumber() {
    return await partsQueries.getNextPartNumber();
  },

  async getPredefinedParts() {
    return await partsQueries.getPredefinedParts();
  },

  async recordUsage(data) {
    if (!data.maintenance_id || !data.part_id || !data.quantity) {
      throw new Error('Maintenance ID, Part ID and quantity are required');
    }
    const result = await partsQueries.recordUsage(data);
    await invalidateMaintenanceCache();
    return result;
  }
};

import { equipmentService, maintenanceService, scheduleService, vendorService, partsService } from './service.js';
import { maintenancePartQueries } from './query.js';

export const equipmentController = {
  async getAll(req, res) {
    try {
      const equipment = await equipmentService.getAllEquipment();
      res.json(equipment);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getById(req, res) {
    try {
      const equipment = await equipmentService.getEquipmentById(req.params.id);
      if (!equipment) {
        return res.status(404).json({ error: 'Equipment not found' });
      }
      res.json(equipment);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getActive(req, res) {
    try {
      const equipment = await equipmentService.getActiveEquipment();
      res.json(equipment);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async create(req, res) {
    try {
      const equipment = await equipmentService.createEquipment(req.body);
      res.status(201).json(equipment);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async update(req, res) {
    try {
      const equipment = await equipmentService.updateEquipment(req.params.id, req.body);
      res.json(equipment);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async delete(req, res) {
    try {
      await equipmentService.deleteEquipment(req.params.id);
      res.json({ message: 'Equipment deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getNextCode(req, res) {
    try {
      const type = req.query.type || 'equip';
      const code = await equipmentService.getNextCode(type);
      res.json({ code });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const maintenanceController = {
  async getAll(req, res) {
    try {
      const filters = {
        type: req.query.type,
        status: req.query.status,
        equipmentId: req.query.equipmentId ? parseInt(req.query.equipmentId) : null,
        vehicleId: req.query.vehicleId ? parseInt(req.query.vehicleId) : null,
        startDate: req.query.startDate,
        endDate: req.query.endDate
      };
      const records = await maintenanceService.getAllMaintenance(filters);
      res.json(records);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getById(req, res) {
    try {
      const record = await maintenanceService.getMaintenanceById(req.params.id);
      if (!record) {
        return res.status(404).json({ error: 'Record not found' });
      }
      res.json(record);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getByEquipment(req, res) {
    try {
      const records = await maintenanceService.getMaintenanceByEquipment(req.params.equipmentId);
      res.json(records);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getByVehicle(req, res) {
    try {
      const records = await maintenanceService.getMaintenanceByVehicle(req.params.vehicleId);
      res.json(records);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getDueSoon(req, res) {
    try {
      const days = parseInt(req.query.days) || 7;
      const records = await maintenanceService.getMaintenanceDueSoon(days);
      res.json(records);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async create(req, res) {
    try {
      const data = { ...req.body, created_by: req.user?.id };
      const record = await maintenanceService.createMaintenance(data);
      res.status(201).json(record);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async update(req, res) {
    try {
      const record = await maintenanceService.updateMaintenance(req.params.id, req.body);
      res.json(record);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async delete(req, res) {
    try {
      const recoverParts = req.query.recover_parts === 'true';
      await maintenanceService.deleteMaintenance(req.params.id, recoverParts);
      res.json({ message: 'Record deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getRecordParts(req, res) {
    try {
      const parts = await maintenanceService.getRecordParts(req.params.id);
      res.json(parts);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getStats(req, res) {
    try {
      const stats = await maintenanceService.getMaintenanceStats();
      res.json(stats);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const scheduleController = {
  async getAll(req, res) {
    try {
      const schedules = await scheduleService.getAllSchedules();
      res.json(schedules);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getDue(req, res) {
    try {
      const schedules = await scheduleService.getDueSchedules();
      res.json(schedules);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async create(req, res) {
    try {
      const schedule = await scheduleService.createSchedule(req.body);
      res.status(201).json(schedule);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async markComplete(req, res) {
    try {
      const schedule = await scheduleService.markScheduleComplete(req.params.id);
      res.json(schedule);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async delete(req, res) {
    try {
      await scheduleService.deleteSchedule(req.params.id);
      res.json({ message: 'Schedule deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const vendorController = {
  async getAll(req, res) {
    try {
      const vendors = await vendorService.getAllVendors();
      res.json(vendors);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getActive(req, res) {
    try {
      const vendors = await vendorService.getActiveVendors();
      res.json(vendors);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getById(req, res) {
    try {
      const vendor = await vendorService.getVendorById(req.params.id);
      if (!vendor) {
        return res.status(404).json({ error: 'Vendor not found' });
      }
      res.json(vendor);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async create(req, res) {
    try {
      const vendor = await vendorService.createVendor(req.body);
      res.status(201).json(vendor);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async update(req, res) {
    try {
      const vendor = await vendorService.updateVendor(req.params.id, req.body);
      res.json(vendor);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async delete(req, res) {
    try {
      await vendorService.deleteVendor(req.params.id);
      res.json({ message: 'Vendor deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const partsController = {
  async getAll(req, res) {
    try {
      const parts = await partsService.getAllParts();
      res.json(parts);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getActive(req, res) {
    try {
      const parts = await partsService.getActiveParts();
      res.json(parts);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getById(req, res) {
    try {
      const part = await partsService.getPartById(req.params.id);
      if (!part) {
        return res.status(404).json({ error: 'Part not found' });
      }
      res.json(part);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async create(req, res) {
    try {
      const part = await partsService.createPart(req.body);
      res.status(201).json(part);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async update(req, res) {
    try {
      const part = await partsService.updatePart(req.params.id, req.body);
      res.json(part);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  async delete(req, res) {
    try {
      await partsService.deletePart(req.params.id);
      res.json({ message: 'Part deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getNextPartNumber(req, res) {
    try {
      const code = await partsService.getNextPartNumber();
      res.json({ part_number: code });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getPredefinedParts(req, res) {
    try {
      const parts = await partsService.getPredefinedParts();
      res.json(parts);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async recordUsage(req, res) {
    try {
      const record = await partsService.recordUsage(req.body);
      res.status(201).json(record);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
};

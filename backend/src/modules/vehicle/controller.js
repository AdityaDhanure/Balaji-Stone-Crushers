import { vehicleService, usageService } from './service.js';
import { todayIst } from '../../utils/istDateTime.js';

export const vehicleController = {
  async getAllVehicles(req, res, next) {
    try {
      const vehicles = await vehicleService.getAllVehicles();
      res.json({ success: true, data: vehicles });
    } catch (error) {
      next(error);
    }
  },

  async getVehicleById(req, res, next) {
    try {
      const vehicle = await vehicleService.getVehicleById(req.params.id);
      res.json({ success: true, data: vehicle });
    } catch (error) {
      next(error);
    }
  },

  async createVehicle(req, res, next) {
    try {
      const vehicle = await vehicleService.createVehicle({
        ...req.body,
        created_by: req.user.id
      });
      res.status(201).json({
        success: true,
        data: vehicle,
        message: 'Vehicle added successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  async updateVehicle(req, res, next) {
    try {
      const vehicle = await vehicleService.updateVehicle(req.params.id, req.body);
      res.json({
        success: true,
        data: vehicle,
        message: 'Vehicle updated successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  async deleteVehicle(req, res, next) {
    try {
      await vehicleService.deleteVehicle(req.params.id);
      res.json({
        success: true,
        message: 'Vehicle deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  async getVehiclesByType(req, res, next) {
    try {
      const vehicles = await vehicleService.getVehiclesByType(req.query.type);
      res.json({ success: true, data: vehicles });
    } catch (error) {
      next(error);
    }
  },

  async updateOdometer(req, res, next) {
    try {
      const vehicle = await vehicleService.updateOdometer(
        req.params.id,
        req.body.reading
      );
      res.json({
        success: true,
        data: vehicle,
        message: 'Odometer updated successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  async getUpcomingExpiries(req, res, next) {
    try {
      const vehicles = await vehicleService.getUpcomingExpiries();
      res.json({ success: true, data: vehicles });
    } catch (error) {
      next(error);
    }
  }
};

export const usageController = {
  async getUsageByVehicleId(req, res, next) {
    try {
      const usage = await usageService.getUsageByVehicleId(req.params.vehicleId);
      res.json({ success: true, data: usage });
    } catch (error) {
      next(error);
    }
  },

  async getUsageByVehicleIdGroupedByDate(req, res, next) {
    try {
      const usage = await usageService.getUsageByVehicleIdGroupedByDate(req.params.vehicleId);
      res.json({ success: true, data: usage });
    } catch (error) {
      next(error);
    }
  },

  async getDistinctDatesByVehicleId(req, res, next) {
    try {
      const dates = await usageService.getDistinctDatesByVehicleId(req.params.vehicleId);
      res.json({ success: true, data: dates });
    } catch (error) {
      next(error);
    }
  },

  async getDailyUsage(req, res, next) {
    try {
      const date = req.query.date || todayIst();
      const usage = await usageService.getDailyUsage(date);
      res.json({ success: true, data: usage });
    } catch (error) {
      next(error);
    }
  },

  async getUsageByDateRange(req, res, next) {
    try {
      const { vehicleId, startDate, endDate } = req.query;
      const usage = await usageService.getUsageByDateRange(
        vehicleId, startDate, endDate
      );
      res.json({ success: true, data: usage });
    } catch (error) {
      next(error);
    }
  },

  async createUsage(req, res, next) {
    try {
      const usage = await usageService.createUsage({
        ...req.body,
        created_by: req.user.id
      });
      res.status(201).json({
        success: true,
        data: usage,
        message: 'Usage record added successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  async updateUsage(req, res, next) {
    try {
      const usage = await usageService.updateUsage(req.params.id, req.body);
      res.json({
        success: true,
        data: usage,
        message: 'Usage record updated successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  async deleteUsage(req, res, next) {
    try {
      await usageService.deleteUsage(req.params.id);
      res.json({
        success: true,
        message: 'Usage record deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  }
};

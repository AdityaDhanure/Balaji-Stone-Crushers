import { dieselService, consumptionService } from './service.js';

export const dieselController = {
  // Get all diesel purchases
  async getAllPurchases(req, res, next) {
    try {
      const purchases = await dieselService.getAllPurchases();
      res.json({ success: true, data: purchases });
    } catch (error) {
      next(error);
    }
  },

  // Get single purchase by ID
  async getPurchaseById(req, res, next) {
    try {
      const purchase = await dieselService.getPurchaseById(req.params.id);
      res.json({ success: true, data: purchase });
    } catch (error) {
      next(error);
    }
  },

  // Create diesel purchase
  async createPurchase(req, res, next) {
    try {
      const purchase = await dieselService.createPurchase({
        ...req.body,
        created_by: req.user.id
      });
      res.status(201).json({
        success: true,
        data: purchase,
        message: 'Purchase recorded successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Update purchase
  async updatePurchase(req, res, next) {
    try {
      const purchase = await dieselService.updatePurchase(req.params.id, req.body);
      res.json({
        success: true,
        data: purchase,
        message: 'Purchase updated successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Delete purchase
  async deletePurchase(req, res, next) {
    try {
      await dieselService.deletePurchase(req.params.id);
      res.json({
        success: true,
        message: 'Purchase deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Get stock overview
  async getStockOverview(req, res, next) {
    try {
      const overview = await dieselService.getStockOverview();
      res.json({ success: true, data: overview });
    } catch (error) {
      next(error);
    }
  }
};

export const consumptionController = {
  // Get all consumption records
  async getAllConsumption(req, res, next) {
    try {
      const consumption = await consumptionService.getAllConsumption();
      res.json({ success: true, data: consumption });
    } catch (error) {
      next(error);
    }
  },

  // Get consumption for vehicle
  async getConsumptionByVehicleId(req, res, next) {
    try {
      const consumption = await consumptionService.getConsumptionByVehicleId(req.params.vehicleId);
      res.json({ success: true, data: consumption });
    } catch (error) {
      next(error);
    }
  },

  // Get consumption in date range
  async getConsumptionByDateRange(req, res, next) {
    try {
      const { startDate, endDate } = req.query;
      const consumption = await consumptionService.getConsumptionByDateRange(startDate, endDate);
      res.json({ success: true, data: consumption });
    } catch (error) {
      next(error);
    }
  },

  // Create consumption record
  async createConsumption(req, res, next) {
    try {
      const consumption = await consumptionService.createConsumption({
        ...req.body,
        created_by: req.user.id
      });
      res.status(201).json({
        success: true,
        data: consumption,
        message: 'Consumption recorded successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Delete consumption record
  async deleteConsumption(req, res, next) {
    try {
      await consumptionService.deleteConsumption(req.params.id);
      res.json({
        success: true,
        message: 'Consumption record deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Update consumption
  async updateConsumption(req, res, next) {
    try {
      const consumption = await consumptionService.updateConsumption(req.params.id, req.body);
      res.json({
        success: true,
        data: consumption,
        message: 'Consumption updated successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Get consumption grouped by date
  async getConsumptionGroupedByDate(req, res, next) {
    try {
      const consumption = await consumptionService.getConsumptionGroupedByDate();
      res.json({ success: true, data: consumption });
    } catch (error) {
      next(error);
    }
  },

  // Get vehicle-wise consumption
  async getVehicleWiseConsumption(req, res, next) {
    try {
      const { startDate, endDate } = req.query;
      const consumption = await consumptionService.getVehicleWiseConsumption(startDate, endDate);
      res.json({ success: true, data: consumption });
    } catch (error) {
      next(error);
    }
  },

  // Get pump-wise payments
  async getPumpWisePayments(req, res, next) {
    try {
      const payments = await consumptionService.getPumpWisePayments();
      res.json({ success: true, data: payments });
    } catch (error) {
      next(error);
    }
  }
};
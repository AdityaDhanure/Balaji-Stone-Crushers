import { blastService, tripService, expenseService } from './service.js';
import { todayIst } from '../../utils/istDateTime.js';

export const blastController = {
  // Get all blasts
  async getAllBlasts(req, res, next) {
    try {
      const blasts = await blastService.getAllBlasts();
      res.json({
        success: true,
        data: blasts
      });
    } catch (error) {
      next(error);
    }
  },

  // Get single blast by ID
  async getBlastById(req, res, next) {
    try {
      const blast = await blastService.getBlastById(req.params.id);
      res.json({
        success: true,
        data: blast
      });
    } catch (error) {
      next(error);
    }
  },

  // Create new blast
  async createBlast(req, res, next) {
    try {
      const blast = await blastService.createBlast({
        ...req.body,
        created_by: req.user?.id
      }, req.user?.id);
      res.status(201).json({
        success: true,
        data: blast,
        message: 'Blast created successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Update blast
  async updateBlast(req, res, next) {
    try {
      const blast = await blastService.updateBlast(req.params.id, req.body);
      res.json({
        success: true,
        data: blast,
        message: 'Blast updated successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Delete blast
  async deleteBlast(req, res, next) {
    try {
      await blastService.deleteBlast(req.params.id);
      res.json({
        success: true,
        message: 'Blast deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Get next blast number
  async getNextBlastNumber(req, res, next) {
    try {
      const nextNumber = await blastService.getNextBlastNumber();
      res.json({
        success: true,
        data: { next_number: nextNumber }
      });
    } catch (error) {
      next(error);
    }
  },

  // Get currently active blast
  async getActiveBlast(req, res, next) {
    try {
      const blast = await blastService.getActiveBlast();
      // Must send data: null explicitly — undefined is omitted by JSON.stringify,
      // which causes Flutter to misinterpret the response envelope as the blast.
      res.json({
        success: true,
        data: blast ?? null
      });
    } catch (error) {
      next(error);
    }
  },

  // Mark blast as completed
  async completeBlast(req, res, next) {
    try {
      const blast = await blastService.completeBlast(req.params.id);
      res.json({
        success: true,
        data: blast,
        message: 'Blast marked as completed'
      });
    } catch (error) {
      next(error);
    }
  },

  // Reopen completed blast
  async reopenBlast(req, res, next) {
    try {
      const blast = await blastService.reopenBlast(req.params.id);
      res.json({
        success: true,
        data: blast,
        message: 'Blast marked as incomplete'
      });
    } catch (error) {
      next(error);
    }
  }
};

export const tripController = {
  // Get all trips for a blast
  async getTripsByBlastId(req, res, next) {
    try {
      const trips = await tripService.getTripsByBlastId(req.params.blastId);
      res.json({
        success: true,
        data: trips
      });
    } catch (error) {
      next(error);
    }
  },

  // Create new trip
  async createTrip(req, res, next) {
    try {
      const trip = await tripService.createTrip({
        ...req.body,
        created_by: req.user.id
      });
      res.status(201).json({
        success: true,
        data: trip,
        message: 'Trip added successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Delete trip
  async deleteTrip(req, res, next) {
    try {
      await tripService.deleteTrip(req.params.id);
      res.json({
        success: true,
        message: 'Trip deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Update trip
  async updateTrip(req, res, next) {
    try {
      const trip = await tripService.updateTrip(req.params.id, req.body);
      res.json({
        success: true,
        data: trip,
        message: 'Trip updated successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Get trips for a specific date
  async getDailyTrips(req, res, next) {
    try {
      const date = req.query.date || todayIst();
      const trips = await tripService.getDailyTrips(date);
      res.json({
        success: true,
        data: trips
      });
    } catch (error) {
      next(error);
    }
  },

  // Get all vehicle types
  async getVehicleTypes(req, res, next) {
    try {
      const types = await tripService.getVehicleTypes();
      res.json({
        success: true,
        data: types
      });
    } catch (error) {
      next(error);
    }
  },

  // Get vehicles by type
  async getVehiclesByType(req, res, next) {
    try {
      const vehicles = await tripService.getVehiclesByType(req.params.type);
      res.json({
        success: true,
        data: vehicles
      });
    } catch (error) {
      next(error);
    }
  },

  // Get trips grouped by date
  async getTripsByBlastIdGroupedByDate(req, res, next) {
    try {
      const trips = await tripService.getTripsByBlastIdGroupedByDate(req.params.blastId);
      res.json({
        success: true,
        data: trips
      });
    } catch (error) {
      next(error);
    }
  },

  // Get distinct trip dates
  async getDistinctDatesByBlastId(req, res, next) {
    try {
      const dates = await tripService.getDistinctDatesByBlastId(req.params.blastId);
      res.json({
        success: true,
        data: dates
      });
    } catch (error) {
      next(error);
    }
  }
};

export const expenseController = {
  // Get all expenses for a blast
  async getExpensesByBlastId(req, res, next) {
    try {
      const expenses = await expenseService.getExpensesByBlastId(req.params.blastId);
      res.json({
        success: true,
        data: expenses
      });
    } catch (error) {
      next(error);
    }
  },

  // Create new expense
  async createExpense(req, res, next) {
    try {
      const expense = await expenseService.createExpense({
        ...req.body,
        created_by: req.user.id
      });
      res.status(201).json({
        success: true,
        data: expense,
        message: 'Expense added successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Update expense
  async updateExpense(req, res, next) {
    try {
      const expense = await expenseService.updateExpense(req.params.id, req.body);
      res.json({
        success: true,
        data: expense,
        message: 'Expense updated successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Delete expense
  async deleteExpense(req, res, next) {
    try {
      await expenseService.deleteExpense(req.params.id);
      res.json({
        success: true,
        message: 'Expense deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  },

  // Get expenses grouped by date
  async getExpensesByBlastIdGroupedByDate(req, res, next) {
    try {
      const expenses = await expenseService.getExpensesByBlastIdGroupedByDate(req.params.blastId);
      res.json({
        success: true,
        data: expenses
      });
    } catch (error) {
      next(error);
    }
  },

  // Get distinct expense dates
  async getDistinctExpenseDatesByBlastId(req, res, next) {
    try {
      const dates = await expenseService.getDistinctExpenseDatesByBlastId(req.params.blastId);
      res.json({
        success: true,
        data: dates
      });
    } catch (error) {
      next(error);
    }
  }
};

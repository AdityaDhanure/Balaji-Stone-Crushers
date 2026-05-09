import { blastQueries, tripQueries, expenseQueries } from './query.js';
import { withCache, invalidateBlastCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';
import { todayIst } from '../../utils/istDateTime.js';

export const blastService = {
  // Get all blasts with caching
  async getAllBlasts() {
    return await withCache.get(CACHE_KEYS.BLASTS, async () => await blastQueries.getAll());
  },

  // Get single blast with trips and expenses
  async getBlastById(id) {
    return await withCache.get(CACHE_KEYS.BLAST_DETAIL(id), async () => {
      const blast = await blastQueries.getById(id);
      if (!blast) {
        throw new Error('Blast not found');
      }
      
      const trips = await tripQueries.getByBlastId(id);
      const expenses = await expenseQueries.getByBlastId(id);

      // Compute live totals from actual records
      const totalTrips = trips.reduce((sum, t) => sum + parseInt(t.trips_count || 0), 0);
      const totalExpenses = expenses.reduce((sum, e) => sum + parseFloat(e.amount || 0), 0);
      
      return {
        ...blast,
        total_expenses: totalExpenses,   // consistent alias used by frontend
        total_trips: totalTrips,
        trips,
        expenses
      };
    });
  },

  // Create new blast with auto-generated drilling/royalty expenses
  async createBlast(data, userId = null) {
    const nextNumber = await blastQueries.getNextBlastNumber();
    const blast = await blastQueries.create({
      ...data,
      blast_number: data.blast_number || nextNumber
    });

    // Auto-create drilling expense based on feet * rate
    const drillingCost = (parseFloat(data.feet) || 0) * (parseFloat(data.rate) || 0);

    if (drillingCost > 0) {
      await expenseQueries.create({
        blast_id: blast.id,
        expense_type: 'drilling',
        description: `Drilling cost for ${data.feet} feet @ ₹${data.rate}/feet`,
        amount: drillingCost,
        expense_date: data.blast_date || todayIst(),
        created_by: userId
      });
    }

    await invalidateBlastCache();
    return await this.getBlastById(blast.id);
  },

  // Update blast details
  async updateBlast(id, data) {
    const existing = await blastQueries.getById(id);
    if (!existing) {
      throw new Error('Blast not found');
    }
    const result = await blastQueries.update(id, data);
    await invalidateBlastCache(id);
    return result;
  },

  // Delete blast
  async deleteBlast(id) {
    const existing = await blastQueries.getById(id);
    if (!existing) {
      throw new Error('Blast not found');
    }
    const result = await blastQueries.delete(id);
    await invalidateBlastCache(id);
    return result;
  },

  // Get next blast number with caching
  async getNextBlastNumber() {
    return await withCache.get(CACHE_KEYS.NEXT_NUMBER, async () => await blastQueries.getNextBlastNumber());
  },

  // Get currently active blast with caching
  async getActiveBlast() {
    return await withCache.get(CACHE_KEYS.BLAST_ACTIVE, async () => await blastQueries.getActiveBlast());
  },

  // Mark blast as completed and aggregate totals
  async completeBlast(id) {
    const existing = await blastQueries.getById(id);
    if (!existing) {
      throw new Error('Blast not found');
    }
    
    const trips = await tripQueries.getByBlastId(id);
    const expenses = await expenseQueries.getByBlastId(id);
    
    const totalTrips = trips.reduce((sum, t) => sum + parseInt(t.trips_count), 0);
    const totalExpenses = expenses.reduce((sum, e) => sum + parseFloat(e.amount), 0);
    
    const result = await blastQueries.update(id, {
      status: 'completed',
      total_expense: totalExpenses,
      total_trips: totalTrips
    });
    
    await invalidateBlastCache(id);
    return result;
  },

  // Reopen completed blast
  async reopenBlast(id) {
    const existing = await blastQueries.getById(id);
    if (!existing) {
      throw new Error('Blast not found');
    }
    
    const result = await blastQueries.update(id, {
      status: 'active'
    });
    
    await invalidateBlastCache(id);
    return result;
  }
};

export const tripService = {
  // Get trips for blast with caching
  async getTripsByBlastId(blastId) {
    return await withCache.get(CACHE_KEYS.BLAST_TRIPS(blastId), async () => await tripQueries.getByBlastId(blastId));
  },

  // Create trip and update blast totals
  async createTrip(data) {
    if (!data.blast_id) {
      throw new Error('Blast ID is required');
    }
    const trip = await tripQueries.create(data);
    await tripQueries.updateBlastTripTotals(data.blast_id);
    await invalidateBlastCache(data.blast_id);
    return trip;
  },

  // Delete trip
  async deleteTrip(id) {
    const result = await tripQueries.delete(id);
    await invalidateBlastCache();
    return result;
  },

  // Update trip and recalculate totals
  async updateTrip(id, data) {
    const trip = await tripQueries.update(id, data);
    if (trip && data.blast_id) {
      await tripQueries.updateBlastTripTotals(data.blast_id);
    }
    await invalidateBlastCache(data.blast_id);
    return trip;
  },

  // Get all trips for a date with caching
  async getDailyTrips(date) {
    return await withCache.get(`trips:daily:${date}`, async () => await tripQueries.getDailyTrips(date));
  },

  // Get vehicles filtered by type with caching
  async getVehiclesByType(vehicleType) {
    return await withCache.get(CACHE_KEYS.VEHICLES_BY_TYPE(vehicleType), async () => await tripQueries.getVehiclesByType(vehicleType));
  },

  // Get all vehicle types with caching
  async getVehicleTypes() {
    return await withCache.get(CACHE_KEYS.VEHICLE_TYPES, async () => await tripQueries.getVehicleTypes());
  },

  // Get trips grouped by date with caching
  async getTripsByBlastIdGroupedByDate(blastId) {
    return await withCache.get(CACHE_KEYS.BLAST_TRIPS_BY_DATE(blastId), async () => await tripQueries.getByBlastIdGroupedByDate(blastId));
  },

  // Get distinct trip dates with caching
  async getDistinctDatesByBlastId(blastId) {
    return await withCache.get(CACHE_KEYS.BLAST_TRIPS_DATES(blastId), async () => await tripQueries.getDistinctDatesByBlastId(blastId));
  }
};

export const expenseService = {
  // Get expenses for blast with caching
  async getExpensesByBlastId(blastId) {
    return await withCache.get(CACHE_KEYS.BLAST_EXPENSES(blastId), async () => await expenseQueries.getByBlastId(blastId));
  },

  // Create expense and update blast totals
  async createExpense(data) {
    if (!data.blast_id) {
      throw new Error('Blast ID is required');
    }
    const expense = await expenseQueries.create(data);
    await expenseQueries.updateBlastExpenseTotals(data.blast_id);
    await invalidateBlastCache(data.blast_id);
    return expense;
  },

  // Update expense
  async updateExpense(id, data) {
    const existing = await expenseQueries.getById(id);
    const expense = await expenseQueries.update(id, data);
    if (existing) {
      await expenseQueries.updateBlastExpenseTotals(existing.blast_id);
    }
    await invalidateBlastCache(existing?.blast_id);
    return expense;
  },

  // Delete expense
  async deleteExpense(id) {
    const existing = await expenseQueries.getById(id);
    await expenseQueries.delete(id);
    if (existing) {
      await expenseQueries.updateBlastExpenseTotals(existing.blast_id);
    }
    await invalidateBlastCache(existing?.blast_id);
  },

  // Get expenses grouped by date with caching
  async getExpensesByBlastIdGroupedByDate(blastId) {
    return await withCache.get(CACHE_KEYS.BLAST_EXPENSES_BY_DATE(blastId), async () => await expenseQueries.getByBlastIdGroupedByDate(blastId));
  },

  // Get distinct expense dates with caching
  async getDistinctExpenseDatesByBlastId(blastId) {
    return await withCache.get(CACHE_KEYS.BLAST_EXPENSES_DATES(blastId), async () => await expenseQueries.getDistinctDatesByBlastId(blastId));
  }
};

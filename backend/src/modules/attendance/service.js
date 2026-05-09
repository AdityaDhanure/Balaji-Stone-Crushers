import { attendanceQueries, shiftQueries, leaveQueries } from './query.js';
import { withCache, invalidateAttendanceCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';

export const attendanceService = {
  // Get all attendance with optional filters and caching
  async getAllAttendance(filters = {}) {
    const cacheKey = `attendance:all:${filters.date || ''}:${filters.startDate || ''}:${filters.endDate || ''}:${filters.employeeId || ''}`;
    return await withCache.get(cacheKey, async () => await attendanceQueries.getAll(filters));
  },

  // Delete all attendance records for a specific date
  async deleteAllAttendanceByDate(date) {
    return await attendanceQueries.deleteAllByDate(date);
  },

  // Get attendance by employee with caching
  async getAttendanceByEmployee(employeeId, startDate, endDate) {
    const cacheKey = `attendance:employee:${employeeId}:${startDate}:${endDate}`;
    return await withCache.get(cacheKey, async () => await attendanceQueries.getByEmployee(employeeId, startDate, endDate));
  },

  // Get attendance by date with caching
  async getAttendanceByDate(date) {
    return await attendanceQueries.getByDate(date);
  },

  // Mark attendance for employee
  async markAttendance(data) {
    if (!data.employee_id) {
      throw new Error('Employee is required');
    }
    if (!data.date) {
      throw new Error('Date is required');
    }
    const result = await attendanceQueries.create(data);
    await invalidateAttendanceCache(data.date);
    return result;
  },

  // Bulk mark attendance for multiple employees
  async bulkMarkAttendance(records) {
    if (!records || records.length === 0) {
      throw new Error('No records to save');
    }
    const result = await attendanceQueries.bulkCreate(records);
    await invalidateAttendanceCache(records[0]?.date);
    return result;
  },

  // Update attendance record
  async updateAttendance(id, data) {
    const result = await attendanceQueries.update(id, data);
    await invalidateAttendanceCache(data.date);
    return result;
  },

  // Delete attendance record
  async deleteAttendance(id) {
    const result = await attendanceQueries.delete(id);
    await invalidateAttendanceCache();
    return result;
  },

  // Get daily summary with caching
  async getDailySummary(date) {
    return await attendanceQueries.getDailySummary(date);
  },

  // Get monthly summary with caching
  async getMonthlySummary(employeeId, year, month) {
    return await withCache.get(`attendance:monthly:${employeeId}:${year}:${month}`, async () => await attendanceQueries.getMonthlySummary(employeeId, year, month));
  }
};

export const shiftService = {
  // Get all active shift types with caching
  async getAllShifts() {
    return await withCache.get('shifts:all', async () => await shiftQueries.getAll());
  },

  // Create new shift type
  async createShift(data) {
    if (!data.name) {
      throw new Error('Shift name is required');
    }
    if (!data.start_time || !data.end_time) {
      throw new Error('Start and end times are required');
    }
    const result = await shiftQueries.create(data);
    await invalidateAttendanceCache();
    return result;
  },

  // Assign shift to employee
  async assignShift(employeeId, shiftTypeId, effectiveFrom) {
    if (!employeeId) {
      throw new Error('Employee is required');
    }
    if (!shiftTypeId) {
      throw new Error('Shift type is required');
    }
    const result = await shiftQueries.assignToEmployee(employeeId, shiftTypeId, effectiveFrom);
    await invalidateAttendanceCache();
    return result;
  }
};

export const leaveService = {
  // Get paid leave balance for employee
  async getPaidLeaveBalance(employeeId) {
    return await leaveQueries.getPaidLeaveBalance(employeeId);
  }
};
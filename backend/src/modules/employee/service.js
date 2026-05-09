import { departmentQueries, employeeQueries, documentQueries, leaveQueries } from './query.js';
import { withCache, invalidateEmployeeCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';

export const departmentService = {
  // Get all departments with caching
  async getAllDepartments() {
    return await withCache.get('departments:all', async () => await departmentQueries.getAll());
  },

  // Create department
  async createDepartment(data) {
    if (!data.name) {
      throw new Error('Department name is required');
    }
    const result = await departmentQueries.create(data);
    await invalidateEmployeeCache();
    return result;
  },

  // Update department
  async updateDepartment(id, data) {
    const result = await departmentQueries.update(id, data);
    await invalidateEmployeeCache();
    return result;
  },

  // Delete department
  async deleteDepartment(id) {
    const result = await departmentQueries.delete(id);
    await invalidateEmployeeCache();
    return result;
  }
};

export const employeeService = {
  // Get all employees with filters and caching
  async getAllEmployees(filters = {}) {
    return await employeeQueries.getAll(filters);
  },

  // Get single employee with caching
  async getEmployeeById(id) {
    return await withCache.get(CACHE_KEYS.EMPLOYEE_DETAIL(id), async () => await employeeQueries.getById(id));
  },

  // Get only active employees with caching
  async getActiveEmployees() {
    return await withCache.get('employees:active', async () => await employeeQueries.getActive());
  },

  // Create employee with auto-generated code
  async createEmployee(data) {
    if (!data.first_name) {
      throw new Error('First name is required');
    }
    if (!data.date_of_joining) {
      throw new Error('Date of joining is required');
    }
    if (!data.employee_code) {
      data.employee_code = await employeeQueries.getNextCode();
    }
    const result = await employeeQueries.create(data);
    await invalidateEmployeeCache();
    return result;
  },

  // Update employee
  async updateEmployee(id, data) {
    try {
      const result = await employeeQueries.update(id, data);
      await invalidateEmployeeCache();
      return result;
    } catch (err) {
      console.log('Query error:', err.message);
      throw err;
    }
  },

  // Delete employee
  async deleteEmployee(id) {
    const result = await employeeQueries.delete(id);
    await invalidateEmployeeCache();
    return result;
  },

  // Get next employee code with caching
  async getNextCode() {
    return await withCache.get('employees:next_code', async () => await employeeQueries.getNextCode());
  },

  // Get employee statistics with caching
  async getEmployeeStats() {
    return await employeeQueries.getStats();
  }
};

export const documentService = {
  // Get documents for employee with caching
  async getDocumentsByEmployee(employeeId) {
    return await withCache.get(`documents:employee:${employeeId}`, async () => await documentQueries.getByEmployeeId(employeeId));
  },

  // Create employee document
  async createDocument(data) {
    if (!data.employee_id) {
      throw new Error('Employee ID is required');
    }
    if (!data.document_type) {
      throw new Error('Document type is required');
    }
    const result = await documentQueries.create(data);
    await invalidateEmployeeCache(data.employee_id);
    return result;
  },

  // Delete document
  async deleteDocument(id) {
    const result = await documentQueries.delete(id);
    await invalidateEmployeeCache();
    return result;
  }
};

export const leaveService = {
  // Get leaves for employee with caching
  async getLeavesByEmployee(employeeId) {
    return await withCache.get(`leaves:employee:${employeeId}`, async () => await leaveQueries.getByEmployeeId(employeeId));
  },

  // Get pending leave requests with caching
  async getPendingLeaves() {
    return await leaveQueries.getPending();
  },

  // Create leave request
  async createLeave(data) {
    if (!data.employee_id) {
      throw new Error('Employee is required');
    }
    if (!data.leave_type) {
      throw new Error('Leave type is required');
    }
    if (!data.start_date || !data.end_date) {
      throw new Error('Start and end dates are required');
    }
    const result = await leaveQueries.create(data);
    await invalidateEmployeeCache(data.employee_id);
    return result;
  },

  // Approve/reject leave
  async updateLeaveStatus(id, status, approvedBy) {
    const validStatuses = ['approved', 'rejected'];
    if (!validStatuses.includes(status)) {
      throw new Error('Invalid status');
    }
    const result = await leaveQueries.updateStatus(id, status, approvedBy);
    await invalidateEmployeeCache();
    return result;
  },

  // Delete leave request
  async deleteLeave(id) {
    const result = await leaveQueries.delete(id);
    await invalidateEmployeeCache();
    return result;
  }
};
import { attendanceService, shiftService, leaveService } from './service.js';

// Returns today's date string in IST (UTC+5:30) as 'YYYY-MM-DD'
const todayIST = () => {
  const istMs = Date.now() + (5.5 * 60 * 60 * 1000);
  return new Date(istMs).toISOString().split('T')[0];
};

const istMonthStart = () => todayIST().slice(0, 8) + '01';

export const attendanceController = {
  // Get all attendance records with filters from query params
  async getAll(req, res) {
    try {
      const filters = {
        employeeId: req.query.employeeId ? parseInt(req.query.employeeId, 10) : null,
        departmentId: req.query.departmentId ? parseInt(req.query.departmentId, 10) : null,
        date: req.query.date,
        startDate: req.query.startDate,
        endDate: req.query.endDate,
        status: req.query.status,
        limit: req.query.limit ? parseInt(req.query.limit, 10) : null
      };
      const attendance = await attendanceService.getAllAttendance(filters);
      res.json(attendance);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get attendance for specific employee (default: current month to today)
  async getByEmployee(req, res) {
    try {
      const { employeeId } = req.params;
      const startDate = req.query.startDate || istMonthStart();
      const endDate   = req.query.endDate   || todayIST();
      const attendance = await attendanceService.getAttendanceByEmployee(employeeId, startDate, endDate);
      res.json(attendance);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get all attendance for specific date
  async getByDate(req, res) {
    try {
      const attendance = await attendanceService.getAttendanceByDate(req.params.date);
      res.json(attendance);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Mark attendance (single record)
  async markAttendance(req, res) {
    try {
      const data = { ...req.body, created_by: req.user?.id };
      const attendance = await attendanceService.markAttendance(data);
      res.status(201).json(attendance);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Bulk mark attendance for multiple employees
  async bulkMarkAttendance(req, res) {
    try {
      console.log('Bulk mark request received:', JSON.stringify(req.body));
      const records = req.body.records;
      console.log(`Processing ${records.length} attendance records`);
      
      const data = records.map(r => ({ ...r, created_by: req.user?.id }));
      const results = await attendanceService.bulkMarkAttendance(data);
      
      console.log(`Successfully saved ${results.length} records`);
      res.status(201).json({ message: `${results.length} records saved`, records: results });
    } catch (error) {
      console.error('Bulk mark error:', error);
      res.status(400).json({ error: error.message });
    }
  },

  // Update attendance record
  async update(req, res) {
    try {
      const attendance = await attendanceService.updateAttendance(req.params.id, req.body);
      res.json(attendance);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Delete all attendance for a specific date
  async deleteAllByDate(req, res) {
    try {
      const { date } = req.params;
      const result = await attendanceService.deleteAllAttendanceByDate(date);
      res.json({ message: `${result.deleted} record(s) deleted for ${date}`, ...result });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Delete attendance record
  async delete(req, res) {
    try {
      await attendanceService.deleteAttendance(req.params.id);
      res.json({ message: 'Attendance record deleted successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get daily attendance summary (default: today)
  async getDailySummary(req, res) {
    try {
      const date = req.query.date || todayIST();
      const summary = await attendanceService.getDailySummary(date);
      res.json(summary);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Get monthly summary for employee
  async getMonthlySummary(req, res) {
    try {
      const { employeeId, year, month } = req.params;
      const summary = await attendanceService.getMonthlySummary(employeeId, parseInt(year, 10), parseInt(month, 10));
      res.json(summary);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
};

export const shiftController = {
  // Get all active shift types
  async getAll(req, res) {
    try {
      const shifts = await shiftService.getAllShifts();
      res.json(shifts);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // Create new shift type
  async create(req, res) {
    try {
      const shift = await shiftService.createShift(req.body);
      res.status(201).json(shift);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  },

  // Assign shift to employee
  async assignShift(req, res) {
    try {
      const { employeeId, shiftTypeId } = req.body;
      const effectiveFrom = req.body.effective_from || todayIST();
      const assignment = await shiftService.assignShift(employeeId, shiftTypeId, effectiveFrom);
      res.status(201).json(assignment);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
};

export const leaveController = {
  // Get paid leave balance for employee
  async getBalance(req, res) {
    try {
      const { employeeId } = req.params;
      console.log('Fetching leave balance for employee:', employeeId);
      const balance = await leaveService.getPaidLeaveBalance(parseInt(employeeId, 10));
      console.log('Leave balance result:', balance);
      res.json(balance);
    } catch (error) {
      console.error('Error fetching leave balance:', error);
      res.status(500).json({ error: error.message });
    }
  }
};

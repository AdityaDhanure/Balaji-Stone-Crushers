import { salaryService } from './service.js';

export const salaryController = {
  async getPeriods(req, res) {
    try {
      const periods = await salaryService.getPeriods();
      res.json({ success: true, data: periods });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getPeriod(req, res) {
    try {
      const period = await salaryService.getPeriod(req.params.id);
      if (!period) {
        return res.status(404).json({ success: false, message: 'Period not found' });
      }
      res.json({ success: true, data: period });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async createPeriod(req, res) {
    try {
      const { year, month } = req.body;
      const period = await salaryService.createPeriod({
        year: parseInt(year),
        month: parseInt(month)
      });
      res.status(201).json({ success: true, data: period });
    } catch (err) {
      const message = err.message || 'Failed to create period';
      if (message.includes('duplicate key') || message.includes('year_month_key')) {
        return res.status(409).json({ success: false, message: 'Period already exists for this month' });
      }
      res.status(500).json({ success: false, message: message });
    }
  },

  async lockPeriod(req, res) {
    try {
      const id = parseInt(req.params.id);
      const isLocked = req.body.is_locked == true || req.body.is_locked === 'true';
      const period = await salaryService.lockPeriod(id, isLocked);
      res.json({ success: true, data: period });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getEmployees(req, res) {
    try {
      const activeOnly = req.query.active !== 'false';
      const employees = await salaryService.getEmployees(activeOnly);
      res.json({ success: true, data: employees });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getSalarySlips(req, res) {
    try {
      const { period_id, employee_id, status, department_id } = req.query;
      const filters = {};
      if (period_id) filters.period_id = parseInt(period_id);
      if (employee_id) filters.employee_id = parseInt(employee_id);
      if (status) filters.status = status;
      if (department_id) filters.department_id = parseInt(department_id);

      const slips = await salaryService.getAllSlips(filters);
      res.json({ success: true, data: slips });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getSalarySlipsByPeriod(req, res) {
    try {
      const slips = await salaryService.getSalarySlipsByPeriod(req.params.periodId);
      res.json({ success: true, data: slips });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getSalarySlip(req, res) {
    try {
      const slip = await salaryService.getSalarySlip(req.params.id);
      if (!slip) {
        return res.status(404).json({ success: false, message: 'Salary slip not found' });
      }
      res.json({ success: true, data: slip });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async generateSalarySlip(req, res) {
    try {
      const user = req.user;
      const data = { ...req.body, created_by: user?.id };
      const slip = await salaryService.generateSalarySlip(data);
      res.status(201).json({ success: true, data: slip });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async bulkGenerateSlips(req, res) {
    try {
      const user = req.user;
      const results = await salaryService.bulkGenerateSlips(req.params.periodId, user?.id);
      res.status(201).json({ success: true, data: results });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async updateSalarySlip(req, res) {
    try {
      const slip = await salaryService.updateSalarySlip(req.params.id, req.body);
      if (!slip) {
        return res.status(404).json({ success: false, message: 'Salary slip not found' });
      }
      res.json({ success: true, data: slip });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async processPayment(req, res) {
    try {
      const slip = await salaryService.processPayment(req.params.id, req.body);
      if (!slip) {
        return res.status(404).json({ success: false, message: 'Salary slip not found' });
      }
      res.json({ success: true, data: slip });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async deleteSalarySlip(req, res) {
    try {
      const slip = await salaryService.deleteSalarySlip(req.params.id);
      if (!slip) {
        return res.status(404).json({ success: false, message: 'Salary slip not found' });
      }
      res.json({ success: true, message: 'Salary slip deleted' });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getAdvances(req, res) {
    try {
      const employeeId = req.query.employee_id ? parseInt(req.query.employee_id) : null;
      const advances = await salaryService.getAdvances(employeeId);
      res.json({ success: true, data: advances });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async createAdvance(req, res) {
    try {
      const user = req.user;
      const data = { ...req.body, created_by: user?.id };
      const advance = await salaryService.createAdvance(data);
      res.status(201).json({ success: true, data: advance });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async approveAdvance(req, res) {
    try {
      const user = req.user;
      const advance = await salaryService.approveAdvance(req.params.id, user?.id);
      res.json({ success: true, data: advance });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async rejectAdvance(req, res) {
    try {
      const user = req.user;
      const advance = await salaryService.rejectAdvance(req.params.id, user?.id);
      res.json({ success: true, data: advance });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getDeductions(req, res) {
    try {
      const deductions = await salaryService.getDeductions();
      res.json({ success: true, data: deductions });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async createDeduction(req, res) {
    try {
      const deduction = await salaryService.createDeduction(req.body);
      res.status(201).json({ success: true, data: deduction });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async updateDeduction(req, res) {
    try {
      const deduction = await salaryService.updateDeduction(req.params.id, req.body);
      if (!deduction) {
        return res.status(404).json({ success: false, message: 'Deduction not found' });
      }
      res.json({ success: true, data: deduction });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async deleteDeduction(req, res) {
    try {
      const deduction = await salaryService.deleteDeduction(req.params.id);
      if (!deduction) {
        return res.status(404).json({ success: false, message: 'Deduction not found' });
      }
      res.json({ success: true, message: 'Deduction deleted' });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getSalarySummary(req, res) {
    try {
      const summary = await salaryService.getSalarySummary(req.params.periodId);
      res.json({ success: true, data: summary });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getEarnings(req, res) {
    try {
      const activeOnly = req.query.active === 'true';
      const earnings = await salaryService.getEarnings(activeOnly);
      res.json({ success: true, data: earnings });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async createEarning(req, res) {
    try {
      const earning = await salaryService.createEarning(req.body);
      res.status(201).json({ success: true, data: earning });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async updateEarning(req, res) {
    try {
      const earning = await salaryService.updateEarning(req.params.id, req.body);
      if (!earning) return res.status(404).json({ success: false, message: 'Earning not found' });
      res.json({ success: true, data: earning });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async deleteEarning(req, res) {
    try {
      const earning = await salaryService.deleteEarning(req.params.id);
      if (!earning) return res.status(404).json({ success: false, message: 'Earning not found' });
      res.json({ success: true, message: 'Earning deleted' });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },
};

import { salaryQueries } from './query.js';
import { withCache, invalidateSalaryCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';

// Ensures salary_slips.extra_days column exists — runs once per server startup
let _schemaChecked = false;
async function ensureSchema() {
  if (!_schemaChecked) {
    await salaryQueries.ensureExtraDaysColumn();
    _schemaChecked = true;
  }
}

export const salaryService = {
  async getPeriods() {
    return await withCache.get(CACHE_KEYS.SALARY, async () => await salaryQueries.getAllPeriods());
  },

  async getPeriod(id) {
    return await withCache.get(`salary:period:${id}`, async () => await salaryQueries.getPeriodById(id));
  },

  async createPeriod(data) {
    const { year, month } = data;
    
    // Check if period already exists for this year/month
    const existing = await salaryQueries.getPeriodByYearMonth(year, month);
    if (existing) {
      throw new Error('Period already exists for this month');
    }
    
    const startDate = new Date(Date.UTC(year, month - 1, 1));
    const endDate = new Date(Date.UTC(year, month, 0));
    
    // Format date as YYYY-MM-DD in local timezone
    const formatDate = (d) => {
      return d.toISOString().split('T')[0];
    };
    
    const result = await salaryQueries.createPeriod({
      year,
      month,
      start_date: formatDate(startDate),
      end_date: formatDate(endDate),
    });
    await invalidateSalaryCache();
    return result;
  },

  async lockPeriod(id, isLocked = true) {
    const result = await salaryQueries.lockPeriod(id, isLocked);
    await invalidateSalaryCache(id);
    return result;
  },

  async getEmployees(activeOnly = true) {
    return await withCache.get(`salary:employees:${activeOnly}`, async () => await salaryQueries.getAllEmployees(activeOnly));
  },

  async getSalarySlipsByPeriod(periodId) {
    return await withCache.get(`salary:slips:period:${periodId}`, async () => await salaryQueries.getSalarySlipsByPeriod(periodId));
  },

  async getSalarySlip(id) {
    return await withCache.get(CACHE_KEYS.SALARY_DETAIL(id), async () => await salaryQueries.getSalarySlipById(id));
  },

  async generateSalarySlip(data) {
    const { employee_id, period_id, created_by } = data;

    const existing = await salaryQueries.getSalarySlipByEmployeeAndPeriod(employee_id, period_id);
    if (existing) {
      throw new Error('Salary slip already exists for this employee and period');
    }

    const employees = await salaryQueries.getAllEmployees(false);
    const employee = employees.find(e => e.id === employee_id);
    if (!employee) {
      throw new Error('Employee not found');
    }

    const period = await salaryQueries.getPeriodById(period_id);
    if (!period) {
      throw new Error('Salary period not found');
    }
parseFloat;
    const isPeriodLocked = 
      period.is_locked === true ||
      period.is_locked === 'true' ||
      period.is_locked === 1;
    if (isPeriodLocked) {
      throw new Error('Salary period is locked');
    }

    const hasAttendance = await salaryQueries.checkAttendanceExists(
      employee_id, period.start_date, period.end_date
    );
    if (!hasAttendance) {
      throw new Error('No attendance records found for this employee in the selected period');
    }

    const attendance = await salaryQueries.getAttendanceSummary(
      employee_id,
      period.start_date,
      period.end_date
    );

    // Only active deductions
    const deductions = await salaryQueries.getDeductions(true);
    const pfDeduction   = deductions.find(d => d.type === 'pf');
    const tdsDeduction  = deductions.find(d => d.type === 'tds');
    const professionalTax = deductions.find(d => d.type === 'tax');

    const activeEarnings = await salaryQueries.getEarnings(true);

    const baseSalary  = parseFloat(employee.salary) || 0;
    const basicSalary = baseSalary;

    await ensureSchema();

    const presentDays = parseInt(attendance.present_days) || 0;
    const halfDays    = parseInt(attendance.half_days)    || 0;
    const absentDays  = parseInt(attendance.absent_days)  || 0;
    const leaveDays   = parseInt(attendance.leave_days)   || 0;
    const sundayDaysWorked = parseFloat(attendance.sunday_days_worked) || 0;

    const totalDays = new Date(Date.UTC(period.year, period.month, 0)).getUTCDate();

    // Count all Sundays in the month — all Sundays are auto-paid
    const startDate = new Date(Date.UTC(period.year, period.month - 1, 1));
    const endDate   = new Date(Date.UTC(period.year, period.month, 0));
    let totalSundays = 0;
    for (let d = new Date(startDate); d <= endDate; d.setUTCDate(d.getUTCDate() + 1)) {
      if (d.getUTCDay() === 0) totalSundays++;
    }

    // paidDays: regular paid attendance + auto-paid Sundays + extra Sunday work.
    // Sunday present counts as 1 extra day; Sunday half-day counts as 0.5.
    const paidDays   = presentDays + (halfDays * 0.5) + leaveDays + totalSundays + sundayDaysWorked;
    const workedDays = paidDays;

    const proRataBasic = Math.round((basicSalary / totalDays) * workedDays * 100) / 100;

    // Compute each active earning's pro-rated amount
    let totalEarningsComponents = 0;
    let proRataHra = 0;
    let proRataAllowances = 0;
    for (const e of activeEarnings) {
      const rate = parseFloat(e.value) || 0;
      const raw = e.calculation_type === 'percentage'
        ? (basicSalary / totalDays) * workedDays * (rate / 100)
        : (rate / totalDays) * workedDays;
      const amount = Math.round(raw * 100) / 100;
      totalEarningsComponents += amount;
      if (e.type === 'hra')       proRataHra        += amount;
      else                        proRataAllowances += amount;
    }

    const overtimeAmount = Math.round(parseFloat(attendance.overtime_hours || 0) * 50 * 100) / 100;
    const totalEarnings = Math.round((proRataBasic + totalEarningsComponents + overtimeAmount) * 100) / 100;

    const pfAmt = pfDeduction ? Math.round(totalEarnings * (parseFloat(pfDeduction.value) / 100) * 100) / 100 : 0;
    const tdsAmt = tdsDeduction && totalEarnings > 15000 ? Math.round(totalEarnings * (parseFloat(tdsDeduction.value) / 100) * 100) / 100 : 0;
    const ptAmt = professionalTax ? parseFloat(professionalTax.value) : 0;

    const totalDeductions = Math.round((pfAmt + tdsAmt + ptAmt) * 100) / 100;
    const netSalary = Math.round((totalEarnings - totalDeductions) * 100) / 100;

    const result = await salaryQueries.createSalarySlip({
      employee_id,
      period_id,
      basic_salary: basicSalary,       // full monthly salary from employees table
      hra: proRataHra,
      allowances: proRataAllowances,
      overtime_amount: overtimeAmount,
      bonus: 0,
      total_earnings: totalEarnings,
      pf_deduction: pfAmt,
      tds_deduction: tdsAmt,
      other_deductions: ptAmt,
      total_deductions: totalDeductions,
      net_salary: netSalary,
      present_days: presentDays,
      absent_days: absentDays,
      leave_days: leaveDays,
      half_days: halfDays,
      sundays: totalSundays,           // total Sundays in month (all auto-paid)
      worked_days: workedDays,
      total_days: totalDays,
      status: 'draft',
      created_by,
      extra_days: sundayDaysWorked,
    });
    
    await invalidateSalaryCache();
    return result;
  },

  async updateSalarySlip(id, data) {
    const result = await salaryQueries.updateSalarySlip(id, data);
    await invalidateSalaryCache(id);
    return result;
  },

  async processPayment(id, data) {
    const { payment_date, payment_mode, transaction_id } = data;
    const result = await salaryQueries.updateSalarySlip(id, {
      status: 'paid',
      payment_date,
      payment_mode,
      transaction_id,
    });
    await invalidateSalaryCache(id);
    return result;
  },

  async deleteSalarySlip(id) {
    const result = await salaryQueries.deleteSalarySlip(id);
    await invalidateSalaryCache(id);
    return result;
  },

  async getAdvances(employeeId = null) {
    return await withCache.get(`salary:advances:${employeeId || 'all'}`, async () => await salaryQueries.getAdvances(employeeId));
  },

  async createAdvance(data) {
    const result = await salaryQueries.createAdvance(data);
    await invalidateSalaryCache();
    return result;
  },

  async approveAdvance(id, approvedBy) {
    const result = await salaryQueries.updateAdvanceStatus(id, 'approved', approvedBy);
    await invalidateSalaryCache();
    return result;
  },

  async rejectAdvance(id, approvedBy) {
    const result = await salaryQueries.updateAdvanceStatus(id, 'rejected', approvedBy);
    await invalidateSalaryCache();
    return result;
  },

  async getDeductions() {
    return await withCache.get('salary:deductions', async () => await salaryQueries.getDeductions());
  },

  async createDeduction(data) {
    const { name, type, calculation_type, value, description } = data;
    const result = await salaryQueries.createDeduction({ name, type, calculation_type, value, description });
    await invalidateSalaryCache();
    return result;
  },

  async updateDeduction(id, data) {
    const result = await salaryQueries.updateDeduction(id, data);
    await invalidateSalaryCache();
    return result;
  },

  async deleteDeduction(id) {
    const result = await salaryQueries.deleteDeduction(id);
    await invalidateSalaryCache();
    return result;
  },

  async getPendingAdvances(employeeId) {
    return await withCache.get(`salary:pending-advances:${employeeId}`, async () => await salaryQueries.getPendingAdvancesByEmployee(employeeId));
  },

  async getSalarySummary(periodId) {
    return await withCache.get(`salary:summary:${periodId}`, async () => await salaryQueries.getSalarySummary(periodId));
  },

  async getAllSlips(filters = {}) {
    const cacheKey = `salary:slips:${JSON.stringify(filters)}`;
    return await withCache.get(cacheKey, async () => await salaryQueries.getAllSlips(filters));
  },

  async bulkGenerateSlips(periodId, createdBy) {
    const employees = await salaryQueries.getAllEmployees(true);
    const period = await salaryQueries.getPeriodById(periodId);

    if (!period) {
      throw new Error('Salary period not found');
    }

    const isPeriodLocked = period.is_locked === true || period.is_locked === 'true';
    if (isPeriodLocked) {
      throw new Error('Salary period is locked');
    }

    const results = { success: [], failed: [] };

    const deductions = await salaryQueries.getDeductions();
    const pfDeduction = deductions.find(d => d.type === 'pf');
    const tdsDeduction = deductions.find(d => d.type === 'tds');
    const professionalTax = deductions.find(d => d.type === 'tax');

    for (const emp of employees) {
      try {
        const existing = await salaryQueries.getSalarySlipByEmployeeAndPeriod(emp.id, periodId);
        if (existing) {
          results.failed.push({ employee_id: emp.id, name: `${emp.first_name} ${emp.last_name}`, reason: 'Already exists' });
          continue;
        }

        const hasAttendance = await salaryQueries.checkAttendanceExists(
          emp.id, period.start_date, period.end_date
        );
        if (!hasAttendance) {
          results.failed.push({ employee_id: emp.id, name: `${emp.first_name} ${emp.last_name}`, reason: 'No attendance records found' });
          continue;
        }

        const attendance = await salaryQueries.getAttendanceSummary(
          emp.id, period.start_date, period.end_date
        );

        // Only active deductions
        const deductions = await salaryQueries.getDeductions(true);
        const pfDeduction   = deductions.find(d => d.type === 'pf');
        const tdsDeduction  = deductions.find(d => d.type === 'tds');
        const professionalTax = deductions.find(d => d.type === 'tax');

        const activeEarnings = await salaryQueries.getEarnings(true);

        const baseSalary  = parseFloat(emp.salary) || 0;
        const basicSalary = baseSalary;

        await ensureSchema();

        const presentDays = parseInt(attendance.present_days) || 0;
        const halfDays    = parseInt(attendance.half_days)    || 0;
        const absentDays  = parseInt(attendance.absent_days)  || 0;
        const leaveDays   = parseInt(attendance.leave_days)   || 0;
        const sundayDaysWorked = parseFloat(attendance.sunday_days_worked) || 0;

        const totalDays = new Date(Date.UTC(period.year, period.month, 0)).getUTCDate();

        // Count all Sundays in the month — all auto-paid
        const startDate = new Date(Date.UTC(period.year, period.month - 1, 1));
        const endDate   = new Date(Date.UTC(period.year, period.month, 0));
        let totalSundays = 0;
        for (let d = new Date(startDate); d <= endDate; d.setUTCDate(d.getUTCDate() + 1)) {
          if (d.getUTCDay() === 0) totalSundays++;
        }

        const paidDays   = presentDays + (halfDays * 0.5) + leaveDays + totalSundays + sundayDaysWorked;
        const workedDays = paidDays;

        const proRataBasic = Math.round((basicSalary / totalDays) * workedDays * 100) / 100;

        let totalEarningsComponents = 0;
        let proRataHra = 0;
        let proRataAllowances = 0;
        for (const e of activeEarnings) {
          const rate = parseFloat(e.value) || 0;
          const raw = e.calculation_type === 'percentage'
            ? (basicSalary / totalDays) * workedDays * (rate / 100)
            : (rate / totalDays) * workedDays;
          const amount = Math.round(raw * 100) / 100;
          totalEarningsComponents += amount;
          if (e.type === 'hra')  proRataHra        += amount;
          else                   proRataAllowances += amount;
        }

        const overtimeAmount = Math.round(parseFloat(attendance.overtime_hours || 0) * 50 * 100) / 100;
        const totalEarnings = Math.round((proRataBasic + totalEarningsComponents + overtimeAmount) * 100) / 100;

        const pfAmt = pfDeduction ? Math.round(totalEarnings * (parseFloat(pfDeduction.value) / 100) * 100) / 100 : 0;
        const tdsAmt = tdsDeduction && totalEarnings > 15000 ? Math.round(totalEarnings * (parseFloat(tdsDeduction.value) / 100) * 100) / 100 : 0;
        const ptAmt = professionalTax ? parseFloat(professionalTax.value) : 0;

        const totalDeductions = Math.round((pfAmt + tdsAmt + ptAmt) * 100) / 100;
        const netSalary = Math.round((totalEarnings - totalDeductions) * 100) / 100;

        await salaryQueries.createSalarySlip({
          employee_id: emp.id,
          period_id: periodId,
          basic_salary: basicSalary,       // full monthly salary from employees table
          hra: proRataHra,
          allowances: proRataAllowances,
          overtime_amount: overtimeAmount,
          bonus: 0,
          total_earnings: totalEarnings,
          pf_deduction: pfAmt,
          tds_deduction: tdsAmt,
          other_deductions: ptAmt,
          total_deductions: totalDeductions,
          net_salary: netSalary,
          present_days: presentDays,
          absent_days: absentDays,
          leave_days: leaveDays,
          half_days: halfDays,
          sundays: totalSundays,           // total Sundays in month (all auto-paid)
          worked_days: workedDays,
          total_days: totalDays,
          status: 'draft',
          created_by: createdBy,
          extra_days: sundayDaysWorked,
        });

        results.success.push({ employee_id: emp.id, name: `${emp.first_name} ${emp.last_name}` });
      } catch (err) {
        results.failed.push({ employee_id: emp.id, name: `${emp.first_name} ${emp.last_name}`, reason: err.message });
      }
    }

    await invalidateSalaryCache();
    return results;
  },

  // ── Earnings ─────────────────────────────────────────────────────────

  async getEarnings(activeOnly = false) {
    await salaryQueries.initializeEarningsTable();
    return await withCache.get(
      `salary:earnings:${activeOnly}`,
      () => salaryQueries.getEarnings(activeOnly),
      60
    );
  },

  async createEarning(data) {
    const result = await salaryQueries.createEarning(data);
    await invalidateSalaryCache();
    return result;
  },

  async updateEarning(id, data) {
    const result = await salaryQueries.updateEarning(id, data);
    await invalidateSalaryCache();
    return result;
  },

  async deleteEarning(id) {
    const result = await salaryQueries.deleteEarning(id);
    await invalidateSalaryCache();
    return result;
  },
};

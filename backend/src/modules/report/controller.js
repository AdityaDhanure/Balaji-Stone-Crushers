import { reportService } from './service.js';

const istNow = () => new Date(Date.now() + 330 * 60 * 1000);

export const reportController = {
  async getOverviewSummary(req, res) {
    try {
      const { start_date, end_date } = req.query;
      const data = await reportService.getOverviewSummary(start_date, end_date);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getSalesReport(req, res) {
    try {
      const { start_date, end_date } = req.query;
      const data = await reportService.getSalesReport(start_date, end_date);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getExpenseSummary(req, res) {
    try {
      const { start_date, end_date } = req.query;
      const data = await reportService.getExpenseSummary(start_date, end_date);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getProfitLoss(req, res) {
    try {
      const { start_date, end_date } = req.query;
      const data = await reportService.getProfitLoss(start_date, end_date);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getYearlyTrend(req, res) {
    try {
      const year = parseInt(req.query.year, 10) || istNow().getUTCFullYear();
      const data = await reportService.getYearlyTrend(year);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },
};

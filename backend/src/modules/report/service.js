import { reportQueries } from './query.js';
import { withCache } from '../../middleware/cacheMiddleware.js';

export const reportService = {
  async getOverviewSummary(startDate, endDate) {
    const key = `reports:overview:${startDate}:${endDate}`;
    return withCache.get(key, () => reportQueries.getOverviewSummary(startDate, endDate), 120);
  },

  async getSalesReport(startDate, endDate) {
    const key = `reports:sales:${startDate}:${endDate}`;
    return withCache.get(key, () => reportQueries.getSalesReport(startDate, endDate));
  },

  async getExpenseSummary(startDate, endDate) {
    const key = `reports:expense-summary:${startDate}:${endDate}`;
    return withCache.get(key, () => reportQueries.getExpenseSummary(startDate, endDate));
  },

  async getProfitLoss(startDate, endDate) {
    const key = `reports:profit-loss:${startDate}:${endDate}`;
    return withCache.get(key, () => reportQueries.getProfitLoss(startDate, endDate));
  },

  async getYearlyTrend(year) {
    const key = `reports:yearly-trend:${year}`;
    return withCache.get(key, () => reportQueries.getYearlyTrend(year));
  },
};

import { cacheGet, cacheSet, cacheDel, cacheDelPattern, CACHE_KEYS } from '../utils/cache.js';

export const withCache = {
  async get(key, fetchFn, ttl = 300) {
    const cached = await cacheGet(key);
    if (cached) {
      console.log(`Cache HIT for key: ${key}`);
      return cached;
    }
    
    console.log(`Cache MISS for key: ${key}`);
    const data = await fetchFn();
    if (data) {
      await cacheSet(key, data, ttl);
    }
    return data;
  },
  
  async invalidate(key) {
    await cacheDel(key);
    console.log(`Cache invalidated for key: ${key}`);
  },
  
  async invalidatePattern(pattern) {
    await cacheDelPattern(pattern);
    console.log(`Cache invalidated for pattern: ${pattern}`);
  }
};

export const invalidateBlastCache = async (blastId = null) => {
  await withCache.invalidatePattern('blasts:*');
  if (blastId) {
    await withCache.invalidate(CACHE_KEYS.BLAST_DETAIL(blastId));
    await withCache.invalidate(CACHE_KEYS.BLAST_TRIPS(blastId));
    await withCache.invalidate(CACHE_KEYS.BLAST_TRIPS_BY_DATE(blastId));
    await withCache.invalidate(CACHE_KEYS.BLAST_TRIPS_DATES(blastId));
    await withCache.invalidate(CACHE_KEYS.BLAST_EXPENSES(blastId));
    await withCache.invalidate(CACHE_KEYS.BLAST_EXPENSES_BY_DATE(blastId));
    await withCache.invalidate(CACHE_KEYS.BLAST_EXPENSES_DATES(blastId));
  }
};

export const invalidateEmployeeCache = async () => {
  await withCache.invalidatePattern('employees:*');
  await withCache.invalidatePattern('leaves:*');
  await withCache.invalidatePattern('departments:*');
};

export const invalidateVehicleCache = async (id = null) => {
  await withCache.invalidatePattern('vehicles:*');
  await withCache.invalidate('vehicles:expiries');
  await withCache.invalidatePattern('usage:*');
  if (id) {
    await withCache.invalidate(CACHE_KEYS.VEHICLE_DETAIL(id));
  }
};

export const invalidateExpenseCache = async (id = null) => {
  await withCache.invalidatePattern('expenses:*');
  if (id) {
    await withCache.invalidate(CACHE_KEYS.EXPENSE_DETAIL(id));
  }
};

export const invalidateDieselCache = async (id = null) => {
  await withCache.invalidate(CACHE_KEYS.DIESEL);
  await withCache.invalidatePattern('diesel:consumption:*');
  await withCache.invalidatePattern('diesel:vehicle-wise:*');
  await withCache.invalidatePattern('diesel:pump-payments*');
  await withCache.invalidate(CACHE_KEYS.DIESEL_STOCK);
};

export const invalidateAttendanceCache = async (date = null) => {
  if (date) {
    await withCache.invalidate(CACHE_KEYS.ATTENDANCE(date));
    await withCache.invalidate(`attendance:summary:${date}`);
  }
  await withCache.invalidatePattern('attendance:*');
};

export const invalidateSalaryCache = async (id = null) => {
  await withCache.invalidatePattern('salary:*');
  if (id) {
    await withCache.invalidate(CACHE_KEYS.SALARY_DETAIL(id));
  }
};

export const invalidateMaintenanceCache = async (id = null) => {
  await withCache.invalidatePattern('maintenance:*');
  if (id) {
    await withCache.invalidate(CACHE_KEYS.MAINTENANCE_DETAIL(id));
  }
};

export const invalidateCustomerCache = async (id = null) => {
  await withCache.invalidate(CACHE_KEYS.CUSTOMERS);
  await withCache.invalidatePattern('customers:*');
  await withCache.invalidatePattern('contacts:*');
  await withCache.invalidatePattern('wallet:*');
};

export const invalidateProductCache = async (id = null) => {
  await withCache.invalidate(CACHE_KEYS.PRODUCTS);
  await withCache.invalidate(CACHE_KEYS.PRODUCT_CATEGORIES);
  await withCache.invalidatePattern('products:*');
  await withCache.invalidatePattern('production:*');
};

export const invalidateBillingCache = async (id = null) => {
  await withCache.invalidate(CACHE_KEYS.BILLING_STATS);
  await withCache.invalidatePattern('billing:invoices:*');
  await withCache.invalidatePattern('billing:items:*');
  await withCache.invalidatePattern('billing:payments:*');
};

export const invalidateSettingsCache = async () => {
  await withCache.invalidatePattern('settings:*');
};
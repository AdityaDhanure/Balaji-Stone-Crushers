import { createClient } from 'redis';
import { REDIS_URL, CACHE_TTL } from '../config/env.js';


let redisClient = null;
let redisConnected = false;
let redisInitAttempted = false;

export const isRedisConnected = () => redisConnected;

export const initializeRedis = async () => {
  if (redisInitAttempted) {
    return redisConnected;
  }

  redisInitAttempted = true;

  try {
    redisClient = createClient({ url: REDIS_URL });

    redisClient.on('error', (err) => {
      if (!redisInitAttempted) return;
      redisConnected = false;
    });

    redisClient.on('end', () => {
      redisConnected = false;
    });

    await redisClient.connect();
    redisConnected = true;
    console.log(`✅ Redis connected successfully on port 6379!`);
    return true;
  } catch (err) {
    console.warn('⚠️ Redis not connected. Caching disabled.');
    console.warn('   Run `docker run -d -p 6379:6379 redis` to enable caching');
    redisConnected = false;
    return false;
  }
};

export const getRedisClient = async () => {
  if (redisClient && redisConnected) {
    return redisClient;
  }

  if (!redisClient && !redisInitAttempted) {
    await initializeRedis();
  }

  return redisConnected ? redisClient : null;
};

export const cacheGet = async (key) => {
  try {
    const client = await getRedisClient();
    if (!client) return null;

    const data = await client.get(key);
    if (data) {
      console.log(`📦 Cache HIT: ${key}`);
      return JSON.parse(data);
    }
    console.log(`📭 Cache MISS: ${key}`);
    return null;
  } catch (err) {
    return null;
  }
};

export const cacheSet = async (key, value, ttl = CACHE_TTL) => {
  try {
    const client = await getRedisClient();
    if (!client) return false;

    await client.setEx(key, ttl, JSON.stringify(value));
    return true;
  } catch (err) {
    return false;
  }
};

export const cacheDel = async (key) => {
  try {
    const client = await getRedisClient();
    if (!client) return false;

    await client.del(key);
    return true;
  } catch (err) {
    return false;
  }
};

export const cacheDelPattern = async (pattern) => {
  try {
    const client = await getRedisClient();
    if (!client) return false;

    const keys = [];
    let cursor = '0';

    do {
      const result = await client.scan(cursor, {
        MATCH: pattern,
        COUNT: 100,
      });
      cursor = result.cursor;
      keys.push(...result.keys);
    } while (cursor !== '0');

    if (keys.length > 0) {
      await client.del(keys);
    }
    return true;
  } catch (err) {
    return false;
  }
};

export const CACHE_KEYS = {
  // ───────── BLASTS ─────────
  BLASTS: 'blasts:all',
  BLAST_ACTIVE: 'blasts:active',
  BLAST_DETAIL: (id) => `blasts:detail:${id}`,
  BLAST_TRIPS: (id) => `blasts:${id}:trips`,
  BLAST_TRIPS_BY_DATE: (id) => `blasts:${id}:trips:by-date`,
  BLAST_TRIPS_DATES: (id) => `blasts:${id}:trips:dates`,
  BLAST_EXPENSES: (id) => `blasts:${id}:expenses`,
  BLAST_EXPENSES_BY_DATE: (id) => `blasts:${id}:expenses:by-date`,
  BLAST_EXPENSES_DATES: (id) => `blasts:${id}:expenses:dates`,

  // ───────── EMPLOYEES ─────────
  EMPLOYEES: 'employees:all',
  EMPLOYEE_DETAIL: (id) => `employees:detail:${id}`,

  // ───────── VEHICLES ─────────
  VEHICLES: 'vehicles:all',
  VEHICLE_DETAIL: (id) => `vehicles:detail:${id}`,
  VEHICLE_TYPES: 'vehicles:types',
  VEHICLES_BY_TYPE: (type) => `vehicles:type:${type}`,

  // ───────── EXPENSES ─────────
  EXPENSES: 'expenses:all',
  EXPENSE_DETAIL: (id) => `expenses:detail:${id}`,

  // ───────── DIESEL ─────────
  DIESEL: 'diesel:all',
  DIESEL_DETAIL: (id) => `diesel:detail:${id}`,
  DIESEL_STOCK: 'diesel:stock',
  DIESEL_CONSUMPTION_ALL: 'diesel:consumption:all',
  DIESEL_CONSUMPTION_VEHICLE: (id) => `diesel:consumption:vehicle:${id}`,
  DIESEL_CONSUMPTION_RANGE: (start, end) => `diesel:consumption:range:${start}:${end}`,
  DIESEL_CONSUMPTION_GROUPED: 'diesel:consumption:grouped',
  DIESEL_VEHICLE_WISE: (start, end) => `diesel:vehicle-wise:${start}:${end}`,
  DIESEL_PUMP_PAYMENTS: 'diesel:pump-payments',

  // ───────── ATTENDANCE ─────────
  ATTENDANCE: (date) => `attendance:${date}`,
  ATTENDANCE_ALL: 'attendance:all',

  // ───────── SALARY ─────────
  SALARY: 'salary:all',
  SALARY_DETAIL: (id) => `salary:detail:${id}`,

  // ───────── MAINTENANCE ─────────
  MAINTENANCE: 'maintenance:all',
  MAINTENANCE_DETAIL: (id) => `maintenance:detail:${id}`,

  // ───────── CUSTOMERS ─────────
  CUSTOMERS: 'customers:all',
  CUSTOMER_DETAIL: (id) => `customers:detail:${id}`,
  CUSTOMERS_ACTIVE: 'customers:active',
  CUSTOMERS_SEARCH: (query) => `customers:search:${query}`,
  CUSTOMER_NEXT_CODE: 'customers:next-code',

  CONTACTS_BY_CUSTOMER: (id) => `contacts:customer:${id}`,

  WALLET_TRANSACTIONS: (id) => `wallet:customer:${id}`,
  WALLET_BALANCE: (id) => `wallet:balance:${id}`,

  // ───────── PRODUCTS ─────────
  PRODUCTS: 'products:all',
  PRODUCT_DETAIL: (id) => `products:detail:${id}`,
  PRODUCTS_ACTIVE: 'products:active',
  PRODUCT_CATEGORIES: 'products:categories',
  PRODUCT_RATES: (id) => `products:rates:${id}`,

  // ───────── PRODUCTION ─────────
  PRODUCTION_ALL: (filters = {}) => `production:all:${JSON.stringify(filters)}`,
  PRODUCTION_BY_DATE: (date) => `production:date:${date}`,
  PRODUCTION_SUMMARY: (date) => `production:summary:${date}`,
  PRODUCTION_GROUPED: 'production:grouped',

  // ───────── BILLING ─────────
  BILLING: 'billing:all',
  BILLING_STATS: 'billing:stats',
  BILLING_INVOICES: (filters) => `billing:invoices:${JSON.stringify(filters)}`,
  BILLING_DETAIL: (id) => `billing:detail:${id}`,
  BILLING_ITEMS: (id) => `billing:items:${id}`,
  BILLING_PAYMENTS: (id) => `billing:payments:${id}`,

  // ───────── REPORTS ─────────
  REPORTS: 'reports:all',

  // ───────── SYSTEM ─────────
  NEXT_NUMBER: 'next:blast_number',

  SETTINGS_ALL: 'settings:all',
  SETTINGS_MAP: 'settings:map',
  SETTINGS_CATEGORY: (category) => `settings:category:${category}`,
};
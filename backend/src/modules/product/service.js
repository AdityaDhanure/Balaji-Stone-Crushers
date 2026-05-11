import { productQueries, categoryQueries, rateQueries, productionQueries } from './query.js';
import { withCache, invalidateProductCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';
import { todayIst } from '../../utils/istDateTime.js';

export const productService = {
  async getAllProducts() {
    return await withCache.get(CACHE_KEYS.PRODUCTS, async () => await productQueries.getAll());
  },

  async getProductById(id) {
    return await withCache.get(CACHE_KEYS.PRODUCT_DETAIL(id), async () => await productQueries.getById(id));
  },

  async getActiveProducts() {
    return await withCache.get(CACHE_KEYS.PRODUCTS_ACTIVE, async () => await productQueries.getActive());
  },

  async createProduct(data) {
    if (!data.name) {
      throw new Error('Product name is required');
    }
    if (!data.product_code) {
      data.product_code = await productQueries.getNextProductCode();
    }
    const result = await productQueries.create(data);
    
    if (data.selling_rate_per_brass && data.selling_rate_per_brass > 0) {
      await rateQueries.create({
        product_id: result.id,
        selling_rate_per_brass: data.selling_rate_per_brass,
        production_rate_per_brass: data.production_rate_per_brass || 0,
        effective_from: todayIst()
      });
    }
    
    await invalidateProductCache();
    return result;
  },

  async updateProduct(id, data) {
    const result = await productQueries.update(id, data);
    
    if (data.selling_rate_per_brass && data.selling_rate_per_brass > 0) {
      const existingRates = await rateQueries.getByProductId(id);
      if (existingRates && existingRates.length > 0) {
        await rateQueries.update(existingRates[0].id, {
          selling_rate_per_brass: data.selling_rate_per_brass,
          production_rate_per_brass: data.production_rate_per_brass
        });
      } else {
        await rateQueries.create({
          product_id: id,
          selling_rate_per_brass: data.selling_rate_per_brass,
          production_rate_per_brass: data.production_rate_per_brass || 0,
          effective_from: todayIst()
        });
      }
    }
    
    await invalidateProductCache();
    return result;
  },

  async deleteProduct(id) {
    const result = await productQueries.delete(id);
    await invalidateProductCache();
    return result;
  }
};

export const categoryService = {
  async getAllCategories() {
    return await withCache.get(CACHE_KEYS.PRODUCT_CATEGORIES, async () => await categoryQueries.getAll());
  },

  async createCategory(data) {
    if (!data.name) {
      throw new Error('Category name is required');
    }
    const result = await categoryQueries.create(data);
    await invalidateProductCache();
    return result;
  },

  async deleteCategory(id) {
    const result = await categoryQueries.delete(id);
    await invalidateProductCache();
    return result;
  }
};

export const rateService = {
  async getRatesByProduct(productId) {
    return await withCache.get(CACHE_KEYS.PRODUCT_RATES(productId), async () => await rateQueries.getByProductId(productId));
  },

  async createRate(data) {
    if (!data.product_id) {
      throw new Error('Product ID is required');
    }
    if (!data.selling_rate_per_brass || data.selling_rate_per_brass <= 0) {
      throw new Error('Valid selling rate per brass is required');
    }
    const result = await rateQueries.create(data);
    await invalidateProductCache();
    return result;
  },

  async updateRate(id, data) {
    const result = await rateQueries.update(id, data);
    await invalidateProductCache();
    return result;
  },

  async deleteRate(id) {
    const result = await rateQueries.delete(id);
    await invalidateProductCache();
    return result;
  }
};

export const productionService = {
  async getAllProduction(filters = {}) {
    return await withCache.get(CACHE_KEYS.PRODUCTION_ALL(filters), async () => await productionQueries.getAll(filters));
  },

  async getProductionByDate(date) {
    return await withCache.get(CACHE_KEYS.PRODUCTION_BY_DATE(date), async () => await productionQueries.getByDate(date));
  },

  async getDailySummary(date) {
    return await withCache.get(CACHE_KEYS.PRODUCTION_SUMMARY(date), async () => await productionQueries.getDailySummary(date));
  },

  async createProduction(data) {
    if (!data.product_id) {
      throw new Error('Product ID is required');
    }
    if (!data.quantity_tons || data.quantity_tons <= 0) {
      throw new Error('Valid quantity is required');
    }
    const result = await productionQueries.create(data);
    await invalidateProductCache();
    return result;
  },

  async updateProduction(id, data) {
    const result = await productionQueries.update(id, data);
    
    if (data.production_rate_per_brass && data.production_rate_per_brass > 0) {
      const quantity = data.quantity_tons || result.quantity_tons;
      const royalty = data.royalty_amount ?? result.royalty_amount;
      const transport = data.transportation_cost ?? result.transportation_cost;
      const totalValue = (quantity * data.production_rate_per_brass) + royalty + transport;
      
      await productionQueries.updateSnapshot(id, data.production_rate_per_brass, totalValue);
    }
    
    await invalidateProductCache();
    return result;
  },

  async deleteProduction(id) {
    const result = await productionQueries.delete(id);
    await invalidateProductCache();
    return result;
  },

  async getMonthlyStats(year, month) {
    return await productionQueries.getMonthlyStats(year, month);
  },

  async getGroupedByDate() {
    return await withCache.get(CACHE_KEYS.PRODUCTION_GROUPED, async () => await productionQueries.getGroupedByDate());
  }
};

import { productService, categoryService, rateService, productionService } from './service.js';

export const productController = {
  async getAll(req, res, next) {
    try {
      const products = await productService.getAllProducts();
      res.json({ success: true, data: products });
    } catch (error) {
      next(error);
    }
  },

  async getById(req, res, next) {
    try {
      const product = await productService.getProductById(req.params.id);
      if (!product) {
        return res.status(404).json({ error: 'Product not found' });
      }
      res.json({ success: true, data: product });
    } catch (error) {
      next(error);
    }
  },

  async getActive(req, res, next) {
    try {
      const products = await productService.getActiveProducts();
      res.json({ success: true, data: products });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const product = await productService.createProduct(req.body);
      res.status(201).json({ success: true, data: product, message: 'Product created successfully' });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const product = await productService.updateProduct(req.params.id, req.body);
      res.json({ success: true, data: product, message: 'Product updated successfully' });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      await productService.deleteProduct(req.params.id);
      res.json({ success: true, message: 'Product deleted successfully' });
    } catch (error) {
      next(error);
    }
  },

  async getNextCode(req, res, next) {
    try {
      const { productQueries } = await import('./query.js');
      const nextCode = await productQueries.getNextProductCode();
      res.json({ success: true, product_code: nextCode });
    } catch (error) {
      next(error);
    }
  }
};

export const categoryController = {
  async getAll(req, res, next) {
    try {
      const categories = await categoryService.getAllCategories();
      res.json({ success: true, data: categories });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const category = await categoryService.createCategory(req.body);
      res.status(201).json({ success: true, data: category, message: 'Category created successfully' });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      await categoryService.deleteCategory(req.params.id);
      res.json({ success: true, message: 'Category deleted successfully' });
    } catch (error) {
      next(error);
    }
  }
};

export const rateController = {
  async getByProduct(req, res, next) {
    try {
      const rates = await rateService.getRatesByProduct(req.params.productId);
      res.json({ success: true, data: rates });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const rate = await rateService.createRate(req.body);
      res.status(201).json({ success: true, data: rate, message: 'Rate created successfully' });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const rate = await rateService.updateRate(req.params.id, req.body);
      res.json({ success: true, data: rate, message: 'Rate updated successfully' });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      await rateService.deleteRate(req.params.id);
      res.json({ success: true, message: 'Rate deleted successfully' });
    } catch (error) {
      next(error);
    }
  }
};

export const productionController = {
  async getAll(req, res, next) {
    try {
      const filters = {
        startDate: req.query.startDate,
        endDate: req.query.endDate,
        productId: req.query.productId
      };
      const production = await productionService.getAllProduction(filters);
      res.json({ success: true, data: production });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  async getByDate(req, res, next) {
    try {
      const production = await productionService.getProductionByDate(req.params.date);
      res.json({ success: true, data: production });
    } catch (error) {
      next(error);
    }
  },

  async getDailySummary(req, res, next) {
    try {
      const summary = await productionService.getDailySummary(req.params.date);
      res.json({ success: true, data: summary });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const data = { ...req.body, created_by: req.user?.id };
      const production = await productionService.createProduction(data);
      res.status(201).json({ success: true, data: production, message: 'Production entry created successfully' });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const production = await productionService.updateProduction(req.params.id, req.body);
      res.json({ success: true, data: production, message: 'Production entry updated successfully' });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      await productionService.deleteProduction(req.params.id);
      res.json({ success: true, message: 'Production entry deleted successfully' });
    } catch (error) {
      next(error);
    }
  },

  async getMonthlyStats(req, res, next) {
    try {
      const { year, month } = req.params;
      const stats = await productionService.getMonthlyStats(parseInt(year), parseInt(month));
      res.json({ success: true, data: stats });
    } catch (error) {
      next(error);
    }
  },

  async getGroupedByDate(req, res, next) {
    try {
      const data = await productionService.getGroupedByDate();
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }
};

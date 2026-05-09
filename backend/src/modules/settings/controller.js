import { settingsService } from './service.js';
import { SETTING_CATEGORIES } from './query.js';

const getUserId = (req) => {
  if (!req.user) {
    throw new Error('Unauthorized');
  }
  return req.user.id;
};

export const settingsController = {
  async getAll(req, res, next) {
    try {
      const format = req.query.format;
      if (format === 'map') {
        const map = await settingsService.getAllAsMap();
        return res.json({ success: true, data: map });
      }
      const settings = await settingsService.getAll();
      res.json({ success: true, data: settings });
    } catch (error) {
      next(error);
    }
  },

  async getByKey(req, res, next) {
    try {
      const { key } = req.params;
      const setting = await settingsService.getByKey(key);
      if (!setting) {
        return res.status(404).json({ success: false, message: `Setting '${key}' not found` });
      }
      res.json({ success: true, data: setting });
    } catch (error) {
      next(error);
    }
  },

  async getByCategory(req, res, next) {
    try {
      const { category } = req.params;
      if (!Object.values(SETTING_CATEGORIES).includes(category)) {
        return res.status(400).json({
          success: false,
          message: `Invalid category. Valid categories: ${Object.values(SETTING_CATEGORIES).join(', ')}`,
        });
      }
      const settings = await settingsService.getByCategory(category);
      res.json({ success: true, data: settings });
    } catch (error) {
      next(error);
    }
  },

  async create(req, res, next) {
    try {
      const { key, value, category, description } = req.body;
      if (!key) {
        return res.status(400).json({ success: false, message: 'Setting key is required' });
      }
      const setting = await settingsService.create(key, value, { category, description }, getUserId(req));
      res.status(201).json({ success: true, data: setting, message: 'Setting created successfully' });
    } catch (error) {
      next(error);
    }
  },

  async update(req, res, next) {
    try {
      const { key } = req.body;
      const { value } = req.body;
      if (!key) {
        return res.status(400).json({ success: false, message: 'Setting key is required' });
      }
      const setting = await settingsService.update(key, value, getUserId(req));
      res.json({ success: true, data: setting, message: 'Setting updated successfully' });
    } catch (error) {
      if (error.message.includes('not found')) {
        return res.status(404).json({ success: false, message: error.message });
      }
      next(error);
    }
  },

  async bulkUpdate(req, res, next) {
    try {
      const { settings } = req.body;
      if (!Array.isArray(settings)) {
        return res.status(400).json({ success: false, message: 'Settings must be an array' });
      }
      const result = await settingsService.bulkUpdate(settings, getUserId(req));
      res.json({
        success: true,
        message: `Updated ${result.results.length} settings${result.errors.length > 0 ? `, ${result.errors.length} failed` : ''}`,
        data: {
          updated: result.results,
          errors: result.errors,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  async delete(req, res, next) {
    try {
      const { key } = req.params;
      await settingsService.delete(key);
      res.json({ success: true, message: `Setting '${key}' deleted successfully` });
    } catch (error) {
      if (error.message.includes('not found') || error.message.includes('Cannot delete')) {
        return res.status(400).json({ success: false, message: error.message });
      }
      next(error);
    }
  },

  async resetToDefaults(req, res, next) {
    try {
      await settingsService.resetToDefaults();
      res.json({ success: true, message: 'Settings reset to defaults successfully' });
    } catch (error) {
      next(error);
    }
  },

  async exportSettings(req, res, next) {
    try {
      const exportData = await settingsService.exportSettings();
      res.json({ success: true, data: exportData });
    } catch (error) {
      next(error);
    }
  },

  async importSettings(req, res, next) {
    try {
      const importData = req.body;
      if (!importData || !importData.settings) {
        return res.status(400).json({ success: false, message: 'Invalid import data format' });
      }
      const result = await settingsService.importSettings(importData, { userId: getUserId(req) });
      res.json({
        success: true,
        message: 'Settings imported successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },

  async getCompanyInfo(req, res, next) {
    try {
      const settings = await settingsService.getCompanyInfo();
      res.json({ success: true, data: settings });
    } catch (error) {
      next(error);
    }
  },

  async getInvoiceSettings(req, res, next) {
    try {
      const settings = await settingsService.getInvoiceSettings();
      res.json({ success: true, data: settings });
    } catch (error) {
      next(error);
    }
  },

  async getAlertSettings(req, res, next) {
    try {
      const settings = await settingsService.getAlertSettings();
      res.json({ success: true, data: settings });
    } catch (error) {
      next(error);
    }
  },
};
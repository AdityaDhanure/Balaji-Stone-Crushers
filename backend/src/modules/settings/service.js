import { settingsQueries, SETTING_CATEGORIES, DEFAULT_SETTINGS } from './query.js';
import { withCache } from '../../middleware/cacheMiddleware.js';
import { CACHE_KEYS } from '../../utils/cache.js';
import { nowIstIsoString } from '../../utils/istDateTime.js';

const SETTINGS_CACHE_TTL = 60;

export const settingsService = {
  async getAll() {
    return await withCache.get(
      CACHE_KEYS.SETTINGS_ALL,
      () => settingsQueries.getAll(),
      SETTINGS_CACHE_TTL
    );
  },

  async getAllAsMap() {
    // Auto-seed defaults into DB if any keys are missing.
    // Ensures fresh installs always return complete settings.
    await this.ensureDefaultsExist();
    return await withCache.get(
      CACHE_KEYS.SETTINGS_MAP,
      () => settingsQueries.getAllAsMap(),
      SETTINGS_CACHE_TTL
    );
  },

  async getByKey(key) {
    return await settingsQueries.getByKey(key);
  },

  async getValue(key) {
    const setting = await settingsQueries.getByKey(key);
    return setting?.setting_value;
  },

  async getByCategory(category) {
    return await withCache.get(
      CACHE_KEYS.SETTINGS_CATEGORY(category),
      () => settingsQueries.getByCategory(category),
      SETTINGS_CACHE_TTL
    );
  },

  async update(key, value, userId = null) {
    const existing = await settingsQueries.getByKey(key);
    if (!existing) {
      throw new Error(`Setting '${key}' not found`);
    }

    const validated = validateSettingValue(key, value);
    if (!validated.valid) {
      throw new Error(validated.error);
    }

    const result = await settingsQueries.update(key, validated.value, userId);
    await invalidateSettingsCache();
    return result;
  },

  async bulkUpdate(settings, userId = null) {
    if (!Array.isArray(settings) || settings.length === 0) {
      throw new Error('Settings must be a non-empty array');
    }

    const errors = [];
    const validSettings = [];

    for (const item of settings) {
      if (!item.key) {
        errors.push({ item, error: 'Setting key is required' });
        continue;
      }

      const validated = validateSettingValue(item.key, item.value);
      if (!validated.valid) {
        errors.push({ key: item.key, error: validated.error });
        continue;
      }

      validSettings.push({ key: item.key, value: validated.value });
    }

    if (errors.length > 0 && validSettings.length === 0) {
      throw new Error(`Validation failed for all settings: ${errors.map(e => e.error).join(', ')}`);
    }

    const results = await settingsQueries.bulkUpsert(
      validSettings.map(s => ({ ...s, updatedBy: userId }))
    );

    await invalidateSettingsCache();
    return { results, errors };
  },

  async create(key, value, options = {}, userId = null) {
    const validated = validateSettingValue(key, value);
    if (!validated.valid) {
      throw new Error(validated.error);
    }

    const result = await settingsQueries.create({
      key,
      value: validated.value,
      category: options.category || 'general',
      description: options.description,
      updatedBy: userId,
    });

    await invalidateSettingsCache();
    return result;
  },

  async delete(key) {
    const existing = await settingsQueries.getByKey(key);
    if (!existing) {
      throw new Error(`Setting '${key}' not found`);
    }

    const isDefault = DEFAULT_SETTINGS.some(s => s.key === key);
    if (isDefault) {
      throw new Error(`Cannot delete default setting '${key}'`);
    }

    const deleted = await settingsQueries.delete(key);
    await invalidateSettingsCache();
    return deleted;
  },

  async resetToDefaults() {
    const result = await settingsQueries.resetToDefaults();
    await invalidateSettingsCache();
    return result;
  },

  async initializeDefaults() {
    return await settingsQueries.initializeDefaults();
  },

  async ensureDefaultsExist() {
    const missing = await settingsQueries.getMissingKeys();
    if (missing.length > 0) {
      await settingsQueries.initializeDefaults();
      await invalidateSettingsCache();
    }
    return missing.length === 0 ? null : missing;
  },

  async exportSettings() {
    const settings = await settingsQueries.getAll();
    return {
      exportedAt: nowIstIsoString(),
      version: '1.0',
      settings: settings.reduce((acc, s) => {
        acc[s.setting_key] = {
          value: s.setting_value,
          category: s.category,
          description: s.description,
        };
        return acc;
      }, {}),
    };
  },

  async importSettings(importData, options = {}) {
    if (!importData || !importData.settings) {
      throw new Error('Invalid import data format');
    }

    const settingsArray = Object.entries(importData.settings).map(([key, data]) => ({
      key,
      value: data.value,
      category: data.category || 'general',
      description: data.description,
    }));

    return await this.bulkUpdate(settingsArray, options.userId);
  },

  async getCompanyInfo() {
    return await this.getByCategory(SETTING_CATEGORIES.COMPANY);
  },

  async getInvoiceSettings() {
    return await this.getByCategory(SETTING_CATEGORIES.INVOICE);
  },

  async getAlertSettings() {
    return await this.getByCategory(SETTING_CATEGORIES.ALERT);
  },
};

function validateSettingValue(key, value) {
  if (value === undefined || value === null) {
    return { valid: true, value: '' };
  }

  const stringValue = String(value);

  if (key.includes('email') || key === 'company_email') {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (stringValue && !emailRegex.test(stringValue)) {
      return { valid: false, error: `Invalid email format for ${key}` };
    }
  }

  if (key.includes('phone') || key === 'company_phone') {
    const phoneRegex = /^[0-9]{10}$/;
    if (stringValue && !phoneRegex.test(stringValue)) {
      return { valid: false, error: `Invalid phone format for ${key}. Must be 10 digits` };
    }
  }

  if (key.includes('threshold') || key.includes('days') || key.includes('amount')) {
    const num = Number(stringValue);
    if (stringValue && isNaN(num)) {
      return { valid: false, error: `${key} must be a valid number` };
    }
    if (num < 0) {
      return { valid: false, error: `${key} cannot be negative` };
    }
  }

  if (key === 'gst_number') {
    const gstRegex = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[0-9]{1}[Z]{1}[0-9]{1}$/;
    if (stringValue && !gstRegex.test(stringValue)) {
      return { valid: false, error: 'Invalid GST number format' };
    }
  }

  if (key === 'company_pan') {
    const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
    if (stringValue && !panRegex.test(stringValue)) {
      return { valid: false, error: 'Invalid PAN format (e.g. ABCDE1234F)' };
    }
  }

  return { valid: true, value: stringValue };
}

async function invalidateSettingsCache() {
  await withCache.invalidatePattern('settings:*');
}

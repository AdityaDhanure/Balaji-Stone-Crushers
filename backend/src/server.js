import express, { json, urlencoded } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { PORT, NODE_ENV } from './config/env.js';
import errorHandler from './middleware/errorHandler.js';
import authRoutes from './modules/auth/route.js';
import blastRoutes from './modules/blast/route.js';
import vehicleRoutes from './modules/vehicle/route.js';
import dieselRoutes from './modules/diesel/route.js';
import productRoutes from './modules/product/route.js';
import customerRoutes from './modules/customer/route.js';
import billingRoutes from './modules/billing/route.js';
import maintenanceRoutes from './modules/maintenance/route.js';
import employeeRoutes from './modules/employee/route.js';
import attendanceRoutes from './modules/attendance/route.js';
import salaryRoutes from './modules/salary/route.js';
import expenseRoutes from './modules/expense/route.js';
import reportRoutes from './modules/report/route.js';
import notificationRoutes from './modules/notification/route.js';
import settingsRouter from './modules/settings/route.js';
import { createDefaultAdmin } from './modules/auth/service.js';
import { initializeRedis, isRedisConnected } from './utils/cache.js';
import { checkDatabaseConnection } from './config/db.js';

const app = express();

// ─── Middleware ───────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(json());
app.use(urlencoded({ extended: true }));

if (NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// ─── Health Check ─────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: '🏭 Balaji Crushers API is running!',
    redis: isRedisConnected() ? 'connected' : 'disconnected',
  });
});

// ─── Routes (will add here as we build) ───────────────
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/blasts', blastRoutes);
app.use('/api/v1/vehicles', vehicleRoutes);
app.use('/api/v1/diesel', dieselRoutes);
app.use('/api/v1/products', productRoutes);
app.use('/api/v1/customers', customerRoutes);
app.use('/api/v1/billing', billingRoutes);
app.use('/api/v1/maintenance', maintenanceRoutes);
app.use('/api/v1/employees', employeeRoutes);
app.use('/api/v1/employee', employeeRoutes);
app.use('/api/v1/attendance', attendanceRoutes);
app.use('/api/v1/salary', salaryRoutes);
app.use('/api/v1/expenses', expenseRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/settings', settingsRouter);

// ─── Error Handler (must be last) ─────────────────────
app.use(errorHandler);

// ─── Start Server ─────────────────────────────────────
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`🚀 Also available on http://10.0.2.2:${PORT} (Android emulator)`);
  console.log(`📦 Environment: ${NODE_ENV}`);
  
  const dbConnected = await checkDatabaseConnection();
  if (dbConnected) {
    console.log(`✅ Database connected successfully!`);
  } else {
    console.error(`❌ Database connection failed!`);
  }
  
  await initializeRedis();
  await createDefaultAdmin();
});
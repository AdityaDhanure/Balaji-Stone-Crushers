# Balaji Crushers – ERP System Project Report

## Table of Contents
1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Project Architecture](#project-architecture)
4. [Database Schema](#database-schema)
5. [API Modules](#api-modules)
6. [Flutter App Features](#flutter-app-features)
7. [Configuration](#configuration)
8. [Running the Project](#running-the-project)
9. [Development History](#development-history)

---

## Project Overview

**Balaji Crushers** is a full-stack ERP (Enterprise Resource Planning) system built for a stone crusher manufacturing plant. It consists of a **Node.js REST API backend** and a **Flutter Windows/Android mobile app** that together manage all business operations.

### Business Domain
- Stone crusher manufacturing plant — **Bhande Gaon, Khultabad, Maharashtra**
- Products: crushed stone aggregates, dust, GSB, railway ballast
- Vehicle fleet for material transport
- 20+ employees (permanent, contract, daily wagers)

---

## Technology Stack

### Backend
| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 22 (ES Modules) |
| Framework | Express.js v5 |
| Database | PostgreSQL (Neon cloud) |
| Caching | Redis (optional, graceful fallback) |
| Auth | JWT (jsonwebtoken) + bcryptjs |
| Security | Helmet, CORS, Morgan |

### Frontend (Flutter App)
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State Management | Riverpod (StateNotifier) |
| HTTP Client | Dio |
| Navigation | GoRouter |
| Date/Time | IST-normalised utilities |
| Target Platforms | Windows (desktop), Android |

---

## Project Architecture

### Directory Structure
```
9.Balaji-Crushers/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   ├── db.js                  # PostgreSQL pool
│   │   │   └── env.js                 # Environment variables
│   │   ├── middleware/
│   │   │   ├── auth.js                # JWT middleware
│   │   │   ├── cacheMiddleware.js     # Redis cache helpers
│   │   │   └── errorHandler.js        # Global error handler
│   │   ├── modules/
│   │   │   ├── auth/                  # Login / JWT
│   │   │   ├── blast/                 # Drilling operations
│   │   │   ├── vehicle/               # Vehicle fleet
│   │   │   ├── diesel/                # Fuel inventory
│   │   │   ├── product/               # Products & rates
│   │   │   ├── customer/              # Customer CRM
│   │   │   ├── billing/               # Invoices & payments
│   │   │   ├── maintenance/           # Equipment service
│   │   │   ├── employee/              # HR management
│   │   │   ├── attendance/            # Daily attendance
│   │   │   ├── salary/                # Payroll
│   │   │   ├── expense/               # General expenses
│   │   │   ├── report/                # Analytics
│   │   │   ├── notification/          # Alerts
│   │   │   └── settings/              # App settings
│   │   ├── utils/
│   │   │   └── cache.js               # Redis keys & helpers
│   │   ├── init-*.js                  # Table initialisation scripts
│   │   └── server.js                  # Entry point
│   ├── sql/                           # SQL schemas
│   ├── .env                           # Environment config (git-ignored)
│   └── package.json
│
└── balaji_crushers_app/               # Flutter app
    ├── lib/
    │   ├── core/
    │   │   ├── constants/             # AppColors, ApiConstants
    │   │   ├── services/              # ApiClient, SettingsService
    │   │   └── utils/                 # ISTDateUtils, formatters
    │   ├── features/
    │   │   ├── attendance/            # Attendance list, bulk mark, bulk delete
    │   │   ├── auth/                  # Login screen
    │   │   ├── billing/               # Invoices, payments, PDF
    │   │   ├── blast/                 # Blast tracking, trips, expenses
    │   │   ├── customer/              # CRM, wallet
    │   │   ├── dashboard/             # Overview cards
    │   │   ├── diesel/                # Fuel purchase & consumption
    │   │   ├── employee/              # HR, documents, leaves
    │   │   ├── expense/               # Manual expenses, unified view
    │   │   ├── maintenance/           # Records, schedule, vendors, parts
    │   │   ├── product/               # Products, rates, production
    │   │   ├── profile/               # User profile
    │   │   ├── report/                # Reports with tabs
    │   │   ├── salary/                # Payroll, slips, advances
    │   │   ├── settings/              # Company info, invoice, alerts
    │   │   └── vehicle/               # Fleet, expiry tracking
    │   ├── shared/
    │   │   └── widgets/               # TopBar, common components
    │   └── main.dart
    └── pubspec.yaml
```

### API Base URL
```
http://localhost:5000/api/v1/
```

### Backend Module Pattern
Every module follows: `route.js → controller.js → service.js → query.js`

---

## Database Schema

### Core Tables Summary

| # | Table Group | Key Tables |
|---|-------------|-----------|
| 1 | Users | `users` |
| 2 | Blast | `blasts`, `blast_trips`, `blast_expenses` |
| 3 | Vehicles | `vehicles`, `vehicle_daily_usage` |
| 4 | Diesel | `diesel_purchases`, `diesel_consumption` |
| 5 | Products | `product_categories`, `products`, `crushing_rates`, `daily_production`, `production_rate_snapshots` |
| 6 | Customers | `customers`, `customer_contacts`, `customer_wallets` |
| 7 | Billing | `invoices`, `invoice_items`, `invoice_payments` |
| 8 | Employees | `departments`, `employees`, `employee_documents`, `employee_leaves` |
| 9 | Attendance | `attendance`, `shift_types`, `employee_shifts` |
| 10 | Salary | `salary_periods`, `salary_slips`, `salary_advances`, `salary_deductions` |
| 11 | Maintenance | `equipment`, `maintenance_records`, `maintenance_schedule`, `maintenance_vendors`, `spare_parts`, `maintenance_record_parts` |
| 12 | Expenses | `expense_categories`, `expenses`, `expense_recurring` |
| 13 | System | `notifications`, `app_settings` |

### Default Expense Categories (seeded)
Site Operations, Electricity Bill, Fuel & Diesel, Repairs & Maintenance, Office Supplies, Salary Advances, Insurance, Rent, Phone & Internet, **Royalty**, Miscellaneous

---

## API Modules

| # | Module | Route | Notable Endpoints |
|---|--------|-------|-------------------|
| 1 | Auth | `/api/v1/auth` | `POST /login` |
| 2 | Blasts | `/api/v1/blasts` | CRUD, `POST /:id/complete`, `POST /:id/reopen` |
| 3 | Blast Trips | (nested) | CRUD trips + grouped-by-date |
| 4 | Blast Expenses | (nested) | CRUD expenses |
| 5 | Vehicles | `/api/v1/vehicles` | CRUD, document expiry, odometer |
| 6 | Diesel | `/api/v1/diesel` | Purchases, consumption, stock |
| 7 | Products | `/api/v1/products` | Products, rates, production |
| 8 | Customers | `/api/v1/customers` | CRM, contacts, wallet |
| 9 | Billing | `/api/v1/billing` | Invoices, items, payments |
| 10 | Employees | `/api/v1/employees` | HR, departments, docs, leaves |
| 11 | Attendance | `/api/v1/attendance` | Mark, bulk, `DELETE /by-date/:date` |
| 12 | Salary | `/api/v1/salary` | Periods, slips, advances, deductions |
| 13 | Expenses | `/api/v1/expenses` | Manual expenses, categories, unified view |
| 14 | Maintenance | `/api/v1/maintenance` | Equipment, records, schedule, vendors, parts |
| 15 | Reports | `/api/v1/reports` | Overview, sales, expenses, P&L, yearly trend |
| 16 | Notifications | `/api/v1/notifications` | Alerts, read/unread |
| 17 | Settings | `/api/v1/settings` | Company info, invoice config, bulk update |

---

## Flutter App Features

### 1. Blast Management
- Active blast hero card with aggregated trip/expense totals
- **Instant state transitions**: marking complete immediately shows "Start New Blast" UI
- Add trips (by vehicle type/number) and expenses per blast
- Blast expense types: Labour, Material, Machinery, Transport, Loading, Drilling, **Royalty**, Other
- Mark complete / reopen with optimistic UI updates
- History list with detail drill-down
- Safe ID parsing (`_safeId`) prevents `FormatException` crashes

### 2. Attendance
- Daily attendance list with "Quick Mark" and "All Attendance" tabs
- Bulk mark present/absent for multiple employees
- **Delete All** button clears all attendance for a selected date (with confirmation dialog)
- IST-normalised date handling throughout

### 3. Expense Management
- Manual expense entry with DB-driven category picker (incl. Royalty)
- Unified expense view aggregates 9 sources: manual, diesel, blast, royalty, maintenance, salary, advances, production
- Add/Edit/Delete with payment mode, vendor, reference, date

### 4. Payroll & Salary
- Salary periods with lock/unlock
- Bulk salary slip generation from attendance data
- Pro-rata calculation: basic, HRA (10%), allowances (5%), PF (12%), TDS, professional tax
- Salary advance request, approval, and repayment tracking
- PDF salary slip export

### 5. Billing
- Create/edit invoices with line items
- Partial payment tracking, payment history
- Invoice status auto-updates (draft → partial → paid)
- PDF invoice generation

### 6. Maintenance
- Equipment and vehicle maintenance records
- Vendor management
- Spare parts inventory with stock levels
- Maintenance schedule tracking

### 7. Settings
- Company info (name, address, GST, PAN, bank details)
- Invoice configuration (prefix, footer, terms, tax rate)
- Alert thresholds (diesel, document expiry, maintenance)
- Powered by `app_settings` table with bulk update

### 8. Other Modules
- **Dashboard**: business overview cards
- **Vehicles**: fleet, document expiry alerts, odometer
- **Diesel**: purchase & consumption tracking
- **Customers**: CRM with wallet/advance system
- **Products**: catalog, rate history, daily production
- **Employees**: HR with documents, leaves
- **Reports**: 5-tab report screen (overview, sales, expenses, P&L, yearly)

---

## Configuration

### Backend `.env`
```env
PORT=5000
NODE_ENV=development
DATABASE_URL=postgresql://<user>:<pass>@<host>/balaji-crushers?sslmode=require
JWT_SECRET=<secret>
JWT_EXPIRES_IN=7d
REDIS_URL=redis://localhost:6379
CACHE_TTL=300
```

### Flutter API Base
Set in `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://localhost:5000/api/v1';
```

### Database
- Hosted on **Neon** (cloud PostgreSQL), region: `ap-southeast-1`
- Requires SSL. Connection pool via `pg`.

### Caching
- **Redis** (optional). Falls back gracefully if unavailable.
- TTL: 300 s. Cache invalidated per-module on writes.

---

## Running the Project

### Backend
```bash
cd backend
npm install
npm run dev        # development with nodemon
npm start          # production
```

Default login: `admin` / `admin123`

### Initialise Database (first time)
```bash
node src/init-blast-tables.js
node src/init-vehicle-tables.js
node src/init-diesel-tables.js
node src/init-product-tables.js
node src/init-customer-tables.js
node src/init-billing-tables.js
node src/init-employee-tables.js
node src/init-attendance-tables.js
node src/init-salary-tables.js
node src/init-maintenance-tables.js
node src/init-expense-tables.js
node src/init-notification-tables.js
```

### Flutter App
```bash
cd balaji_crushers_app
flutter pub get
flutter run -d windows   # Windows desktop
flutter run              # Android (device/emulator)
```

---

## Development History

### v1.0 — Backend Foundation
- Full REST API: 15 backend modules, 36+ route groups
- JWT auth, Redis caching, PostgreSQL on Neon
- 30+ database tables with foreign keys and default seeding
- Auto-numbering: blasts, invoices, employees, customers, expenses

### v1.1 — Flutter App (Initial)
- Flutter project scaffolded targeting Windows + Android
- Riverpod state management, GoRouter navigation, Dio HTTP client
- All 16 feature modules implemented with screens, providers, repositories
- Premium dark-mode UI with glassmorphism cards

### v1.2 — Module Refinements
- Billing: edit invoice flow, payment history, PDF export
- Maintenance: vendor management, spare parts inventory
- Salary: bulk generation, PDF slips, advance repayment tracking
- Reports: consolidated 5-tab report screen

### v1.3 — Attendance & Blast Stabilisation (May 2026)
- **Attendance bulk delete**: `DELETE /attendance/by-date/:date` backend endpoint + Flutter "Delete All" UI with confirmation dialog
- **Blast state management rewrite**:
  - `getActiveBlast` backend fix: returns `data: null` explicitly (was returning `undefined`, causing JSON envelope to be misread as blast object)
  - Flutter `getActiveBlast()` repo: validates `envelope['data']` directly — prevents `{"success":true}` being mistaken for a blast
  - `completeBlast`: clears `activeBlast` immediately (instant "Start New Blast" UI), reloads list from server for accurate aggregated values
  - `reopenBlast`: sources optimistic blast from `state.blasts` list (not `activeBlast` which is null post-completion)
  - `_safeId()` helper: safe `int` extraction from `dynamic` (handles `int`, `String`, `null`) — eliminates `FormatException` on navigation
- **Royalty expense category**: added to blast expense form + inserted into `expense_categories` DB table
- `.gitignore` cleanup: proper Flutter and Node.js ignores

---

*Last updated: May 2026*
*Project: Balaji Crushers ERP System*
*Version: 1.3.0*

# Balaji Crushers ERP

Balaji Crushers ERP is a Flutter + Node.js/PostgreSQL system for crusher operations, including billing, attendance, salary, expenses, diesel, vehicles, maintenance, customers, products, reports, and settings.

## Project Structure

```text
.
├── backend/
│   ├── src/
│   │   ├── server.js
│   │   ├── config/
│   │   ├── middleware/
│   │   ├── modules/
│   │   ├── utils/
│   │   ├── migrations/
│   │   └── scripts/
│   │       ├── admin/
│   │       └── init/
│   ├── scripts/
│   │   ├── diagnostics/
│   │   ├── tests/
│   │   ├── auth/
│   │   └── legacy-db/
│   ├── sql/
│   ├── package.json
│   └── .env.example
└── balaji_crushers_app/
    └── lib/
```

Production source lives under `backend/src`. Local debug/test/helper scripts are kept under `backend/scripts` and are ignored by Git.

## What To Commit

Commit these production files:

- `backend/src/server.js`
- `backend/src/config/**`
- `backend/src/middleware/**`
- `backend/src/modules/**`
- `backend/src/utils/**`
- `backend/src/scripts/init/**`
- `backend/src/scripts/admin/**`
- `backend/src/migrations/**`
- `backend/package.json`
- `backend/package-lock.json`
- `backend/.env.example`
- `balaji_crushers_app/lib/**`
- Flutter project files such as `pubspec.yaml` and `pubspec.lock`

Do not commit:

- `.env` or any real secret file
- `node_modules/`
- Flutter build output
- logs
- `nul`
- local debug/test scripts under `backend/scripts/diagnostics`, `backend/scripts/tests`, `backend/scripts/auth`, or `backend/scripts/legacy-db`

## Backend Setup

```bash
cd backend
npm ci
cp .env.example .env
```

Update `.env` with production values:

```text
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://USER:PASSWORD@HOST:PORT/DB_NAME
JWT_SECRET=replace-with-strong-secret
JWT_EXPIRES_IN=7d
FRONTEND_URL=https://your-production-frontend-url
REDIS_URL=redis://your-redis-host:6379
```

Never commit the real `.env`.

## Production Database Plan

For real go-live, create a fresh production PostgreSQL database. Do not reuse or clean the development database.

Use the schema/init scripts under:

```text
backend/src/scripts/init/
```

Use database migrations under:

```text
backend/src/migrations/
```

Recommended production flow:

1. Create a fresh production database.
2. Configure `backend/.env` with the production `DATABASE_URL`.
3. Run required table/init scripts in a controlled order.
4. Run required migrations from `backend/src/migrations`.
5. Create the real admin user and remove/demo-disable default credentials.
6. Enter real company settings, GST, invoice settings, bank details, alert thresholds, and salary settings.
7. Add opening balances for customers, diesel stock, advances, odometer readings, and other real starting values.
8. Clear cache before go-live.
9. Run full module smoke tests.

## Backend Commands

```bash
npm start
```

Available package scripts:

```bash
npm run init:blasts
npm run init:vehicles
npm run init:diesel
npm run migrate
npm run cache:clear-salary
```

Other init scripts can be run directly from `backend/src/scripts/init` when preparing a fresh database.

## Frontend Setup

```bash
cd balaji_crushers_app
flutter pub get
```

Configure the app API base URL for the production backend before building a release.

## Production Checklist

- Fresh production DB created.
- Schema/init scripts applied.
- Required migrations applied.
- Real company settings configured.
- Real users created with strong passwords.
- Demo/test data excluded.
- Opening balances entered.
- Backend running with production `.env`.
- Frontend points to production backend.
- Redis/cache cleared.
- Billing, attendance, salary, reports, expense, diesel, vehicle, and maintenance flows smoke-tested.
- Backups configured before go-live.

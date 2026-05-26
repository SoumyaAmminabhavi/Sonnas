# Supabase Integration & Setup Guide

This guide explains how to connect the application to the company’s shared Supabase database instead of a local database.

---

# Step 1: Gather Required Credentials

> [!IMPORTANT]
> If you only received:
>
> - `NEXT_PUBLIC_SUPABASE_URL`
> - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
>
> You still **must** get the `DATABASE_URL`.
>
> The application uses **Prisma ORM** for all database operations, and Prisma requires a direct PostgreSQL connection.

Ask your team lead or administrator for the following credentials:

## Required Credentials

- `DATABASE_URL`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

---

# Step 2: Update `.env`

Replace the values inside your `.env` file:

```env
# PostgreSQL Database URL
DATABASE_URL="postgresql://postgres:[YOUR_DB_PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"

# Supabase Public Credentials
NEXT_PUBLIC_SUPABASE_URL="https://[PROJECT_REF].supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="[YOUR_ANON_KEY]"

# Supabase Server Secret
SUPABASE_SERVICE_ROLE_KEY="[YOUR_SERVICE_ROLE_KEY]"
```

---

# Step 3: Setup Database Schema

## Option A — Fresh Database

If the database is empty/new:

### Run migrations

```bash
npm run db:migrate
```

OR

### Push schema directly

```bash
npm run db:push
```

---

## Option B — Existing Production Database

If the database already contains tables and production data:

```bash
npm run postinstall
```

> Do NOT run migrations or push commands on an existing production database unless instructed.

---

# Step 4: Seed Database (Optional)

If default menu/categories/settings are required:

```bash
npx tsx prisma/seed.ts
```

---

# Step 5: Start Development Server

```bash
npm run dev
```

The application will now use the shared Supabase database and storage.

---

# Credentials to Ask From Team Lead

## Mandatory
# PostgreSQL Database Connection
DATABASE_URL="postgresql://postgres:YOUR_DATABASE_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres"

# Supabase Public Credentials
NEXT_PUBLIC_SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="YOUR_SUPABASE_ANON_KEY"

# Supabase Server Secret
SUPABASE_SERVICE_ROLE_KEY="YOUR_SUPABASE_SERVICE_ROLE_KEY"

## Helpful Additional Information

- Is the database fresh or production/live?
- Should migrations be run?
- Should connection pooler be used?
- Existing storage bucket names
- RLS (Row Level Security) policies info
- Any existing Prisma migration history
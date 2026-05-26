# Supabase Integration & Setup Guide

This guide details how to switch the application's database operations from a local database instance to the company's shared Supabase database.

---

## Step 1: Gather Supabase Credentials

> [!IMPORTANT]
> **If you were only provided `NEXT_PUBLIC_SUPABASE_URL` and the Publishable/`anon` Key:**
> You **still strictly need the Database Connection String (`DATABASE_URL`)**.
> * **Why?** The application uses **Prisma ORM** on the server side to read/write all data (menu, orders, sessions, etc.). Prisma interacts directly with the database using TCP connection protocols and cannot run over the HTTP client SDK alone.
> * **Action Required**: Ask your project administrator or team lead for the **PostgreSQL database connection string** (and the password for it).
>
> Once you have all the pieces, retrieve the following values from the **Supabase Dashboard**:

### 1. Database Connection String (`DATABASE_URL`)
* Navigate to **Project Settings** (gear icon) ➔ **Database**.
* Under the **Connection string** section, select **URI** and copy the connection string.
* **Direct Connection (Port 5432)**: Recommended for running migrations and local development.
* **Connection Pooler (Port 6543)**: Recommended for serverless application runtimes in production. Append `?pgbouncer=true&connection_limit=1` if using transactional pooling.
* Replace the `[YOUR-PASSWORD]` placeholder in the URI string with the actual password of the database.

### 2. API Keys & Endpoints
* Navigate to **Project Settings** ➔ **API**.
* Copy the **Project URL**. This is your `NEXT_PUBLIC_SUPABASE_URL`.
* Copy the **`anon` (public)** API Key. This is your `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
* Copy the **`service_role` (secret)** API Key. This is your server-side `SUPABASE_SERVICE_ROLE_KEY` (required for bypassing row-level security and handling system-level uploads like WhatsApp media storage).

---

## Step 2: Update the Environment Variables

Open the `.env` file in the root of the project and update the keys with the gathered credentials:

```env
# Database connection string
DATABASE_URL="postgresql://postgres:[YOUR_DB_PASSWORD]@db.[COMPANY_REF].supabase.co:5432/postgres"

# Supabase Keys
NEXT_PUBLIC_SUPABASE_URL="https://[COMPANY_REF].supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="[YOUR_COMPANY_ANON_KEY]"
SUPABASE_SERVICE_ROLE_KEY="[YOUR_COMPANY_SERVICE_ROLE_KEY]"
```

---

## Step 3: Align the Database Schema

Depending on the state of the target Supabase database, choose the appropriate command below:

### Option A: Deploy Schema to a Fresh Database
If the company database is new/empty and needs all the tables created:

* **Deploy Migrations (Recommended for consistency)**:
  ```bash
  npm run db:migrate
  ```
  *(Applies all existing migration files to the database using `prisma migrate deploy`)*

* **Direct Push (Best for fast prototyping)**:
  ```bash
  npm run db:push
  ```
  *(Pushes the Prisma schema directly to the database using `prisma db push`)*

### Option B: Connect to an Existing Database
If the database already contains tables and live/production data, **do not** run migration or push commands. Simply regenerate the Prisma client locally to align types:

```bash
npm run postinstall
```
*(Runs `prisma generate` to update the local type-safe client)*

---

## Step 4: Seed the Database (Optional)

If the database is fresh and you need to load the default menu items, categories, and settings:

```bash
npx tsx prisma/seed.ts
```

---

## Step 5: Start the Application

Once variables are configured and the client is regenerated, start the local development server:

```bash
npm run dev
```

The application will now perform all read/write database actions and handle media storage directly on the company's shared Supabase instance.

DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT].supabase.co:5432/postgres"

NEXT_PUBLIC_SUPABASE_URL="https://[PROJECT].supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="[ANON_KEY]"
SUPABASE_SERVICE_ROLE_KEY="[SERVICE_ROLE_KEY]"
# Connecting Prepzi to Supabase — step by step

This guide moves the site from the local SQLite database to Supabase
(PostgreSQL) and explains how the code keeps your **5 GB free-tier egress**
safe. Follow the steps in order — total time ≈ 20 minutes.

---

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) → **New project**.
2. Pick a name (e.g. `prepzi`), a region close to your visitors, and a strong
   **database password** (save it — you'll need it below).

## 2. Copy the two connection strings

Supabase → **Project Settings → Database → Connection string → URI**:

| String | Port | Used for |
| --- | --- | --- |
| **Connection pooling** | 6543 | `DATABASE_URL` — what the app uses at runtime |
| **Direct connection** | 5432 (or 5433) | `DIRECT_URL` — what Prisma uses for migrations |

They look like:

```
postgresql://postgres.<project-ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres?pgbouncer=true
postgresql://postgres.<project-ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres
```

## 3. Switch the Prisma schema to PostgreSQL

```bash
cp prisma/schema.supabase.prisma prisma/schema.prisma
```

The Supabase variant is identical to the SQLite one except
`provider = "postgresql"` and it declares `directUrl = env("DIRECT_URL")`.

## 4. Fill in your environment file

Edit `.env` (never committed — `.gitignore` already excludes `.env*`):

```dotenv
DATABASE_URL="postgresql://postgres.<ref>:<pw>@aws-0-<region>.pooler.supabase.com:6543/postgres?pgbouncer=true"
DIRECT_URL="postgresql://postgres.<ref>:<pw>@aws-0-<region>.pooler.supabase.com:5432/postgres"

# Admin portal password — lives only here / in your host's secret vault.
ADMIN_PASSWORD="your-secret-admin-password"
```

## 5. Create the tables and move your data

```bash
# a) (optional) export what you created in local SQLite first
node scripts/export-data.mjs          # writes data-export.json

# b) create the tables in Supabase
npx prisma db push

# c) load subjects / files / settings into Supabase
node scripts/import-to-supabase.mjs

# d) seed default settings + the admin password hash
ADMIN_PASSWORD="your-secret-admin-password" node scripts/seed-site.mjs
```

The admin password is stored **only as a salted scrypt hash** in the `Setting`
table (`admin_password_hash`). Nobody inspecting the Supabase dashboard can
read the plain password, and it is never hardcoded anywhere in the repo.

## 6. Deploy

Deploy anywhere Node runs (Vercel is the easiest for Next.js):

1. Push this repo to GitHub.
2. Import it on Vercel → add the **same three env vars**
   (`DATABASE_URL`, `DIRECT_URL`, `ADMIN_PASSWORD`) in
   Project → Settings → Environment Variables.
3. Build command `npm run build`, output is the default (standalone).
4. Open `https://your-domain/admin` → enter the password → add subjects/files.

---

## How this codebase protects your egress quota

The refactored architecture means a normal visitor **never triggers a live
Supabase query**:

| Layer | What it does |
| --- | --- |
| **Static pages** | `/`, `/about`, `/privacy`, `/terms`, and all six Notes/Topical/Yearly pages are prerendered at build time (`generateStaticParams`). Visitors get prebuilt HTML — no DB call at all. |
| **Cached data layer** | `src/lib/queries.ts` wraps every query in `unstable_cache` with tags (`subjects`, `files`, `settings`). Even dynamically-rendered pages (e.g. `/subject/[id]`) hit the in-memory/framework cache, not Postgres. |
| **Tag revalidation** | Every admin write (create / edit / delete / settings) calls `revalidateTag(...)` **once**, which regenerates the affected cache. No polling, no per-visitor queries. |
| **Light list queries** | All list selects fetch identification columns only. The heavy `PaperFile.data` (PDF binary) column is **never** selected for lists — bytes are read only by `/api/files/[id]` when someone actually opens/downloads a file. |
| **Immutable PDF caching** | PDF responses send `Cache-Control: public, max-age=86400, immutable`, so repeat views/downloads come from the browser/CDN instead of re-reading the database. |

Net effect: Supabase egress ≈ (one query per admin action) + (PDF bytes only
on first download per visitor). Page views cost **zero** egress.

### Extra tips to stay far below 5 GB

- Prefer **External link** entries (Admin → Add content → External link) for
  big PDFs hosted elsewhere (Google Drive, Supabase Storage, S3…). Linked
  files cost **zero** database egress — the visitor's browser fetches them
  straight from the source.
- If you later outgrow storing PDFs in Postgres, move binaries to
  **Supabase Storage** (its CDN serves downloads without going through your
  server) and keep only the URL in `PaperFile.externalUrl`.
- Set `revalidate` values conservatively — the current setup only refreshes
  when *you* change content in admin, which is exactly what you want.

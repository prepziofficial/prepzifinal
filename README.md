# Prepzi — One Stop Study Guide

Cambridge IGCSE & AS/A Level topical papers, notes and yearly past papers.
Every resource is an **external link** (e.g. Google Drive) — Prepzi stores no
files at all, which keeps hosting and database egress essentially free.

Built with **Next.js 16 (App Router)**, TypeScript, Tailwind 4, shadcn/ui,
**Prisma** and **Supabase (PostgreSQL)**.

## Project structure

```
src/
  app/
    page.tsx                    → Dashboard (one stop study guide)
    notes/[level]/page.tsx      → "Choose a subject" — Notes (igcse | alevel)
    topical/[level]/page.tsx    → "Choose a subject" — Topical Past Papers
    yearly/[level]/page.tsx     → "Choose a subject" — Yearly Past Papers
    subject/[id]/page.tsx       → Subject page (?go=notes|topical|yearly)
    admin/page.tsx              → Admin portal (password-protected)
    about|privacy|terms         → Info pages
    icon.png / apple-icon.png / favicon.ico → browser-tab logo
    api/
      subjects, files           → public JSON data
      files/[id]                → 302 redirect to the resource's external link
      settings                  → editable site settings (footer, socials, email)
      admin/{auth,files,subjects} → password-guarded writes
  components/prepzi/
    dashboard.tsx               → hero, library sections, how-it-works
    kind-pages.tsx              → KindPage + SubjectPage (search, open link, ad gate)
    navbar.tsx                  → tabs + dropdowns, glow underline, social icons
    footer.tsx                  → admin-editable footer
    admin-portal.tsx            → add / edit / delete links + site settings
    ad-gate.tsx                 → 3-second ad popup + AD_REDIRECT_URL
    hero-scene.tsx              → pure-code 3D hero animation (desktop only)
  lib/
    queries.ts                  → cached server data layer (unstable_cache + tags)
    admin-auth.ts               → scrypt-hashed password verification
    prepzi-types.ts             → shared types & labels
prisma/
  schema.prisma                 → PostgreSQL schema (Supabase)
  migrations/                   → applied migrations
netlify.toml                    → Netlify build config
```

## Local development

```bash
npm install
cp .env.example .env            # fill in your Supabase URLs + admin password
npx prisma generate
npm run dev                     # http://localhost:3000
```

## Admin portal

Open `/admin`. The password is asked on **every** visit (nothing is stored in
the browser). Verification uses, in order:

1. `ADMIN_PASSWORD` env var (recommended in production — lives in the host's
   secret vault), or
2. a **salted scrypt hash** stored in the `Setting` table. The database can
   never reveal the plain password.

## Hosting on Netlify (step by step)

1. **Push the code to GitHub**
   ```bash
   git init && git add . && git commit -m "Prepzi"
   git remote add origin https://github.com/<you>/prepzi.git
   git push -u origin main
   ```
   (`.gitignore` already excludes secrets, node_modules and local-only files.)

2. **Netlify → Add new site → Import an existing project** → pick the repo.

3. **Set environment variables** (Site configuration → Environment variables):
   | Key | Value |
   | --- | --- |
   | `DATABASE_URL` | Supabase **pooler** URL (port `6543`, `?pgbouncer=true`) |
   | `DIRECT_URL`   | Supabase **session pooler** URL (port `5432`) |
   | `ADMIN_PASSWORD` | your admin portal password |

4. **Deploy.** `netlify.toml` already sets the build command
   (`npx prisma generate && npx next build`) and the official
   `@netlify/plugin-nextjs` runtime — pages, API routes and ISR all work.

5. **Apply future schema changes** from your machine (Netlify only runs
   `migrate deploy`-style reads):
   ```bash
   npx prisma migrate dev --name <change>     # against Supabase
   git push                                    # Netlify rebuilds
   ```

Other hosts (Vercel, Render, Railway, a VPS) work too — the same three env
vars are all that is needed. `output: "standalone"` is used everywhere except
Netlify, where it is disabled automatically.

## How the site protects your Supabase egress quota

- Every public page is **server-rendered from a cached data layer**
  (`src/lib/queries.ts`, `unstable_cache`). A regular visitor's page view
  performs **zero live database queries**.
- All list queries select **light columns only**.
- Because every resource is an external link, students download files straight
  from Google Drive — **no file bytes ever pass through Prepzi or Supabase**.
- Every admin write (create/edit/delete/settings) calls `revalidateTag(...)`,
  which refreshes the caches **once, on demand** — no polling, no per-visitor
  queries.

## Useful commands

```bash
npm run dev          # dev server on :3000
npx next build       # production build
npx prisma studio    # inspect the database
npm run lint         # eslint
```

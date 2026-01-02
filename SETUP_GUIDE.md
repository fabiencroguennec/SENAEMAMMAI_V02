# Nuxt 3 Setup Guide - Senaemammai V02

Follow these instructions to initialize the frontend project `senaemammai-front`.

## 1. Project Initialization

Open your terminal in the parent directory (`/Users/fabien/Site/SENAEMAMMAI/SENAEMAMMAI_V02` or whichever structure you prefer, but usually we keep the repo root clean).

```bash
# Initialize Nuxt 3 project
npx nuxi@latest init senaemammai-front

# Enter the directory
cd senaemammai-front
```

## 2. Install Dependencies

We need the following key modules:
- `@nuxtjs/supabase`: For effortless Supabase Auth & Database interaction.
- `@nuxtjs/tailwindcss`: For utility-first styling.
- `gsap`: For generic animations and the Visual Builder.

```bash
# Install modules
npm install @nuxtjs/supabase @nuxtjs/tailwindcss gsap

# Install dev dependencies if needed (usually handled by nuxi init)
npm install
```

## 3. Configuration

### Edit `nuxt.config.ts`

Open `nuxt.config.ts` and add the modules:

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  modules: [
    '@nuxtjs/tailwindcss',
    '@nuxtjs/supabase'
  ],
  supabase: {
    redirect: false, // Set to true later if you want strictly protected routes by default
  },
  // We don't need a specific module for GSAP, we can import it directly in components.
  // Or use a plugin if global registration is needed.
  devtools: { enabled: true }
})
```

### Environment Variables (.env)

Create a `.env` file in the root of `senaemammai-front`:

```bash
touch .env
```

Add your Supabase credentials (get these from your Supabase Dashboard > Project Settings > API):

```ini
SUPABASE_URL="https://your-project-ref.supabase.co"
SUPABASE_KEY="your-anon-key"
```

## 4. First Run

Start the development server:

```bash
npm run dev
```

Visit `http://localhost:3000` to see your generic Nuxt welcome page.

## 5. Next Steps

- Proceed to implement the **Visual Builder** architecture as described in `docs/VISUAL_BUILDER_ARCH.md`.
- Run the SQL script from `database/schema.sql` in your Supabase SQL Editor to prepare the data structure.

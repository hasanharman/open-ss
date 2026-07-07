# OpenSS — Website

Marketing/demo page for the OpenSS macOS app. Built with Next.js App Router,
Tailwind CSS v4, and a faux macOS desktop that demonstrates the actual product
flow:

1. Click the OpenSS menu bar icon.
2. Hover window previews in the picker.
3. Click a window to start capture.
4. See the stitched long screenshot result.

## Develop

```bash
cd website
pnpm install
pnpm dev
```

## Build

```bash
pnpm build
pnpm start
```

## Structure

```text
website/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   └── globals.css
├── components/
│   ├── MacMenuBar.tsx
│   ├── Hero.tsx
│   ├── TimerWidget.tsx
│   └── AppWindow.tsx
└── lib/site.ts
```

Set `NEXT_PUBLIC_SITE_URL` in production so metadata and OpenGraph URLs match
the deployed domain.

## Deploy on Vercel

The repo includes Vercel config for both common setups:

- `website/vercel.json` if the Vercel Project Root Directory is `website`
- `../vercel.json` if the Vercel Project Root Directory is the repository root

Recommended project settings:

- Framework Preset: Next.js
- Root Directory: `website`
- Install Command: `pnpm install --frozen-lockfile`
- Build Command: `pnpm build`
- Output Directory: `.next`

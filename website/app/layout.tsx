import type { Metadata } from "next";
import "./globals.css";

// Resolve the canonical URL: a custom domain if set, otherwise Vercel's
// production URL, falling back to the intended domain for local builds.
const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "https://open-ss.app");

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "OpenSS — Long screenshots from your Mac menu bar",
  description:
    "A native macOS menu bar app for long screenshots. Pick a window, capture the full page, crop browser chrome, and save a single PNG. Free and open source.",
  keywords: [
    "long screenshot macOS",
    "scrolling screenshot",
    "macOS screenshot app",
    "menu bar screenshot",
    "OpenSS",
    "Swift app",
  ],
  authors: [{ name: "Hasan Harman" }],
  openGraph: {
    title: "OpenSS — Long screenshots from your menu bar",
    description:
      "Native macOS menu bar app for full-page window screenshots. Pick a tab, auto-scroll, crop browser chrome, save one PNG.",
    url: siteUrl,
    siteName: "OpenSS",
    images: [{ url: "/icon.png", width: 500, height: 500, alt: "OpenSS" }],
    type: "website",
  },
  twitter: {
    card: "summary",
    title: "OpenSS",
    description:
      "Native macOS menu bar long screenshot app. Free and open source.",
    images: ["/icon.png"],
  },
  icons: {
    icon: [
      { url: "/favicon.png", type: "image/png", sizes: "500x500" },
      { url: "/icon.png", type: "image/png", sizes: "500x500" },
    ],
    apple: [{ url: "/icon.png", sizes: "500x500", type: "image/png" }],
    shortcut: ["/favicon.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

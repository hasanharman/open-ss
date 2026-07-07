import { DesktopShell } from "@/components/DesktopShell";
import { site } from "@/lib/site";

// Fetched at build time (and revalidated hourly when served by a Node runtime).
async function getStarCount(): Promise<number | null> {
  try {
    const path = site.repo.replace("https://github.com/", "");
    const res = await fetch(`https://api.github.com/repos/${path}`, {
      headers: { Accept: "application/vnd.github+json" },
      next: { revalidate: 3600 },
    });
    if (!res.ok) return null;
    const data = await res.json();
    return typeof data.stargazers_count === "number"
      ? data.stargazers_count
      : null;
  } catch {
    return null;
  }
}

export default async function Home() {
  const stars = await getStarCount();
  return <DesktopShell stars={stars} />;
}

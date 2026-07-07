"use client";

import { useState } from "react";
import { MacMenuBar } from "./MacMenuBar";
import { Hero } from "./Hero";

export type View = "picker" | "result" | "closed";

/**
 * Owns the menu-bar demo state so the picker and screenshot result stay in
 * sync, like the real OpenSS capture flow.
 */
export function DesktopShell({ stars }: { stars: number | null }) {
  const [view, setView] = useState<View>("picker");

  return (
    <main>
      <MacMenuBar
        active={view === "picker"}
        onTimerClick={() =>
          setView((v) => (v === "picker" ? "closed" : "picker"))
        }
      />
      <Hero
        stars={stars}
        view={view}
        onOpenApp={() => setView("result")}
        onCloseWidget={() => setView("closed")}
        onCloseApp={() => setView("picker")}
      />
    </main>
  );
}

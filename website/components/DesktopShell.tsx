"use client";

import { useState } from "react";
import { MacMenuBar } from "./MacMenuBar";
import { Hero } from "./Hero";
import { defaultExample, type CaptureExample } from "@/lib/examples";

export type View = "picker" | "result" | "closed";

/**
 * Owns the menu-bar demo state so the picker and screenshot result stay in
 * sync, like the real OpenSS capture flow.
 */
export function DesktopShell({ stars }: { stars: number | null }) {
  const [view, setView] = useState<View>("picker");
  const [example, setExample] = useState<CaptureExample>(defaultExample);

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
        example={example}
        onOpenApp={(nextExample) => {
          setExample(nextExample);
          setView("result");
        }}
        onCloseWidget={() => setView("closed")}
        onCloseApp={() => setView("picker")}
      />
    </main>
  );
}

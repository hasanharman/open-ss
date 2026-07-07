"use client";

import { Github, Star, Heart, Coffee } from "lucide-react";
import { AppleLogo } from "./AppleLogo";
import { DraggableWindow } from "./DraggableWindow";
import { TimerWidget } from "./TimerWidget";
import { site } from "@/lib/site";
import type { View } from "./DesktopShell";

function formatStars(stars: number) {
  return stars >= 1000 ? `${(stars / 1000).toFixed(1)}k` : `${stars}`;
}

export function Hero({
  stars,
  view,
  onOpenApp,
  onCloseWidget,
  onCloseApp,
}: {
  stars: number | null;
  view: View;
  onOpenApp: () => void;
  onCloseWidget: () => void;
  onCloseApp: () => void;
}) {
  const copyOffset =
    view === "picker"
      ? "justify-start pt-[500px] sm:pt-24 lg:justify-center lg:py-0"
      : "justify-end pt-24 lg:justify-center lg:py-0";

  return (
    <section className="wallpaper relative min-h-[calc(100dvh-30px)] overflow-hidden">
      {/* hero copy — bottom on mobile (under the popover), centered on desktop */}
      <div
        className={`relative z-10 mx-auto flex min-h-[calc(100dvh-30px)] max-w-6xl flex-col px-6 pb-12 ${copyOffset}`}
      >
        <div className="max-w-xl text-white">
          <span className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1 text-[12px] font-medium text-white/90 backdrop-blur-sm">
            <span className="h-1.5 w-1.5 rounded-full bg-[#34c759]" />
            Free &amp; open source · macOS 14+
          </span>

          <h1 className="mt-5 text-balance text-[40px] font-semibold leading-[1.05] sm:text-[52px]">
            Long screenshots,{" "}
            <span className="text-white/62">right from your menu bar</span>
          </h1>

          <p className="mt-5 max-w-md text-pretty text-[17px] leading-relaxed text-white/80">
            OpenSS captures the whole page when the built-in macOS screenshot
            tool stops at the viewport. Save essays, threads, docs, and
            research pages as clean, shareable PNGs.
          </p>

          <div className="mt-8 flex items-center gap-3">
            <a
              href={site.releasesLatest}
              className="inline-flex flex-1 items-center justify-center gap-2 rounded-xl bg-white px-4 py-3 text-[15px] font-semibold text-[color:var(--color-ink)] shadow-lg shadow-black/20 transition hover:bg-white/90 sm:flex-none sm:justify-start sm:px-5"
            >
              <AppleLogo className="h-[18px] w-[18px]" />
              <span>
                Download<span className="hidden sm:inline"> for Mac</span>
              </span>
              <span className="hidden text-[color:var(--color-muted)] sm:inline">
                {site.version}
              </span>
            </a>
            <a
              href={site.repo}
              className="inline-flex flex-1 items-center justify-center gap-2.5 rounded-xl border border-white/25 bg-white/5 px-4 py-3 text-[15px] font-semibold text-white backdrop-blur-sm transition hover:bg-white/10 sm:flex-none sm:justify-start sm:px-5"
            >
              <Github className="h-4 w-4" />
              <span>
                Star<span className="hidden sm:inline"> on GitHub</span>
              </span>
              {stars !== null && (
                <span className="flex items-center gap-1 border-l border-white/20 pl-2.5 text-white/80">
                  <Star className="h-3.5 w-3.5 fill-current" />
                  {formatStars(stars)}
                </span>
              )}
            </a>
          </div>

          <p className="mt-4 font-mono text-[12px] text-white/55">
            {site.requirements}
          </p>

          {/* subtle support links */}
          <div className="mt-5 flex items-center gap-5 text-[13px] text-white/55">
            <a
              href={site.sponsor}
              className="inline-flex items-center gap-1.5 transition hover:text-white"
            >
              <Heart className="h-3.5 w-3.5" />
              Sponsor
            </a>
            <a
              href={site.buyMeACoffee}
              className="inline-flex items-center gap-1.5 transition hover:text-white"
            >
              <Coffee className="h-3.5 w-3.5" />
              Buy me a coffee
            </a>
          </div>
        </div>
      </div>

      {/* the menu-bar picker — overlays the desktop, dropping from the menu bar */}
      {view === "picker" && (
        <div className="drop-in absolute right-3 top-2 z-30 sm:right-4">
          <TimerWidget onOpenApp={onOpenApp} onClose={onCloseWidget} />
        </div>
      )}

      {/* the result — a draggable screenshot preview over the desktop */}
      {view === "result" && (
        <DraggableWindow
          onClose={onCloseApp}
          className="absolute left-1/2 top-[7%] z-20 -translate-x-1/2"
        />
      )}
    </section>
  );
}

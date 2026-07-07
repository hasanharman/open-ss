"use client";

import { useEffect, useState } from "react";
import { Wifi, BatteryMedium, Search } from "lucide-react";
import { AppleLogo } from "./AppleLogo";
import { site } from "@/lib/site";

function useClock() {
  const [now, setNow] = useState<string>("");
  useEffect(() => {
    const tick = () => {
      const d = new Date();
      const day = d.toLocaleDateString("en-US", { weekday: "short" });
      const time = d.toLocaleTimeString("en-US", {
        hour: "numeric",
        minute: "2-digit",
      });
      setNow(`${day} ${time}`);
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);
  return now;
}

function MenuBarOpenSSIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 32 32"
      aria-hidden="true"
      className={className}
      fill="none"
    >
      <path
        d="M9 7h6M9 7v6M23 7h-6M23 7v6M9 25h6M9 25v-6M23 25h-6M23 25v-6"
        stroke="currentColor"
        strokeLinecap="round"
        strokeWidth="2.5"
      />
      <path
        d="M16 10v9m0 0-4-4m4 4 4-4"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2.5"
      />
    </svg>
  );
}

/**
 * Full-width macOS menu bar. The OpenSS status item on the right is "open"
 * when the picker is visible, matching the real app.
 */
export function MacMenuBar({
  active,
  onTimerClick,
}: {
  active?: boolean;
  onTimerClick?: () => void;
}) {
  const clock = useClock();

  return (
    <div className="sticky top-0 z-50 flex h-[30px] items-center justify-between rounded-none border-b border-white/16 bg-[#2b55c6]/52 px-4 text-[13px] text-white shadow-[0_1px_0_rgba(0,0,0,0.08)] backdrop-blur-xl">
      {/* left: apple + focused app + its menus */}
      <div className="flex items-center gap-5">
        <AppleLogo className="h-[17px] w-[17px]" />
        <span className="font-semibold">{site.name}</span>
        {["File", "Edit", "View", "Window", "Help"].map((m) => (
          <span key={m} className="hidden text-white/85 sm:inline">
            {m}
          </span>
        ))}
      </div>

      {/* right: status items — the OpenSS item is the one that's open */}
      <div className="flex items-center gap-3.5 text-white/90">
        <Search className="hidden h-3.5 w-3.5 sm:block" />
        <BatteryMedium className="hidden h-[18px] w-[18px] sm:block" />
        <Wifi className="hidden h-4 w-4 sm:block" />
        <button
          onClick={onTimerClick}
          aria-label="OpenSS menu"
          className={`-mx-1 flex items-center gap-1.5 rounded-md px-1.5 py-0.5 transition ${
            active ? "bg-white/26" : "hover:bg-white/14"
          }`}
        >
          <MenuBarOpenSSIcon className="h-[17px] w-[17px]" />
        </button>
        <span className="tabular min-w-[92px] text-right text-[12px]">
          {clock || " "}
        </span>
      </div>
    </div>
  );
}

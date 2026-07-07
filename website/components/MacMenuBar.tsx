"use client";

import { useEffect, useState } from "react";
import { Wifi, BatteryMedium, Search } from "lucide-react";
import { AppleLogo } from "./AppleLogo";
import { OpenSSIcon } from "./OpenSSIcon";
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
    <div className="sticky top-0 z-50 flex h-[30px] items-center justify-between rounded-none border-0 bg-[#1b1b1d] px-4 text-[13px] text-white">
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
            active ? "bg-white/20" : "hover:bg-white/10"
          }`}
        >
          <OpenSSIcon className="h-[17px] w-[17px]" />
        </button>
        <span className="tabular min-w-[92px] text-right text-[12px]">
          {clock || " "}
        </span>
      </div>
    </div>
  );
}

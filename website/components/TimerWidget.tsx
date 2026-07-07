"use client";

import { useState } from "react";
import {
  Check,
  Crop,
  FileImage,
  MousePointerClick,
  X,
} from "lucide-react";
import { OpenSSIcon } from "./OpenSSIcon";

const windows = [
  {
    app: "Medium",
    title: "How great products explain themselves",
    tone: "from-[#fff7e8] to-[#d9eef1]",
    kind: "article",
  },
  {
    app: "X / Twitter",
    title: "A thread about tiny macOS utilities",
    tone: "from-[#eff6ff] to-[#dceafe]",
    kind: "social",
  },
  {
    app: "Notion",
    title: "Launch checklist — open source app",
    tone: "from-[#f7f2ea] to-[#e6ddd1]",
    kind: "doc",
  },
  {
    app: "GitHub",
    title: "README.md — installation and permissions",
    tone: "from-[#f8fafc] to-[#dbe7f1]",
    kind: "readme",
  },
];

function PreviewThumb({
  tone,
  kind,
}: {
  tone: string;
  kind: string;
}) {
  return (
    <span
      className={`relative h-12 w-[72px] shrink-0 overflow-hidden rounded-md bg-gradient-to-br ${tone} ring-1 ring-black/10`}
    >
      {kind === "article" && (
        <>
          <span className="absolute left-3 top-2 h-1.5 w-8 rounded-full bg-[#2f6f67]" />
          <span className="absolute left-3 top-5 h-1.5 w-12 rounded-full bg-black/65" />
          <span className="absolute left-3 top-8 h-1.5 w-10 rounded-full bg-black/32" />
          <span className="absolute bottom-0 right-2 h-7 w-5 rounded-t bg-[#dba15d]/55" />
        </>
      )}
      {kind === "social" && (
        <>
          <span className="absolute left-2 top-2 h-6 w-6 rounded-full bg-[#1d9bf0]/80" />
          <span className="absolute left-10 top-3 h-1.5 w-16 rounded-full bg-black/45" />
          <span className="absolute left-10 top-6 h-1.5 w-10 rounded-full bg-black/24" />
          <span className="absolute bottom-2 left-3 h-1.5 w-12 rounded-full bg-[#1d9bf0]/55" />
        </>
      )}
      {kind === "doc" && (
        <>
          <span className="absolute left-3 top-2 h-2 w-7 rounded bg-black/55" />
          <span className="absolute left-3 top-6 h-1.5 w-12 rounded bg-black/32" />
          <span className="absolute left-3 top-9 h-1.5 w-10 rounded bg-black/22" />
          <span className="absolute right-3 top-7 grid h-3 w-3 place-items-center rounded-full bg-[#35dbc9]" />
        </>
      )}
      {kind === "readme" && (
        <>
          <span className="absolute left-3 top-2 h-2 w-8 rounded bg-[#24292f]/70" />
          <span className="absolute left-3 top-6 h-1.5 w-11 rounded bg-[#57606a]/45" />
          <span className="absolute left-3 top-9 h-1.5 w-12 rounded bg-[#57606a]/32" />
          <span className="absolute right-2 top-2 h-8 w-4 rounded bg-[#0969da]/20" />
        </>
      )}
    </span>
  );
}

export function TimerWidget({
  onOpenApp,
  onClose,
}: {
  onOpenApp?: () => void;
  onClose?: () => void;
}) {
  const [hovered, setHovered] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [capturing, setCapturing] = useState(false);
  const [frames, setFrames] = useState(0);

  const startCapture = (index: number) => {
    if (capturing) return;
    setSelected(index);
    setCapturing(true);
    setFrames(1);

    let count = 1;
    const id = window.setInterval(() => {
      count += 1;
      setFrames(count);
      if (count >= 8) {
        window.clearInterval(id);
        setCapturing(false);
        onOpenApp?.();
      }
    }, 180);
  };

  return (
    <div className="w-[370px] select-none rounded-[18px] border border-white/10 bg-[#14171c]/95 p-3 text-white shadow-[0_32px_90px_-28px_rgba(0,0,0,0.95)] ring-1 ring-black/50 backdrop-blur-2xl">
      <div className="mb-3 flex items-center justify-between px-1">
        <div className="flex items-center gap-2">
          <span className="grid h-7 w-7 place-items-center rounded-lg bg-[#35dbc9]/15 text-[#52f1df] ring-1 ring-[#52f1df]/25">
            <OpenSSIcon className="h-5 w-5" />
          </span>
          <div>
            <p className="text-[13px] font-semibold leading-tight">OpenSS</p>
            <p className="text-[11px] text-white/45">Click a window to capture</p>
          </div>
        </div>
        <button
          onClick={onClose}
          aria-label="Close picker"
          className="grid h-6 w-6 place-items-center rounded-full text-white/45 transition hover:bg-white/10 hover:text-white"
        >
          <X className="h-3.5 w-3.5" />
        </button>
      </div>

      <div className="mb-3 flex items-center justify-between rounded-xl bg-white/[0.04] px-3 py-2 ring-1 ring-white/8">
        <span className="flex items-center gap-2 text-[12px] text-white/72">
          <Crop className="h-3.5 w-3.5 text-[#52f1df]" />
          Content only
        </span>
        <span className="flex h-5 w-9 items-center rounded-full bg-[#35dbc9] px-0.5 shadow-inner shadow-black/20">
          <span className="ml-auto h-4 w-4 rounded-full bg-white shadow" />
        </span>
      </div>

      <div className="space-y-1.5">
        {windows.map((item, index) => {
          const active = selected === index;
          const hover = hovered === index;
          return (
            <button
              key={`${item.app}-${item.title}`}
              onMouseEnter={() => setHovered(index)}
              onFocus={() => setHovered(index)}
              onClick={() => startCapture(index)}
              className={`group flex w-full items-center gap-3 rounded-xl px-2.5 py-2 text-left transition ${
                active
                  ? "bg-[#0a84ff] text-white"
                  : hover
                    ? "bg-[#35dbc9]/14"
                    : "bg-black/25 hover:bg-[#35dbc9]/14"
              }`}
            >
              <PreviewThumb tone={item.tone} kind={item.kind} />
              <span className="min-w-0 flex-1">
                <span className="block truncate text-[13px] font-semibold">
                  {item.app}
                </span>
                <span
                  className={`block truncate text-[12px] ${
                    active ? "text-white/85" : "text-white/48"
                  }`}
                >
                  {item.title}
                </span>
              </span>
              {active && !capturing && <Check className="h-4 w-4" />}
            </button>
          );
        })}
      </div>

      <div className="mt-3 h-1 overflow-hidden rounded-full bg-white/10">
        <div
          className={`h-full rounded-full bg-[#52f1df] transition-all duration-200 ${
            capturing ? "opacity-100" : "opacity-45"
          }`}
          style={{ width: capturing ? `${Math.min(100, frames * 13)}%` : "16%" }}
        />
      </div>

      <div className="mt-3 flex items-center justify-between text-[11px] text-white/45">
        <span className="flex items-center gap-1.5">
          {capturing ? (
            <>
              <FileImage className="h-3.5 w-3.5 text-[#52f1df]" />
              Captured {frames} frames
            </>
          ) : (
            <>
              <MousePointerClick className="h-3.5 w-3.5" />
              Hover previews, click starts
            </>
          )}
        </span>
        <span>⌘⇧L</span>
      </div>
    </div>
  );
}

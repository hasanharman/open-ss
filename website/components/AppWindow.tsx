import {
  Check,
  Download,
  FileImage,
  PanelLeft,
  X,
} from "lucide-react";
import { OpenSSIcon } from "./OpenSSIcon";
import type { CaptureExample } from "@/lib/examples";

function SourceBrowser({ example }: { example: CaptureExample }) {
  const html = `<!doctype html>
<html>
  <head>
    <style>
      body {
        margin: 0;
        background: ${example.palette.page};
        color: #172033;
        font: 13px -apple-system, BlinkMacSystemFont, sans-serif;
      }
      main { padding: 16px 18px 28px; }
      .eyebrow {
        color: ${example.palette.accent};
        font: 700 9px ui-monospace, SFMono-Regular, Menlo, monospace;
        text-transform: uppercase;
      }
      h1 { margin: 8px 0 6px; font-size: 24px; line-height: 1.05; }
      p { color: ${example.palette.muted}; line-height: 1.45; }
      section { border-top: 1px solid rgba(0,0,0,.12); margin-top: 18px; padding-top: 14px; }
      h2 { font-size: 14px; margin: 0 0 10px; }
      i { display: block; height: 7px; margin: 7px 0; border-radius: 999px; background: rgba(0,0,0,.28); }
      i:nth-child(3) { width: 82%; }
      i:nth-child(4) { width: 68%; }
    </style>
  </head>
  <body>
    <main>
      <div class="eyebrow">${example.source}</div>
      <h1>${example.title}</h1>
      <p>${example.subtitle}</p>
      ${example.sections
        .map(
          (section) =>
            `<section><h2>${section}</h2><i></i><i></i><i></i></section>`,
        )
        .join("")}
    </main>
  </body>
</html>`;

  return (
    <div className="overflow-hidden rounded-lg bg-[#edf1f7] text-[#172033] ring-1 ring-black/10">
      <div className="flex h-5 items-center gap-1.5 bg-[#dfe5ef] px-2">
        <span className="h-1.5 w-1.5 rounded-full bg-[#ff5f57]" />
        <span className="h-1.5 w-1.5 rounded-full bg-[#febc2e]" />
        <span className="h-1.5 w-1.5 rounded-full bg-[#28c840]" />
        <span className="ml-2 h-2 flex-1 rounded bg-white/75" />
      </div>
      <iframe
        title={`${example.source} source preview`}
        srcDoc={html}
        className="h-[102px] w-full border-0"
        tabIndex={-1}
      />
    </div>
  );
}

function CapturedPage({ example }: { example: CaptureExample }) {
  return (
    <div
      className="mx-auto w-[370px] rounded-xl px-8 py-7 shadow-2xl ring-1 ring-black/10"
      style={{ backgroundColor: example.palette.page, color: "#172033" }}
    >
      <p
        className="font-mono text-[8px] uppercase"
        style={{ color: example.palette.accent }}
      >
        {example.eyebrow}
      </p>
      <h2 className="mt-3 text-[25px] font-semibold leading-tight">
        {example.title}
      </h2>
      <p
        className="mt-2 text-[11px] leading-relaxed"
        style={{ color: example.palette.muted }}
      >
        {example.subtitle}
      </p>

      <div
        className="mt-5 rounded-lg border-l-2 p-3 text-[10px] font-medium leading-relaxed"
        style={{
          backgroundColor: `${example.palette.accent}18`,
          borderColor: example.palette.accent,
          color: "#21313f",
        }}
      >
        {example.callout}
      </div>

      <div className="mt-6 space-y-5">
        {example.sections.map((section, index) => (
          <section key={section} className="border-t border-black/10 pt-4">
            <h3 className="flex items-baseline gap-2 text-[14px] font-semibold">
              <span className="font-mono" style={{ color: example.palette.accent }}>
                {index + 1}
              </span>
              {section}
            </h3>
            <div className="mt-3 space-y-2">
              <span className="block h-2 w-full rounded bg-black/45" />
              <span className="block h-2 w-[92%] rounded bg-black/28" />
              <span className="block h-2 w-[76%] rounded bg-black/20" />
            </div>
            {index === 1 && (
              <div className="mt-3 grid grid-cols-3 gap-1.5">
                {[1, 2, 3].map((item) => (
                  <span
                    key={item}
                    className="h-10 rounded bg-black/10 ring-1 ring-black/8"
                  />
                ))}
              </div>
            )}
          </section>
        ))}
      </div>
    </div>
  );
}

/** A stylized result window showing the full-page screenshot OpenSS produces. */
export function AppWindow({
  example,
  onClose,
  dragHandleProps,
}: {
  example: CaptureExample;
  onClose?: () => void;
  dragHandleProps?: React.HTMLAttributes<HTMLDivElement>;
}) {
  return (
    <div className="w-[720px] overflow-hidden rounded-[14px] border border-white/10 bg-[#171a1f] text-white shadow-[0_40px_100px_-25px_rgba(0,0,0,0.9)] ring-1 ring-black/50">
      <div
        {...dragHandleProps}
        className="flex cursor-grab touch-none select-none items-center gap-3 border-b border-white/[0.06] bg-[#1f232b] px-4 py-2.5 active:cursor-grabbing"
      >
        <div className="group flex gap-1.5">
          <button
            onPointerDown={(e) => e.stopPropagation()}
            onClick={onClose}
            aria-label="Close window"
            className="grid h-3 w-3 place-items-center rounded-full bg-[#ff5f57]"
          >
            <X className="h-2 w-2 text-black/55 opacity-0 transition group-hover:opacity-100" />
          </button>
          <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
          <span className="h-3 w-3 rounded-full bg-[#28c840]" />
        </div>
        <PanelLeft className="ml-1 h-3.5 w-3.5 text-white/35" />
        <span className="text-[12px] font-semibold">
          OpenSS-{example.id}-Long-Screenshot.png
        </span>
        <span className="ml-auto flex items-center gap-1.5 rounded-md bg-[#35dbc9]/12 px-2 py-1 text-[10px] font-medium text-[#79fff0] ring-1 ring-[#35dbc9]/20">
          <Check className="h-3 w-3" />
          Content only
        </span>
      </div>

      <div className="grid grid-cols-[180px_1fr] gap-0">
        <aside className="border-r border-white/[0.06] bg-[#111419] p-3">
          <div className="mb-3 flex items-center gap-2 rounded-lg bg-white/[0.04] p-2 ring-1 ring-white/8">
            <span className="grid h-8 w-8 place-items-center rounded-md bg-[#35dbc9]/14 text-[#69f6e9]">
              <OpenSSIcon className="h-5 w-5" />
            </span>
            <div className="min-w-0">
              <p className="truncate text-[11px] font-semibold">
                {example.source}
              </p>
              <p className="truncate text-[10px] text-white/40">8 frames stitched</p>
            </div>
          </div>

          <div className="mb-3 rounded-lg bg-white/[0.035] p-2">
            <SourceBrowser example={example} />
          </div>

          <div className="space-y-2 text-[10px] text-white/52">
            {[
              ["Browser chrome", "cropped"],
              ["Scroll", "auto"],
              ["Output", "PNG"],
            ].map(([label, value]) => (
              <div
                key={label}
                className="flex items-center justify-between rounded-md bg-white/[0.035] px-2 py-1.5"
              >
                <span>{label}</span>
                <span className="font-medium text-white/75">{value}</span>
              </div>
            ))}
          </div>

          <button className="mt-4 flex w-full items-center justify-center gap-1.5 rounded-lg bg-white/[0.06] py-2 text-[11px] font-semibold text-white/80 ring-1 ring-white/10">
            <Download className="h-3.5 w-3.5" />
            Saved to Desktop
          </button>
        </aside>

        <main className="max-h-[500px] overflow-hidden bg-[#0d1214] p-5">
          <CapturedPage example={example} />
        </main>
      </div>

      <div className="flex items-center gap-2 border-t border-white/[0.06] bg-[#111419] px-4 py-2 text-[10px] text-white/45">
        <FileImage className="h-3.5 w-3.5 text-[#52f1df]" />
        Output is one tall PNG, ready to share.
      </div>
    </div>
  );
}

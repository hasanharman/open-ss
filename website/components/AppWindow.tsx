import {
  Camera,
  Check,
  Download,
  FileImage,
  PanelLeft,
  X,
} from "lucide-react";

const sections = [
  "Error Message Contract",
  "What exists today",
  "Proposed contract",
  "Fallback behavior",
  "Frontend renderer",
  "Rollout checklist",
];

/** A stylized result window showing the full-page screenshot OpenSS produces. */
export function AppWindow({
  onClose,
  dragHandleProps,
}: {
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
        <span className="text-[12px] font-semibold tracking-tight">
          OpenSS-Long-Screenshot.png
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
              <Camera className="h-4 w-4" />
            </span>
            <div className="min-w-0">
              <p className="truncate text-[11px] font-semibold">Chrome tab</p>
              <p className="truncate text-[10px] text-white/40">8 frames stitched</p>
            </div>
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
          <div className="mx-auto w-[360px] rounded-xl bg-[#11181a] px-8 py-7 shadow-2xl ring-1 ring-white/8">
            <p className="font-mono text-[8px] uppercase tracking-[0.28em] text-[#52f1df]">
              Spec · captured by OpenSS
            </p>
            <h2 className="mt-3 text-[24px] font-semibold tracking-[-0.04em]">
              Error Message Contract
            </h2>
            <p className="mt-2 text-[11px] leading-relaxed text-white/62">
              A stitched, content-only long screenshot that keeps the page body
              and removes the browser furniture.
            </p>

            <div className="mt-5 rounded-lg border-l-2 border-[#52f1df] bg-[#17302f] p-3 text-[10px] leading-relaxed text-white/82">
              Capture the whole page, not just the viewport.
            </div>

            <div className="mt-6 space-y-5">
              {sections.map((section, index) => (
                <section key={section} className="border-t border-white/10 pt-4">
                  <h3 className="flex items-baseline gap-2 text-[14px] font-semibold">
                    <span className="font-mono text-[#52f1df]">{index + 1}</span>
                    {section}
                  </h3>
                  <div className="mt-3 space-y-2">
                    <span className="block h-2 w-full rounded bg-white/55" />
                    <span className="block h-2 w-[92%] rounded bg-white/32" />
                    <span className="block h-2 w-[76%] rounded bg-white/26" />
                  </div>
                  {index === 2 && (
                    <div className="mt-3 grid grid-cols-3 gap-1.5">
                      {[1, 2, 3].map((item) => (
                        <span
                          key={item}
                          className="h-9 rounded bg-[#243034] ring-1 ring-white/8"
                        />
                      ))}
                    </div>
                  )}
                </section>
              ))}
            </div>
          </div>
        </main>
      </div>

      <div className="flex items-center gap-2 border-t border-white/[0.06] bg-[#111419] px-4 py-2 text-[10px] text-white/45">
        <FileImage className="h-3.5 w-3.5 text-[#52f1df]" />
        Output is one tall PNG, ready to share.
      </div>
    </div>
  );
}

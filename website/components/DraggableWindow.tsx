"use client";

import { useRef, useState } from "react";
import { AppWindow } from "./AppWindow";
import type { CaptureExample } from "@/lib/examples";

/**
 * Makes the app window draggable by its title bar — like a real desktop window.
 * Drag offset lives on an un-zoomed wrapper so it tracks the pointer 1:1, while
 * the inner `app-scale` zoom only affects the window's rendered size.
 */
export function DraggableWindow({
  example,
  onClose,
  className,
}: {
  example: CaptureExample;
  onClose?: () => void;
  className?: string;
}) {
  const [pos, setPos] = useState({ x: 0, y: 0 });
  const start = useRef<{ mx: number; my: number; x: number; y: number } | null>(
    null,
  );

  const onPointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    if (e.button !== 0) return;
    if ((e.target as HTMLElement).closest("button")) return; // let buttons click
    start.current = { mx: e.clientX, my: e.clientY, x: pos.x, y: pos.y };
    try {
      e.currentTarget.setPointerCapture(e.pointerId);
    } catch {}
  };
  const onPointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!start.current) return;
    setPos({
      x: start.current.x + (e.clientX - start.current.mx),
      y: start.current.y + (e.clientY - start.current.my),
    });
  };
  const onPointerUp = () => {
    start.current = null;
  };

  return (
    <div className={className}>
      <div style={{ transform: `translate(${pos.x}px, ${pos.y}px)` }}>
        <div className="app-scale scale-in">
          <AppWindow
            example={example}
            onClose={onClose}
            dragHandleProps={{ onPointerDown, onPointerMove, onPointerUp }}
          />
        </div>
      </div>
    </div>
  );
}

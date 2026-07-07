import { ImageResponse } from "next/og";

export const alt = "OpenSS — long screenshots from your Mac menu bar";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const rows = ["Medium article", "X / Twitter thread", "Notion doc"];
const sections = [1, 2, 3, 4, 5];

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "0 82px",
          background:
            "linear-gradient(180deg, #253f9f 0%, #3558c5 34%, #6888e5 67%, #aebbe0 90%, #f2c676 100%)",
          fontFamily: "sans-serif",
          color: "white",
        }}
      >
        <div style={{ display: "flex", flexDirection: "column", maxWidth: 610 }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 14,
              fontSize: 22,
              fontWeight: 700,
              color: "rgba(255,255,255,0.76)",
            }}
          >
            <div
              style={{
                width: 13,
                height: 13,
                borderRadius: 99,
                background: "#52f1df",
                display: "flex",
              }}
            />
            FREE · OPEN SOURCE · macOS 14+
          </div>

          <div
            style={{
              display: "flex",
              flexDirection: "column",
              marginTop: 30,
              fontSize: 76,
              fontWeight: 760,
              lineHeight: 1.02,
            }}
          >
            <span>Long screenshots,</span>
            <span style={{ color: "rgba(255,255,255,0.58)" }}>
              from the menu bar
            </span>
          </div>

          <div
            style={{
              display: "flex",
              fontSize: 27,
              marginTop: 32,
              lineHeight: 1.35,
              color: "rgba(255,255,255,0.78)",
            }}
          >
            Pick a window, auto-scroll to the end, crop browser chrome, and save
            one clean PNG.
          </div>
        </div>

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            width: 330,
            padding: 18,
            borderRadius: 26,
            background: "#14171c",
            border: "1px solid rgba(255,255,255,0.1)",
            boxShadow: "0 40px 90px rgba(0,0,0,0.35)",
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 12,
              fontSize: 22,
              fontWeight: 700,
            }}
          >
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: 12,
                background: "rgba(82,241,223,0.14)",
                border: "1px solid rgba(82,241,223,0.28)",
                display: "flex",
              }}
            />
            OpenSS
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 10, marginTop: 20 }}>
            {rows.map((row, index) => (
              <div
                key={row}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  padding: 12,
                  borderRadius: 16,
                background:
                    index === 0 ? "rgba(82,241,223,0.18)" : "rgba(255,255,255,0.055)",
                }}
              >
                <div
                  style={{
                    width: 68,
                    height: 42,
                    borderRadius: 8,
                    background: "linear-gradient(180deg,#eff8ff,#ffd9a3)",
                    display: "flex",
                  }}
                />
                <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
                  <span style={{ fontSize: 18, fontWeight: 700 }}>{row}</span>
                  <span style={{ fontSize: 14, color: "rgba(255,255,255,0.58)" }}>
                    Click to capture
                  </span>
                </div>
              </div>
            ))}
          </div>

          <div
            style={{
              display: "flex",
              marginTop: 18,
              height: 118,
              borderRadius: 18,
              background: "#0d1214",
              padding: 18,
              gap: 8,
            }}
          >
            {sections.map((section) => (
              <div
                key={section}
                style={{
                  display: "flex",
                  flex: 1,
                  borderRadius: 8,
                  background: section === 1 ? "#52f1df" : "rgba(255,255,255,0.2)",
                  opacity: section === 1 ? 1 : 0.55,
                }}
              />
            ))}
          </div>
        </div>
      </div>
    ),
    { ...size },
  );
}

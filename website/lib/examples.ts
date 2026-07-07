export type ExampleId = "article" | "thread" | "doc" | "readme";

export type CaptureExample = {
  id: ExampleId;
  app: string;
  source: string;
  title: string;
  subtitle: string;
  preview: string;
  eyebrow: string;
  callout: string;
  sections: string[];
  palette: {
    page: string;
    accent: string;
    muted: string;
  };
};

export const examples: CaptureExample[] = [
  {
    id: "article",
    app: "Medium",
    source: "Medium article",
    title: "How Great Products Explain Themselves",
    subtitle: "A complete essay captured as one clean PNG.",
    preview: "/previews/article.png",
    eyebrow: "Article · captured by OpenSS",
    callout: "Capture the full story, not just the part currently visible.",
    sections: [
      "The promise should be visible",
      "Tiny decisions carry the product",
      "Good defaults reduce explanation",
      "Screenshots should keep context",
      "Share the finished thing",
    ],
    palette: {
      page: "#f8f2e7",
      accent: "#0f766e",
      muted: "#5d6b6d",
    },
  },
  {
    id: "thread",
    app: "X / Twitter",
    source: "Social thread",
    title: "A Thread About Tiny macOS Utilities",
    subtitle: "A tall thread preserved without stitching by hand.",
    preview: "/previews/social.png",
    eyebrow: "Thread · captured by OpenSS",
    callout: "Threads, replies, and cards stay in one continuous capture.",
    sections: [
      "Why menu bar tools work",
      "The screenshot problem",
      "A capture should feel instant",
      "Crop the browser chrome",
      "Post the result anywhere",
    ],
    palette: {
      page: "#f8fafc",
      accent: "#1d9bf0",
      muted: "#64748b",
    },
  },
  {
    id: "doc",
    app: "Notion",
    source: "Workspace doc",
    title: "Launch Checklist for an Open Source App",
    subtitle: "A project doc captured from first heading to final task.",
    preview: "/previews/doc.png",
    eyebrow: "Doc · captured by OpenSS",
    callout: "Checklists and notes become one shareable artifact.",
    sections: [
      "Release candidate",
      "Permission copy",
      "Website screenshots",
      "README pass",
      "First tagged build",
    ],
    palette: {
      page: "#fbfaf7",
      accent: "#14b8a6",
      muted: "#78716c",
    },
  },
  {
    id: "readme",
    app: "GitHub",
    source: "GitHub README",
    title: "OpenSS Installation and Permissions",
    subtitle: "A repository page captured for docs and support.",
    preview: "/previews/readme.png",
    eyebrow: "README · captured by OpenSS",
    callout: "Long setup guides stay readable outside the browser.",
    sections: [
      "Install from source",
      "Build the app bundle",
      "Grant permissions",
      "Use content-only mode",
      "Troubleshooting",
    ],
    palette: {
      page: "#ffffff",
      accent: "#0969da",
      muted: "#57606a",
    },
  },
];

export const defaultExample = examples[0];

export function OpenSSIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 32 32"
      aria-hidden="true"
      className={className}
      fill="none"
    >
      <rect width="32" height="32" rx="8" fill="#10161A" />
      <path
        d="M9 7h6M9 7v6M23 7h-6M23 7v6M9 25h6M9 25v-6M23 25h-6M23 25v-6"
        stroke="#52F1DF"
        strokeLinecap="round"
        strokeWidth="2.2"
      />
      <rect
        x="12"
        y="9.5"
        width="8"
        height="13"
        rx="2"
        stroke="white"
        strokeOpacity=".92"
        strokeWidth="1.7"
      />
      <circle cx="16" cy="16" r="2.2" fill="#52F1DF" />
    </svg>
  );
}

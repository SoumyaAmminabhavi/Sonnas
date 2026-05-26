import { type Config } from "tailwindcss";

export default {
    content: ["./src/**/*.{ts,tsx,js,jsx}"],
    theme: {
        extend: {
            colors: {
                blush: "#F4C2C2",
                rose: "#E8A9A9",
                roseDark: "#D88C8C",
                cream: "#F7F3EF",
                beige: "#E8DED4",
                ivory: "#FFF9F7",
                textPrimary: "#2B2B2B",
                textSecondary: "#6E6E6E",
                textMuted: "#9A9A9A",
                gold: "#C9A27E",
                cocoa: "#5A3E36",
            },
            spacing: {
                xs: "4px",
                sm: "8px",
                md: "16px",
                lg: "24px",
                xl: "32px",
                "2xl": "48px",
            },
            fontFamily: {
                heading: ["Playfair Display", "serif"],
                body: ["Inter", "sans-serif"],
            },
            borderRadius: {
                sm: "8px",
                md: "12px",
                lg: "16px",
            },
            boxShadow: {
                soft: "0 4px 12px rgba(0,0,0,0.05)",
                medium: "0 8px 20px rgba(0,0,0,0.08)",
            },
            transitionDuration: {
                DEFAULT: "300ms",
            },
            transitionTimingFunction: {
                DEFAULT: "ease",
            },
            transitionProperty: {
                DEFAULT: "all",
            },
        },
    },
} satisfies Config;
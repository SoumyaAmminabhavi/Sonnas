import "~/styles/globals.css";

import { type Metadata } from "next";
import { Playfair_Display, Inter } from "next/font/google";

import { TRPCReactProvider } from "~/trpc/react";

const playfair = Playfair_Display({
  subsets: ["latin"],
  variable: "--font-playfair",
});

// trigger build
const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

// Deployment pulse: Multi-item cart system v1.1
export const metadata: Metadata = {
  title: "SONNA'S PATISSERIE & CAFE | Luxury French Desserts",
  description: "Experience the finest luxury French patisserie and cakes, crafted with love and baked to perfection.",
  icons: [{ rel: "icon", url: "/favicon.ico" }],
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${playfair.variable} ${inter.variable}`}>
      <body className="font-body antialiased">
        <TRPCReactProvider>{children}</TRPCReactProvider>
      </body>
    </html>
  );
}

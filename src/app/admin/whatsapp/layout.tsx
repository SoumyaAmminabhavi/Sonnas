import { type Metadata } from "next";

export const metadata: Metadata = {
  title: "WhatsApp Orders | SONNA'S Admin",
  description: "Manage WhatsApp orders for Sonna's Patisserie & Cafe",
};

export default function AdminWhatsAppLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return <>{children}</>;
}

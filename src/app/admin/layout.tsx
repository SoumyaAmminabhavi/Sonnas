"use client";

import Link from "next/image";
import { usePathname } from "next/navigation";
import LinkNext from "next/link";

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();

  const navItems = [
    { name: "Orders", href: "/admin/whatsapp", icon: "📋" },
    { name: "Menu", href: "/admin/menu", icon: "🧁" },
  ];

  return (
    <div className="flex min-h-screen bg-[#FFF9F7]">
      {/* Sidebar Navigation */}
      <aside className="w-64 bg-[#2B2B2B] text-[#FFF9F7] flex flex-col shadow-2xl">
        <div className="p-8 border-b border-white/5">
          <h2 className="font-heading text-xl text-[#F4C2C2] tracking-widest">SONNA&apos;S</h2>
          <p className="text-[10px] uppercase tracking-[3px] text-[#9A9A9A] mt-1">Management</p>
        </div>

        <nav className="flex-1 p-4 space-y-2">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <LinkNext
                key={item.name}
                href={item.href}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                  isActive
                    ? "bg-[#F4C2C2] text-[#2B2B2B] font-bold shadow-lg"
                    : "text-[#9A9A9A] hover:bg-white/5 hover:text-white"
                }`}
              >
                <span className="text-xl">{item.icon}</span>
                <span>{item.name}</span>
              </LinkNext>
            );
          })}
        </nav>

        <div className="p-6 border-t border-white/5">
          <LinkNext
            href="/"
            className="flex items-center gap-2 text-xs text-[#9A9A9A] hover:text-[#F4C2C2] transition-colors"
          >
            ← Back to Website
          </LinkNext>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 h-screen overflow-y-auto">
        {children}
      </main>
    </div>
  );
}

"use client";

import { usePathname, useSearchParams } from "next/navigation";
import LinkNext from "next/link";
import { Suspense } from "react";

function AdminNavbar() {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const navItems = [
    { name: "Orders", href: "/admin/whatsapp", icon: "📋" },
    { name: "Menu", href: "/admin/menu", icon: "🧁" },
  ];

  return (
    <nav className="flex items-center gap-4">
      {navItems.map((item) => {
        const isActive = pathname === item.href;
        const isOrders = item.name === "Orders";
        
        return (
          <div key={item.name} className="flex items-center gap-1">
            <LinkNext
              href={item.href}
              className={`flex items-center gap-2 px-6 py-2 rounded-full transition-all ${
                isActive
                  ? "bg-[#F4C2C2] text-[#2B2B2B] font-bold shadow-lg"
                  : "text-[#9A9A9A] hover:bg-white/5 hover:text-white"
              }`}
            >
              <span className="text-lg">{item.icon}</span>
              <span className="text-sm font-medium">{item.name}</span>
            </LinkNext>
            
            {isOrders && isActive && (
              <LinkNext
                href={pathname + (searchParams.get("sidebar") === "collapsed" ? "" : "?sidebar=collapsed")}
                className="p-2 hover:bg-white/5 rounded-full text-[#F4C2C2] transition-colors"
                title={searchParams.get("sidebar") === "collapsed" ? "Show Filters" : "Hide Filters"}
              >
                <span className="text-lg">
                  {searchParams.get("sidebar") === "collapsed" ? "→" : "←"}
                </span>
              </LinkNext>
            )}
          </div>
        );
      })}
    </nav>
  );
}

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex flex-col h-screen overflow-hidden bg-[#FFF9F7]">
      {/* Top Navbar */}
      <header className="h-20 bg-[#2B2B2B] text-[#FFF9F7] flex items-center justify-between px-8 shadow-xl z-50">
        <div className="flex items-center gap-12">
          <div>
            <h2 className="font-heading text-xl text-[#F4C2C2] tracking-widest m-0 leading-none">SONNA&apos;S</h2>
            <p className="text-[10px] uppercase tracking-[3px] text-[#9A9A9A] mt-1 m-0">Management</p>
          </div>

          <Suspense fallback={<div className="text-[#9A9A9A] text-sm">Loading...</div>}>
            <AdminNavbar />
          </Suspense>
        </div>

        <div className="flex items-center gap-6">
          <LinkNext
            href="/"
            className="text-xs text-[#9A9A9A] hover:text-[#F4C2C2] transition-colors"
          >
            ← View Site
          </LinkNext>
          <div className="w-8 h-8 rounded-full bg-[#5A3E36] flex items-center justify-center text-[#F4C2C2] font-bold text-xs">
            A
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 relative">
        {children}
      </main>
    </div>
  );
}

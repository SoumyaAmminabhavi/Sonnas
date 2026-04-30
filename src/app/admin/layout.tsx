"use client";

import { usePathname, useSearchParams } from "next/navigation";
import LinkNext from "next/link";
import { Suspense } from "react";

function AdminNavbar() {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const isOrdersPage = pathname === "/admin/whatsapp";
  const isMenuPage = pathname === "/admin/menu";

  return (
    <div className="flex items-center gap-4">
      {/* Orders / Sidebar Toggle */}
      {isMenuPage ? (
        <LinkNext
          href="/admin/whatsapp"
          className="flex items-center gap-2 px-6 py-2 rounded-full transition-all bg-white/5 text-[#9A9A9A] hover:bg-[#F4C2C2] hover:text-[#2B2B2B] hover:font-bold hover:shadow-lg"
        >
          <span className="text-lg">📋</span>
          <span className="text-sm font-medium">Orders</span>
        </LinkNext>
      ) : isOrdersPage ? (
        <LinkNext
          href={pathname + (searchParams.get("sidebar") === "collapsed" ? "" : "?sidebar=collapsed")}
          className="flex items-center gap-2 px-6 py-2 rounded-full transition-all bg-[#F4C2C2] text-[#2B2B2B] font-bold shadow-lg hover:bg-white/10 hover:text-white"
          title={searchParams.get("sidebar") === "collapsed" ? "Show Sidebar" : "Hide Sidebar"}
        >
          <span className="text-lg">
            {searchParams.get("sidebar") === "collapsed" ? "→" : "←"}
          </span>
        </LinkNext>
      ) : null}

      {/* Persistent Menu Button */}
      <LinkNext
        href="/admin/menu"
        className={`flex items-center gap-2 px-6 py-2 rounded-full transition-all ${
          isMenuPage
            ? "bg-[#F4C2C2] text-[#2B2B2B] font-bold shadow-lg"
            : "text-[#9A9A9A] hover:bg-white/5 hover:text-white"
        }`}
      >
        <span className="text-lg">🧁</span>
        <span className="text-sm font-medium">Menu</span>
      </LinkNext>
    </div>
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
      <main className="flex-1 relative overflow-y-auto">
        {children}
      </main>
    </div>
  );
}

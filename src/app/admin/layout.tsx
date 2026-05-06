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
    <div className="flex items-center gap-6">
      {/* Orders / Sidebar Toggle */}
      {isMenuPage ? (
        <LinkNext
          href="/admin/whatsapp"
          className="flex items-center gap-2 px-6 py-2 rounded-full transition-all bg-beige/40 text-text-muted hover:bg-blush/20 hover:text-cocoa hover:shadow-soft"
        >
          <span className="text-base">📋</span>
          <span className="text-[11px] uppercase tracking-wider font-bold">Orders</span>
        </LinkNext>
      ) : isOrdersPage ? (
        <LinkNext
          href={pathname + (searchParams.get("sidebar") === "collapsed" ? "" : "?sidebar=collapsed")}
          className="flex items-center justify-center w-10 h-10 rounded-full transition-all bg-blush/30 text-cocoa shadow-soft hover:bg-blush/50"
          title={searchParams.get("sidebar") === "collapsed" ? "Show Sidebar" : "Hide Sidebar"}
        >
          <span className="text-sm font-bold">
            {searchParams.get("sidebar") === "collapsed" ? "⇀" : "↽"}
          </span>
        </LinkNext>
      ) : null}

      {/* Persistent Menu Button */}
      <LinkNext
        href="/admin/menu"
        className={`flex items-center gap-2 px-6 py-2 rounded-full transition-all ${
          isMenuPage
            ? "bg-blush/40 text-cocoa font-bold shadow-soft ring-1 ring-blush/20"
            : "text-text-muted hover:bg-beige/30 hover:text-cocoa"
        }`}
      >
        <span className="text-base">🧁</span>
        <span className="text-[11px] uppercase tracking-wider font-bold">Menu Studio</span>
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
    <div className="flex flex-col h-screen overflow-hidden bg-cream">
      {/* Top Navbar: Light Glassmorphism */}
      <header className="h-16 glass-ivory flex items-center justify-between px-8 z-50">
        <div className="flex items-center gap-12">
          <div className="flex flex-col">
            <h2 className="font-heading text-lg text-cocoa tracking-[4px] m-0 leading-none">SONNA&apos;S</h2>
            <p className="text-[9px] uppercase tracking-[4px] text-gold mt-1 m-0 opacity-80 font-medium">Pâtisserie & Café</p>
          </div>

          <Suspense fallback={<div className="text-text-muted text-xs">Loading...</div>}>
            <AdminNavbar />
          </Suspense>
        </div>

        <div className="flex items-center gap-8">
          <LinkNext
            href="/"
            className="text-[10px] uppercase tracking-widest text-text-muted hover:text-gold transition-colors font-medium"
          >
            ← Public Boutique
          </LinkNext>
          <div className="flex items-center gap-3 pl-6 border-l border-border/60">
            <div className="text-right">
              <p className="text-[10px] font-bold text-cocoa m-0 uppercase tracking-tighter">Administrator</p>
              <p className="text-[9px] text-text-muted m-0">Studio Access</p>
            </div>
            <div className="w-9 h-9 rounded-full bg-beige border border-border flex items-center justify-center text-cocoa font-heading font-bold shadow-soft">
              S
            </div>
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

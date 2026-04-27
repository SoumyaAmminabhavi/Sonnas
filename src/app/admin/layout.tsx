"use client";

import { useState } from "react";
import { usePathname } from "next/navigation";
import LinkNext from "next/link";

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const [isCollapsed, setIsCollapsed] = useState(false);

  const navItems = [
    { name: "Orders", href: "/admin/whatsapp", icon: "📋" },
    { name: "Menu", href: "/admin/menu", icon: "🧁" },
  ];

  // Logic for the second sidebar (Sub-navigation)
  const isOrdersPage = pathname.startsWith("/admin/whatsapp");
  const isMenuPage = pathname.startsWith("/admin/menu");

  return (
    <div className="flex h-screen bg-[#FFF9F7] overflow-hidden">
      {/* ─── Sidebar 1: Main Navigation (Slim) ────────────────── */}
      <aside 
        className={`bg-[#1A1A1A] text-white flex flex-col transition-all duration-300 ease-in-out z-30 shadow-2xl ${
          isCollapsed ? "w-[72px]" : "w-64"
        }`}
      >
        {/* Logo & Toggle */}
        <div className={`p-6 flex items-center justify-between border-b border-white/5 h-24 ${isCollapsed ? "justify-center" : ""}`}>
          {!isCollapsed && (
            <div className="animate-in fade-in duration-500">
              <h2 className="font-heading text-xl text-[#F4C2C2] tracking-[0.2em]">SONNA&apos;S</h2>
              <p className="text-[10px] uppercase tracking-[3px] text-[#9A9A9A] mt-1">Admin Panel</p>
            </div>
          )}
          {isCollapsed && (
            <h2 className="font-heading text-2xl text-[#F4C2C2]">S</h2>
          )}
        </div>

        {/* Main Links */}
        <nav className="flex-1 px-3 py-6 space-y-2">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <LinkNext
                key={item.name}
                href={item.href}
                className={`flex items-center gap-4 px-4 py-3 rounded-xl transition-all duration-200 group relative ${
                  isActive
                    ? "bg-[#F4C2C2] text-[#1A1A1A] font-bold shadow-[0_8px_20px_rgba(244,194,194,0.3)]"
                    : "text-[#9A9A9A] hover:bg-white/5 hover:text-white"
                } ${isCollapsed ? "justify-center px-0 h-12 w-12 mx-auto" : ""}`}
                title={isCollapsed ? item.name : ""}
              >
                <span className="text-xl">{item.icon}</span>
                {!isCollapsed && (
                  <span className="text-sm font-medium tracking-wide">{item.name}</span>
                )}
                {isCollapsed && isActive && (
                  <div className="absolute left-0 w-1 h-6 bg-[#F4C2C2] rounded-r-full" />
                )}
              </LinkNext>
            );
          })}
        </nav>

        {/* Bottom Actions */}
        <div className="p-4 border-t border-white/5 space-y-2">
          <button 
            onClick={() => setIsCollapsed(!isCollapsed)}
            className={`w-full flex items-center gap-4 px-4 py-3 rounded-xl text-[#9A9A9A] hover:bg-white/5 hover:text-[#F4C2C2] transition-all ${
              isCollapsed ? "justify-center px-0 h-12 w-12 mx-auto" : ""
            }`}
            title={isCollapsed ? "Expand Sidebar" : "Collapse Sidebar"}
          >
            <span className="text-xl">{isCollapsed ? "≫" : "≪"}</span>
            {!isCollapsed && <span className="text-xs uppercase tracking-widest font-semibold">Collapse</span>}
          </button>

          <LinkNext
            href="/"
            className={`flex items-center gap-4 px-4 py-3 rounded-xl text-[#9A9A9A] hover:text-[#F4C2C2] transition-colors ${
              isCollapsed ? "justify-center px-0 h-12 w-12 mx-auto" : ""
            }`}
            title="Back to Website"
          >
            <span className="text-xl">🏠</span>
            {!isCollapsed && <span className="text-xs uppercase tracking-widest font-semibold">Website</span>}
          </LinkNext>
        </div>
      </aside>

      {/* ─── Sidebar 2: Contextual Sub-Nav ──────────────────── */}
      <aside className="w-72 bg-[#FFFFFF] border-r border-[#E8DED4] flex flex-col z-20 shadow-sm overflow-y-auto">
        <div className="h-24 flex flex-col justify-center px-8 border-b border-[#F7F3EF]">
          <h3 className="font-heading text-lg text-[#2B2B2B]">
            {isOrdersPage ? "Orders Management" : isMenuPage ? "Menu & Catalog" : "Dashboard"}
          </h3>
          <p className="text-[11px] uppercase tracking-wider text-[#9A9A9A] mt-1">
            {isOrdersPage ? "WhatsApp Automation" : isMenuPage ? "Product Control" : "Overview"}
          </p>
        </div>

        <div className="flex-1 p-6">
          {isOrdersPage && (
            <div className="space-y-8">
              <div>
                <h4 className="text-[11px] uppercase tracking-[2px] font-bold text-[#F4C2C2] mb-4">Status Filters</h4>
                <div className="space-y-1">
                  <p className="text-sm text-[#2B2B2B] font-medium p-2 hover:bg-[#FFF9F7] rounded-lg cursor-pointer transition-colors">All Orders</p>
                  <p className="text-sm text-[#6E6E6E] p-2 hover:bg-[#FFF9F7] rounded-lg cursor-pointer transition-colors">Pending (8)</p>
                  <p className="text-sm text-[#6E6E6E] p-2 hover:bg-[#FFF9F7] rounded-lg cursor-pointer transition-colors">Confirmed</p>
                  <p className="text-sm text-[#6E6E6E] p-2 hover:bg-[#FFF9F7] rounded-lg cursor-pointer transition-colors">Preparing</p>
                  <p className="text-sm text-[#6E6E6E] p-2 hover:bg-[#FFF9F7] rounded-lg cursor-pointer transition-colors">Delivered</p>
                </div>
              </div>
              <div>
                <h4 className="text-[11px] uppercase tracking-[2px] font-bold text-[#F4C2C2] mb-4">Quick Actions</h4>
                <div className="space-y-3">
                  <button className="w-full py-3 px-4 bg-[#2B2B2B] text-white text-xs font-bold rounded-xl shadow-md hover:bg-black transition-all">Export Report</button>
                  <button className="w-full py-3 px-4 border border-[#E8DED4] text-[#2B2B2B] text-xs font-bold rounded-xl hover:bg-[#FFF9F7] transition-all">Broadcast Msg</button>
                </div>
              </div>
            </div>
          )}

          {isMenuPage && (
            <div className="space-y-8">
              <div>
                <h4 className="text-[11px] uppercase tracking-[2px] font-bold text-[#F4C2C2] mb-4">Categories</h4>
                <div className="space-y-1">
                  <p className="text-sm text-[#2B2B2B] font-medium p-2 hover:bg-[#FFF9F7] rounded-lg cursor-pointer transition-colors">Signature Cakes</p>
                  <p className="text-sm text-[#6E6E6E] p-2 hover:bg-[#FFF9F7] rounded-lg cursor-pointer transition-colors">Tea Time</p>
                  <p className="text-sm text-[#6E6E6E] p-2 hover:bg-[#FFF9F7] rounded-lg cursor-pointer transition-colors">Cupcakes</p>
                </div>
              </div>
              <div className="p-4 bg-[#FFF9F7] rounded-2xl border border-[#F4C2C2]/20">
                <p className="text-[10px] text-[#9A9A9A] uppercase tracking-wider mb-2">Inventory Stats</p>
                <div className="flex justify-between items-baseline">
                  <span className="text-2xl font-heading text-[#2B2B2B]">24</span>
                  <span className="text-xs text-[#5A8F5A] font-bold">Active Items</span>
                </div>
              </div>
            </div>
          )}

          {!isOrdersPage && !isMenuPage && (
            <div className="flex flex-col items-center justify-center py-20 text-center space-y-4">
              <span className="text-4xl opacity-20">🍰</span>
              <p className="text-sm text-[#9A9A9A]">Select a category to manage your patisserie.</p>
            </div>
          )}
        </div>
      </aside>

      {/* ─── Main Content ────────────────────────────────────── */}
      <main className="flex-1 h-screen overflow-y-auto bg-[#FFF9F7] relative">
        {/* Subtle shadow overlay for depth */}
        <div className="absolute inset-y-0 left-0 w-8 bg-gradient-to-r from-black/[0.02] to-transparent pointer-events-none" />
        {children}
      </main>
    </div>
  );
}

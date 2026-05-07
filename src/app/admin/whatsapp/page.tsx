"use client";

import React, { useState, useMemo, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Image from "next/image";
import { api } from "~/trpc/react";

// ─── Status Config ──────────────────────────────────────────────────────────

const STATUS_CONFIG: Record<
  string,
  { label: string; emoji: string; color: string; bg: string; border: string }
> = {
  PENDING: {
    label: "Awaiting Confirmation",
    emoji: "⏳",
    color: "#C9A27E",
    bg: "#FFF9F7",
    border: "#F0EBE4",
  },
  CONFIRMED: {
    label: "Confirmed",
    emoji: "✨",
    color: "#5A8F5A",
    bg: "#F4F9F4",
    border: "#E8F0E8",
  },
  PREPARING: {
    label: "Artisan Kitchen",
    emoji: "👨‍🍳",
    color: "#8B6FC0",
    bg: "#F7F5FB",
    border: "#EFECF6",
  },
  READY: {
    label: "Ready for Departure",
    emoji: "🎀",
    color: "#4A90D9",
    bg: "#F4F8FD",
    border: "#E8F0F9",
  },
  DELIVERED: {
    label: "Enjoyed",
    emoji: "💝",
    color: "#5A3E36",
    bg: "#F7F3EF",
    border: "#E8DED4",
  },
  CANCELLED: {
    label: "Cancelled",
    emoji: "✕",
    color: "#D88C8C",
    bg: "#FDF4F4",
    border: "#F9E8E8",
  },
};

const PAYMENT_STATUS_CONFIG: Record<
  string,
  { label: string; emoji: string; color: string; bg: string }
> = {
  PENDING: {
    label: "Unpaid",
    emoji: "⚪",
    color: "#9A9A9A",
    bg: "rgba(154,154,154,0.1)",
  },
  PAID: {
    label: "Paid",
    emoji: "💎",
    color: "#C9A27E",
    bg: "rgba(201,162,126,0.15)",
  },
  FAILED: {
    label: "Failed",
    emoji: "⚠️",
    color: "#D88C8C",
    bg: "rgba(216,140,140,0.1)",
  },
  REFUNDED: {
    label: "Refunded",
    emoji: "↩️",
    color: "#8B6FC0",
    bg: "rgba(139,111,192,0.1)",
  },
};

const STATUS_FLOW = [
  "PENDING",
  "CONFIRMED",
  "PREPARING",
  "READY",
  "DELIVERED",
] as const;

type OrderStatus =
  | "PENDING"
  | "CONFIRMED"
  | "PREPARING"
  | "READY"
  | "DELIVERED"
  | "CANCELLED";

interface AdminOrderItem {
  id: string;
  cakeName: string;
  size: string;
  price: string;
  quantity: number;
  image?: string | null;
}

interface AdminOrder {
  id: string;
  orderNumber: string;
  phone: string;
  customerName?: string | null;
  totalPrice?: string | null;
  status: OrderStatus;
  address?: string | null;
  notes?: string | null;
  deliveryDate?: string | null;
  deliveryTime?: string | null;
  customImageUrl?: string | null;
  createdAt: string | Date;
  items: AdminOrderItem[];
  isCustom?: boolean;
  paymentStatus: string;
}

// ─── Page ───────────────────────────────────────────────────────────────────

function WhatsAppAdminContent() {
  const [statusFilter, setStatusFilter] = useState<string>("ALL");
  const [customFilter, setCustomFilter] = useState<boolean>(false);
  const [dateFilter, setDateFilter] = useState<string>("ALL");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [filterByDelivery, setFilterByDelivery] = useState<boolean>(true);
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const [replyPhone, setReplyPhone] = useState<string | null>(null);
  const [replyText, setReplyText] = useState("");

  const searchParams = useSearchParams();
  const isSidebarCollapsed = searchParams.get("sidebar") === "collapsed";

  const { data: settings, refetch: refetchSettings } = api.whatsapp.getSettings.useQuery();
  const updateSetting = api.whatsapp.updateSetting.useMutation({
    onSuccess: () => refetchSettings(),
  });

  const statsQuery = api.whatsapp.getStats.useQuery(undefined, {
    refetchInterval: 15_000, // ADMIN-02: Auto-refresh every 15s
  });
  const { data: ordersData, refetch: refetchOrders, isLoading: ordersLoading } = 
    api.whatsapp.getOrders.useQuery({ 
      status: statusFilter === "ALL" ? undefined : statusFilter,
      customOnly: customFilter || undefined
    }, {
      refetchInterval: 15_000, // ADMIN-02: Auto-refresh every 15s
    });
  
  // ── Audio Alert Logic ───────────────────────────────────────────────────
  const lastOrderCount = React.useRef(0);
  React.useEffect(() => {
    if (ordersData?.orders && ordersData.orders.length > lastOrderCount.current) {
      if (lastOrderCount.current > 0) {
        // Play soft notification chime
        const audio = new Audio("https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3");
        audio.volume = 0.4;
        void audio.play().catch(() => null);
      }
      lastOrderCount.current = ordersData.orders.length;
    }
  }, [ordersData?.orders]);
  
  const { data: conversations, refetch: refetchConvos } = 
    api.whatsapp.getConversations.useQuery({ limit: 50 }, {
      refetchInterval: 30_000,
    });

  const stats = statsQuery.data;

  const updateStatus = api.whatsapp.updateOrderStatus.useMutation({
    onSuccess: () => refetchOrders(),
  });

  const sendMessage = api.whatsapp.sendMessage.useMutation({
    onSuccess: () => {
      setReplyText("");
      setReplyPhone(null);
      void refetchConvos();
    },
  });

  const filteredOrders = useMemo(() => {
    if (!ordersData?.orders) return [];
    let filtered = ordersData.orders;
    
    // ADMIN-03: Search filter
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      filtered = filtered.filter(o => {
        const order = o as unknown as AdminOrder;
        return (
          order.orderNumber.toLowerCase().includes(q) ||
          (order.customerName?.toLowerCase().includes(q) ?? false) ||
          order.phone.includes(q)
        );
      });
    }
    
    // ADMIN-04: Date filter (supports both order date and delivery date)
    if (dateFilter !== "ALL") {
      const today = new Date();
      const todayStr = today.toISOString().split('T')[0];
      
      // Normalize dateFilter to YYYY-MM-DD if it's in DD-MM-YYYY
      let normalizedFilter = dateFilter;
      if (dateFilter.includes('-') && dateFilter.split('-')[0]?.length === 2) {
        const [d, m, y] = dateFilter.split('-');
        normalizedFilter = `${y}-${m}-${d}`;
      }

      if (dateFilter === "TODAY") {
        filtered = filtered.filter(o => {
          const order = o as unknown as AdminOrder;
          if (filterByDelivery && order.deliveryDate) {
            return order.deliveryDate.includes(todayStr ?? "") || order.deliveryDate.toLowerCase().includes("today");
          }
          return new Date(o.createdAt).toISOString().split('T')[0] === todayStr;
        });
      } else if (dateFilter === "TOMORROW") {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const tomorrowStr = tomorrow.toISOString().split('T')[0];
        filtered = filtered.filter(o => {
          const order = o as unknown as AdminOrder;
          if (filterByDelivery && order.deliveryDate) {
            return order.deliveryDate.includes(tomorrowStr ?? "") || order.deliveryDate.toLowerCase().includes("tomorrow");
          }
          return new Date(o.createdAt).toISOString().split('T')[0] === tomorrowStr;
        });
      } else {
        filtered = filtered.filter(o => {
          const order = o as unknown as AdminOrder;
          const orderCreatedDate = new Date(o.createdAt).toISOString().split('T')[0];
          
          if (filterByDelivery && order.deliveryDate) {
            return order.deliveryDate.includes(normalizedFilter) || order.deliveryDate.includes(dateFilter);
          }
          return orderCreatedDate === normalizedFilter || orderCreatedDate === dateFilter;
        });
      }
    }
    
    return [...filtered].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }, [ordersData?.orders, dateFilter, searchQuery, filterByDelivery]);

  return (
    <div style={styles.container}>
      {/* ─── Sidebar ─────────────────────────────────────────── */}
      <aside
        style={{
          ...styles.sidebar,
          width: isSidebarCollapsed ? 0 : 280,
          opacity: isSidebarCollapsed ? 0 : 1,
          pointerEvents: isSidebarCollapsed ? "none" : "auto",
        }}
      >
        <div style={styles.sidebarHeader}>
           <h2 style={styles.sidebarTitle}>Order Studio</h2>
           <p style={styles.sidebarSubtitle}>Managing Sonna&apos;s Boutique</p>
        </div>

        <nav style={styles.filterNav}>
          <button
            style={{
              ...styles.filterBtn,
              ...(statusFilter === "ALL" && !customFilter ? styles.filterBtnActive : {}),
            }}
            onClick={() => {
              setStatusFilter("ALL");
              setCustomFilter(false);
            }}
          >
            <span style={styles.filterIcon}>📋</span>
            <span style={styles.filterLabel}>All Orders</span>
          </button>
          <button
            style={{
              ...styles.filterBtn,
              ...(customFilter ? styles.filterBtnActive : {}),
            }}
            onClick={() => {
              setCustomFilter(!customFilter);
              setStatusFilter("ALL");
            }}
          >
            <span style={styles.filterIcon}>🎨</span>
            <span style={styles.filterLabel}>Custom Requests</span>
          </button>
          
          <div style={styles.filterSeparator}>Statuses</div>

          {STATUS_FLOW.map((s) => {
            const cfg = STATUS_CONFIG[s]!;
            return (
              <button
                key={s}
                style={{
                  ...styles.filterBtn,
                  ...(statusFilter === s ? styles.filterBtnActive : {}),
                }}
                onClick={() => {
                  setStatusFilter(s);
                  setCustomFilter(false);
                }}
              >
                <span style={styles.filterIcon}>{cfg.emoji}</span>
                <span style={styles.filterLabel}>{cfg.label}</span>
              </button>
            );
          })}
          <button
            style={{
              ...styles.filterBtn,
              ...(statusFilter === "CANCELLED" ? styles.filterBtnActive : {}),
            }}
            onClick={() => {
              setStatusFilter("CANCELLED");
              setCustomFilter(false);
            }}
          >
            <span style={styles.filterIcon}>✕</span>
            <span style={styles.filterLabel}>Cancelled</span>
          </button>
        </nav>

        <div style={styles.convSection}>
          <h3 style={styles.convTitle}>Recent Inquiries</h3>
          <div style={styles.convList}>
            {conversations?.map((c) => (
              <div key={c.id} style={styles.convItem} onClick={() => setReplyPhone(c.phone)}>
                <div style={styles.convAvatar}>
                  {(c.name ?? c.phone).charAt(0).toUpperCase()}
                </div>
                <div style={styles.convInfo}>
                  <span style={styles.convName}>{c.name ?? "Guest"}</span>
                  <span style={styles.convPhone}>{c.phone}</span>
                </div>
                <div style={styles.convAction}>
                   <span className="text-gold text-[10px]">REPLY</span>
                </div>
              </div>
            ))}
            {(!conversations || conversations.length === 0) && (
              <p style={styles.emptyText}>No recent chats</p>
            )}
          </div>
        </div>

        <div style={styles.sidebarFooter}>
           <div style={styles.maintenanceRow}>
              <div style={styles.maintenanceInfo}>
                 <span style={styles.maintenanceLabel}>Maintenance Mode</span>
                 <span style={styles.maintenanceStatus}>
                    {settings?.MAINTENANCE_MODE === "true" ? "Bot Paused" : "Bot Active"}
                 </span>
              </div>
              <button
                onClick={() => updateSetting.mutate({ 
                  key: "MAINTENANCE_MODE", 
                  value: settings?.MAINTENANCE_MODE === "true" ? "false" : "true" 
                })}
                style={{
                  ...styles.toggleBtn,
                  backgroundColor: settings?.MAINTENANCE_MODE === "true" ? "#D88C8C" : "#E8DED4",
                }}
              >
                <div style={{
                  ...styles.toggleCircle,
                  transform: settings?.MAINTENANCE_MODE === "true" ? "translateX(20px)" : "translateX(0)",
                }} />
              </button>
           </div>
        </div>
      </aside>

      {/* ─── Main Content ────────────────────────────────────── */}
      <main style={styles.main}>
        <div style={styles.statsBar}>
          <StatCard label="Today's Orders" value={stats?.todaysOrders ?? 0} icon="🧁" />
          <StatCard label="Pending Confirmation" value={stats?.pendingOrders ?? 0} icon="⌛" highlight />
          <StatCard label="Revenue" value={`₹${(stats?.totalRevenue ?? 0).toLocaleString("en-IN")}`} icon="✨" />
          
          {/* Revenue Trend Chart */}
          <div style={styles.trendCard}>
            <div style={styles.trendHeader}>
               <span style={styles.statLabel}>7-Day Trend</span>
               <span style={styles.trendIndicator}>GROWTH</span>
            </div>
            <div style={styles.trendChart}>
               {stats?.revenueTrend?.map((day, i) => {
                 const max = Math.max(...stats.revenueTrend.map(d => d.revenue), 100);
                 const height = (day.revenue / max) * 100;
                 return (
                   <div key={i} style={styles.trendColumn} title={`${day.date}: ₹${day.revenue}`}>
                      <div style={{ ...styles.trendBar, height: `${Math.max(height, 5)}%` }} />
                      <span style={styles.trendDate}>{day.date.split(' ')[0]}</span>
                   </div>
                 );
               })}
            </div>
          </div>

          <StatCard label="Guests" value={stats?.totalConversations ?? 0} icon="👥" />
        </div>

        <div style={styles.tableWrapper}>
          <div style={styles.tableHeader}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              <h2 style={styles.tableTitle}>
                {statusFilter !== "ALL" ? `${STATUS_CONFIG[statusFilter]?.label} Orders` : "Recent Orders"}
              </h2>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginLeft: 8 }}>
                <button
                  onClick={() => setFilterByDelivery(!filterByDelivery)}
                  style={{
                    ...styles.datePicker,
                    cursor: 'pointer',
                    fontSize: 10,
                    padding: '4px 10px',
                    backgroundColor: filterByDelivery ? 'rgba(201,162,126,0.15)' : 'transparent',
                    border: '1px solid #E8DED4',
                    borderRadius: 6,
                    color: '#5A3E36',
                    whiteSpace: 'nowrap' as const,
                  }}
                  title={filterByDelivery ? 'Filtering by delivery date' : 'Filtering by order date'}
                >
                  {filterByDelivery ? '📅 Delivery' : '📋 Ordered'}
                </button>
                <input 
                  type="date" 
                  value={dateFilter === "ALL" || dateFilter === "TODAY" || dateFilter === "TOMORROW" ? "" : dateFilter}
                  onChange={(e) => setDateFilter(e.target.value || "ALL")}
                  style={styles.datePicker}
                />
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <input
                type="text"
                placeholder="Search order, name, phone..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  padding: '6px 14px',
                  borderRadius: 8,
                  border: '1px solid #E8DED4',
                  fontSize: 12,
                  fontFamily: 'inherit',
                  color: '#5A3E36',
                  backgroundColor: 'rgba(255,249,247,0.6)',
                  outline: 'none',
                  width: 200,
                  transition: 'border-color 0.2s',
                }}
              />
              <span style={styles.orderCount}>{filteredOrders.length} collections</span>
            </div>
          </div>

          {ordersLoading ? (
            <div style={styles.loading}>Preparing the studio...</div>
          ) : filteredOrders.length === 0 ? (
            <div style={styles.emptyState}>
              <span style={{ fontSize: 40, opacity: 0.5 }}>🧁</span>
              <p style={styles.emptyText}>The studio is currently quiet</p>
              <p style={styles.emptySubtext}>Upcoming orders will appear here.</p>
            </div>
          ) : (
            <div style={styles.orderGrid}>
              {filteredOrders.map((order) => {
                const cfg = STATUS_CONFIG[order.status] ?? STATUS_CONFIG.PENDING!;
                const isSelected = selectedOrderId === order.id;
                const o = order as unknown as AdminOrder;

                return (
                  <div
                    key={order.id}
                    style={{ ...styles.orderCard, ...(isSelected ? styles.orderCardSelected : {}) }}
                    onClick={() => setSelectedOrderId(isSelected ? null : order.id)}
                  >
                    <div style={styles.orderCardHeader}>
                      <div style={styles.orderIdentity}>
                        <span style={styles.orderNumber}>#{o.orderNumber}</span>
                        <span style={styles.orderTimestamp}>
                          {new Date(o.createdAt).toLocaleTimeString("en-IN", { hour: '2-digit', minute: '2-digit' })}
                        </span>
                      </div>
                      <div style={styles.badges}>
                        <span style={{ ...styles.statusBadge, color: cfg.color, backgroundColor: cfg.bg, borderColor: cfg.border }}>
                          {cfg.label}
                        </span>
                        {(() => {
                          const pCfg = PAYMENT_STATUS_CONFIG[o.paymentStatus] ?? PAYMENT_STATUS_CONFIG.PENDING!;
                          return (
                            <span style={{ ...styles.paymentBadge, color: pCfg.color, backgroundColor: pCfg.bg }}>
                              {pCfg.label}
                            </span>
                          );
                        })()}
                      </div>
                    </div>

                    <div style={styles.productInfo}>
                      <h3 style={styles.cakeNameMain}>
                        {o.items && o.items.length > 0 
                          ? (o.items.length > 1 ? `${o.items[0]?.cakeName} & More` : o.items[0]?.cakeName)
                          : "Artisanal Selection"}
                      </h3>
                      {o.isCustom && <span style={styles.customTag}>Custom Creation</span>}
                    </div>

                    <div style={styles.orderDetailsCompact}>
                      <div style={styles.detailItem}>
                        <span style={styles.detailIcon}>👤</span>
                        <span style={styles.detailText}>{o.customerName ?? "Guest"}</span>
                      </div>
                      <div style={styles.detailItem}>
                        <span style={styles.detailIcon}>📅</span>
                        <span style={styles.detailText}>
                          {(() => {
                            if (!o.deliveryDate) return "Today";
                            if (o.deliveryDate.includes(",")) return o.deliveryDate.split(',')[0];
                            const date = new Date(o.deliveryDate);
                            return isNaN(date.getTime()) ? o.deliveryDate : date.toLocaleDateString("en-IN", { weekday: 'short', day: 'numeric', month: 'short' });
                          })()}
                        </span>
                      </div>
                      <div style={styles.detailItem}>
                        <span style={styles.detailIcon}>🕒</span>
                        <span style={styles.detailText}>{o.deliveryTime ?? "Anytime"}</span>
                      </div>
                    </div>

                    {isSelected && (
                      <div style={styles.expandedContent}>
                        <div style={styles.itemList}>
                          {o.items.map(item => (
                            <div key={item.id} style={styles.productRow}>
                              {item.image && (
                                <div style={styles.productThumb}>
                                  <Image src={item.image} alt={item.cakeName} width={48} height={48} unoptimized />
                                </div>
                              )}
                              <div style={styles.productMeta}>
                                <p style={styles.productName}>{item.cakeName}</p>
                                <p style={styles.productSpec}>{item.size} • {item.price}</p>
                              </div>
                              <div style={styles.productQty}>×{item.quantity}</div>
                            </div>
                          ))}
                        </div>

                        {o.address && (
                          <div style={styles.addressSection}>
                            <p style={styles.sectionLabel}>Boutique Destination</p>
                            <div style={styles.addressBox}>
                              <span style={styles.addressText}>{o.address.split('\n')[0]}</span>
                              {o.address.includes('https://') && (
                                <a href={o.address.split('🔗').pop()?.trim()} target="_blank" rel="noreferrer" style={styles.mapPill}>
                                  View Map
                                </a>
                              )}
                            </div>
                          </div>
                        )}

                        {o.notes && (
                          <div style={styles.notesSection}>
                            <p style={styles.sectionLabel}>Client Notes</p>
                            <p style={styles.notesBody}>“{o.notes}”</p>
                          </div>
                        )}

                        {o.isCustom && o.customImageUrl && (
                          <div style={styles.imagePreview}>
                            {o.customImageUrl.split(',').map((url, idx) => (
                              <Image
                                key={idx}
                                src={url.trim()}
                                alt={`Custom Reference ${idx + 1}`}
                                style={styles.previewImg}
                                width={180}
                                height={140}
                                unoptimized
                              />
                            ))}
                          </div>
                        )}

                        <div style={styles.cardActions}>
                          <div style={styles.actionGrid}>
                            {STATUS_FLOW.filter(s => s !== order.status).slice(0, 3).map(s => {
                              const sCfg = STATUS_CONFIG[s]!;
                              return (
                                <button
                                  key={s}
                                  style={{ ...styles.actionPill, backgroundColor: sCfg.bg, color: sCfg.color, borderColor: sCfg.border }}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    if (confirm(`Update to "${sCfg.label}"? This will notify the customer via WhatsApp.`)) {
                                      updateStatus.mutate({ id: order.id, status: s as OrderStatus, notifyCustomer: true });
                                    }
                                  }}
                                >
                                  {sCfg.label}
                                </button>
                              );
                            })}
                          </div>
                          <div style={styles.footerActions}>
                            <button style={styles.secondaryAction} onClick={(e) => { e.stopPropagation(); setReplyPhone(order.phone); }}>
                              Contact Client
                            </button>
                            <button 
                              style={styles.cancelAction} 
                              onClick={(e) => {
                                e.stopPropagation();
                                if(confirm("Cancel this artisanal order?")) {
                                  updateStatus.mutate({ id: order.id, status: "CANCELLED", notifyCustomer: true });
                                }
                              }}
                            >
                              Cancel Order
                            </button>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </main>

      {/* ─── Reply Modal ─────────────────────────────────────── */}
      {replyPhone && (
        <div style={styles.modalOverlay} onClick={() => setReplyPhone(null)}>
          <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
            <h3 style={styles.modalTitle}>Client Correspondence</h3>
            <p style={styles.modalPhone}>Sending to: {replyPhone}</p>
            <textarea
              style={styles.modalTextarea}
              placeholder="Craft your message..."
              value={replyText}
              onChange={(e) => setReplyText(e.target.value)}
              rows={4}
            />
            <div style={styles.modalActions}>
              <button style={styles.modalCancel} onClick={() => setReplyPhone(null)}>Close</button>
              <button
                style={styles.modalSend}
                onClick={() => {
                  if (replyText.trim()) {
                    sendMessage.mutate({ phone: replyPhone, message: replyText.trim() });
                  }
                }}
                disabled={!replyText.trim() || sendMessage.isPending}
              >
                {sendMessage.isPending ? "Sending..." : "Send Message"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Stat Card ──────────────────────────────────────────────────────────────

function StatCard({ label, value, icon, highlight, isText }: { label: string; value: string | number; icon: string; highlight?: boolean; isText?: boolean; }) {
  return (
    <div style={{ ...styles.statCard, ...(highlight ? styles.statCardHighlight : {}) }}>
      <div style={styles.statIconWrapper}>
        <span style={styles.statEmoji}>{icon}</span>
      </div>
      <div style={styles.statContent}>
        <span style={{ ...styles.statValue, ...(isText ? { fontSize: 13, letterSpacing: '0' } : {}) }}>{value}</span>
        <span style={styles.statLabel}>{label}</span>
      </div>
    </div>
  );
}

export default function WhatsAppAdminPage() {
  return (
    <Suspense fallback={<div style={{ padding: 40, textAlign: "center", color: "#9A9A9A" }}>Loading orders...</div>}>
      <WhatsAppAdminContent />
    </Suspense>
  );
}

// ─── Styles (Luxury Sonna's Design System) ───────────────────────────────────

const styles: Record<string, React.CSSProperties> = {
  container: { display: "flex", height: "calc(100vh - 64px)", overflow: "hidden", backgroundColor: "#F7F3EF", fontFamily: "'Inter', sans-serif" },
  sidebar: { backgroundColor: "#FFF9F7", borderRight: "1px solid #F0EBE4", display: "flex", flexDirection: "column", flexShrink: 0, transition: "all 0.4s cubic-bezier(0.4, 0, 0.2, 1)", zIndex: 40, overflow: "hidden" },
  sidebarHeader: { padding: "32px 28px 24px" },
  sidebarTitle: { fontFamily: "'Playfair Display', serif", fontSize: "20px", fontWeight: "700", color: "#5A3E36", margin: 0, letterSpacing: "-0.02em" },
  sidebarSubtitle: { fontSize: "10px", textTransform: "uppercase", letterSpacing: "0.1em", color: "#C9A27E", marginTop: "4px", fontWeight: "600" },
  filterNav: { padding: "0 16px", display: "flex", flexDirection: "column", gap: "4px" },
  filterSeparator: { fontSize: "10px", textTransform: "uppercase", letterSpacing: "0.1em", color: "#9A9A9A", margin: "20px 12px 10px", fontWeight: "700" },
  filterBtn: { display: "flex", alignItems: "center", gap: "12px", padding: "10px 14px", borderRadius: "12px", border: "none", backgroundColor: "transparent", color: "#6E6E6E", fontSize: "13px", fontWeight: "500", textAlign: "left", cursor: "pointer", transition: "all 0.2s ease" },
  filterBtnActive: { backgroundColor: "#F4C2C220", color: "#5A3E36", fontWeight: "700" },
  filterIcon: { fontSize: "16px", width: "24px", display: "flex", justifyContent: "center" },
  filterLabel: { flex: 1 },
  convSection: { marginTop: "auto", padding: "24px 16px 32px", borderTop: "1px solid #F0EBE4" },
  convTitle: { fontSize: "11px", textTransform: "uppercase", letterSpacing: "0.08em", color: "#9A9A9A", padding: "0 12px", marginBottom: "16px", fontWeight: "700" },
  convList: { display: "flex", flexDirection: "column", gap: "8px" },
  convItem: { display: "flex", alignItems: "center", gap: "10px", padding: "8px 12px", borderRadius: "12px", cursor: "pointer", transition: "all 0.2s ease", border: "1px solid transparent" },
  convAvatar: { width: "32px", height: "32px", borderRadius: "50%", backgroundColor: "#E8DED4", color: "#5A3E36", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "12px", fontWeight: "700" },
  convInfo: { display: "flex", flexDirection: "column", flex: 1, minWidth: 0 },
  convName: { fontSize: "13px", fontWeight: "600", color: "#2B2B2B", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" },
  convPhone: { fontSize: "11px", color: "#9A9A9A" },
  convAction: { padding: "4px 8px", borderRadius: "8px", backgroundColor: "#F7F3EF" },
  main: { flex: 1, overflowY: "auto", padding: "32px 40px", scrollBehavior: "smooth" },
  statsBar: { display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: "20px", marginBottom: "40px" },
  statCard: { backgroundColor: "#FFFFFF", padding: "16px 20px", borderRadius: "20px", boxShadow: "0 2px 10px rgba(90, 62, 54, 0.03)", display: "flex", alignItems: "center", gap: "16px", border: "1px solid #F0EBE4" },
  statCardHighlight: { backgroundColor: "#FFF9F7", borderColor: "#F4C2C240" },
  statIconWrapper: { width: "44px", height: "44px", borderRadius: "14px", backgroundColor: "#F7F3EF", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "20px" },
  statContent: { display: "flex", flexDirection: "column" },
  statValue: { fontSize: "20px", fontWeight: "800", color: "#2B2B2B", fontFamily: "'Playfair Display', serif" },
  statLabel: { fontSize: "11px", color: "#9A9A9A", textTransform: "uppercase", letterSpacing: "0.05em", marginTop: "2px", fontWeight: "600" },
  statEmoji: {},
  tableWrapper: { maxWidth: "1100px" },
  tableHeader: { display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: "24px", padding: "0 4px" },
  tableTitle: { fontFamily: "'Playfair Display', serif", fontSize: "24px", color: "#5A3E36", margin: 0 },
  datePicker: { padding: "8px 16px", borderRadius: "12px", border: "1px solid #E8DED4", fontSize: "13px", color: "#5A3E36", backgroundColor: "#FFFFFF", outline: "none", boxShadow: "0 2px 5px rgba(0,0,0,0.02)" },
  orderCount: { fontSize: "12px", color: "#C9A27E", fontStyle: "italic", fontFamily: "'Playfair Display', serif" },
  orderGrid: { display: "flex", flexDirection: "column", gap: "16px" },
  orderCard: { backgroundColor: "#FFFFFF", borderRadius: "24px", padding: "24px", cursor: "pointer", transition: "all 0.4s cubic-bezier(0.4, 0, 0.2, 1)", border: "1px solid #F0EBE4", position: "relative", overflow: "hidden" },
  orderCardSelected: { boxShadow: "0 10px 30px rgba(90, 62, 54, 0.08)", borderColor: "#F4C2C2", transform: "translateY(-2px)" },
  orderCardHeader: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" },
  orderIdentity: { display: "flex", alignItems: "center", gap: "12px" },
  orderNumber: { fontSize: "12px", fontWeight: "800", color: "#C9A27E", letterSpacing: "0.05em" },
  orderTimestamp: { fontSize: "11px", color: "#9A9A9A", paddingLeft: "12px", borderLeft: "1px solid #F0EBE4" },
  badges: { display: "flex", gap: "8px" },
  statusBadge: { padding: "6px 14px", borderRadius: "30px", fontSize: "11px", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.05em", border: "1px solid" },
  paymentBadge: { padding: "6px 12px", borderRadius: "30px", fontSize: "10px", fontWeight: "700", textTransform: "uppercase" },
  productInfo: { display: "flex", alignItems: "center", gap: "16px", marginBottom: "12px" },
  cakeNameMain: { fontFamily: "'Playfair Display', serif", fontSize: "20px", color: "#2B2B2B", margin: 0, fontWeight: "700" },
  customTag: { fontSize: "10px", padding: "4px 8px", borderRadius: "6px", backgroundColor: "#FDF4F4", color: "#D88C8C", fontWeight: "700", textTransform: "uppercase" },
  orderDetailsCompact: { display: "flex", gap: "24px" },
  detailItem: { display: "flex", alignItems: "center", gap: "8px" },
  detailIcon: { fontSize: "14px", opacity: 0.6 },
  detailText: { fontSize: "13px", color: "#6E6E6E", fontWeight: "500" },
  expandedContent: { marginTop: "24px", paddingTop: "24px", borderTop: "1px solid #F0EBE4", display: "flex", flexDirection: "column", gap: "20px" },
  itemList: { display: "flex", flexDirection: "column", gap: "12px", backgroundColor: "#F7F3EF", padding: "16px", borderRadius: "16px" },
  productRow: { display: "flex", alignItems: "center", gap: "16px" },
  productThumb: { width: "48px", height: "48px", borderRadius: "10px", overflow: "hidden", border: "1px solid #E8DED4" },
  productMeta: { flex: 1 },
  productName: { fontSize: "14px", fontWeight: "700", color: "#2B2B2B", margin: 0 },
  productSpec: { fontSize: "12px", color: "#9A9A9A", margin: 0 },
  productQty: { fontSize: "14px", fontWeight: "800", color: "#5A3E36" },
  addressSection: { padding: "0 4px" },
  sectionLabel: { fontSize: "10px", textTransform: "uppercase", letterSpacing: "0.1em", color: "#C9A27E", marginBottom: "8px", fontWeight: "700" },
  addressBox: { display: "flex", justifyContent: "space-between", alignItems: "center", gap: "16px" },
  addressText: { fontSize: "13px", color: "#5A3E36", lineHeight: "1.5" },
  mapPill: { padding: "6px 14px", borderRadius: "30px", backgroundColor: "#F7F3EF", color: "#C9A27E", fontSize: "11px", fontWeight: "700", textDecoration: "none", border: "1px solid #E8DED4" },
  notesSection: { backgroundColor: "#FFF9F7", padding: "16px", borderRadius: "16px", border: "1px dotted #F4C2C2" },
  notesBody: { fontSize: "13px", color: "#5A3E36", fontStyle: "italic", margin: 0 },
  imagePreview: { marginTop: 12, marginBottom: 12, display: "flex", flexDirection: "row", gap: 10, flexWrap: "wrap" },
  previewImg: { borderRadius: 10, overflow: "hidden", border: "1px solid #E8DED4", objectFit: "cover", backgroundColor: "#F7F3EF", boxShadow: "0 2px 12px rgba(0,0,0,0.08)" },
  cardActions: { marginTop: "8px", display: "flex", flexDirection: "column", gap: "16px" },
  actionGrid: { display: "flex", gap: "8px", flexWrap: "wrap" },
  actionPill: { padding: "10px 20px", borderRadius: "30px", fontSize: "12px", fontWeight: "700", border: "1px solid", cursor: "pointer", transition: "all 0.2s ease" },
  footerActions: { display: "flex", justifyContent: "space-between", alignItems: "center", paddingTop: "16px", borderTop: "1px solid #F0EBE4" },
  secondaryAction: { background: "none", border: "none", color: "#C9A27E", fontSize: "12px", fontWeight: "700", cursor: "pointer", textTransform: "uppercase", letterSpacing: "0.05em" },
  cancelAction: { background: "none", border: "none", color: "#D88C8C", fontSize: "11px", fontWeight: "600", cursor: "pointer" },
  modalOverlay: { position: "fixed", top: 0, left: 0, right: 0, bottom: 0, backgroundColor: "rgba(90, 62, 54, 0.4)", backdropFilter: "blur(4px)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000 },
  modal: { backgroundColor: "#FFFFFF", borderRadius: "32px", padding: "40px", width: "100%", maxWidth: "500px", boxShadow: "0 20px 50px rgba(0,0,0,0.15)", border: "1px solid #F0EBE4" },
  modalTitle: { fontFamily: "'Playfair Display', serif", fontSize: "24px", color: "#5A3E36", margin: "0 0 8px 0" },
  modalPhone: { fontSize: "13px", color: "#C9A27E", marginBottom: "24px", fontWeight: "600" },
  modalTextarea: { width: "100%", padding: "16px", borderRadius: "16px", border: "1px solid #E8DED4", fontSize: "14px", color: "#2B2B2B", outline: "none", resize: "none", backgroundColor: "#F7F3EF", marginBottom: "24px" },
  modalActions: { display: "flex", justifyContent: "flex-end", gap: "12px" },
  modalCancel: { padding: "12px 24px", borderRadius: "30px", border: "1px solid #E8DED4", backgroundColor: "transparent", color: "#9A9A9A", fontSize: "13px", fontWeight: "700", cursor: "pointer" },
  modalSend: { padding: "12px 32px", borderRadius: "30px", border: "none", backgroundColor: "#C9A27E", color: "#FFFFFF", fontSize: "13px", fontWeight: "700", cursor: "pointer", boxShadow: "0 4px 10px rgba(201, 162, 126, 0.3)" },
  loading: { padding: 40, textAlign: "center", color: "#C9A27E", fontStyle: "italic" },
  emptyState: { padding: 80, textAlign: "center" },
  emptyText: { fontSize: 18, color: "#5A3E36", fontWeight: "700", fontFamily: "'Playfair Display', serif", marginTop: 16 },
  emptySubtext: { fontSize: "12px", color: "#9A9A9A", marginTop: "4px" },

  // New Styles for Sprint 6
  sidebarFooter: { padding: "20px 24px", borderTop: "1px solid #F0EBE4", marginTop: "auto" },
  maintenanceRow: { display: "flex", alignItems: "center", justifyContent: "space-between", gap: "12px" },
  maintenanceInfo: { display: "flex", flexDirection: "column" },
  maintenanceLabel: { fontSize: "11px", fontWeight: "700", color: "#5A3E36", textTransform: "uppercase", letterSpacing: "0.05em" },
  maintenanceStatus: { fontSize: "10px", color: "#9A9A9A", marginTop: "2px" },
  toggleBtn: { width: "42px", height: "22px", borderRadius: "20px", border: "none", position: "relative", cursor: "pointer", transition: "all 0.3s ease", padding: "3px" },
  toggleCircle: { width: "16px", height: "16px", borderRadius: "50%", backgroundColor: "#FFF", transition: "all 0.3s ease", boxShadow: "0 2px 4px rgba(0,0,0,0.1)" },
  
  trendCard: { backgroundColor: "#FFF", borderRadius: "20px", padding: "18px 20px", border: "1px solid #F0EBE4", display: "flex", flexDirection: "column", gap: "10px", flex: 1, minWidth: "180px" },
  trendHeader: { display: "flex", justifyContent: "space-between", alignItems: "center" },
  trendIndicator: { fontSize: "8px", fontWeight: "800", color: "#5A8F5A", backgroundColor: "#F4F9F4", padding: "2px 6px", borderRadius: "4px" },
  trendChart: { display: "flex", alignItems: "flex-end", gap: "6px", height: "40px", padding: "2px 0" },
  trendColumn: { display: "flex", flexDirection: "column", alignItems: "center", flex: 1, gap: "4px" },
  trendBar: { width: "100%", backgroundColor: "#E8DED4", borderRadius: "2px", transition: "height 0.6s ease" },
  trendDate: { fontSize: "7px", color: "#9A9A9A", fontWeight: "600" },
};
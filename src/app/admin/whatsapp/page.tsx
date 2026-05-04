"use client";

import { useState, useMemo, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Image from "next/image";
import { api } from "~/trpc/react";

// ─── Status Config ──────────────────────────────────────────────────────────

const STATUS_CONFIG: Record<
  string,
  { label: string; emoji: string; color: string; bg: string }
> = {
  PENDING: {
    label: "Pending",
    emoji: "🕐",
    color: "#C9A27E",
    bg: "rgba(201,162,126,0.12)",
  },
  CONFIRMED: {
    label: "Confirmed",
    emoji: "✅",
    color: "#5A8F5A",
    bg: "rgba(90,143,90,0.12)",
  },
  PREPARING: {
    label: "Preparing",
    emoji: "👩‍🍳",
    color: "#8B6FC0",
    bg: "rgba(139,111,192,0.12)",
  },
  READY: {
    label: "Ready",
    emoji: "📦",
    color: "#4A90D9",
    bg: "rgba(74,144,217,0.12)",
  },
  DELIVERED: {
    label: "Delivered",
    emoji: "🎉",
    color: "#5A3E36",
    bg: "rgba(90,62,54,0.12)",
  },
  CANCELLED: {
    label: "Cancelled",
    emoji: "❌",
    color: "#D88C8C",
    bg: "rgba(216,140,140,0.12)",
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
  customImageUrl?: string | null;
  createdAt: string | Date;
  items: AdminOrderItem[];
  isCustom?: boolean;
}

// ─── Page ───────────────────────────────────────────────────────────────────

function WhatsAppAdminContent() {
  const [statusFilter, setStatusFilter] = useState<string>("ALL");
  const [customFilter, setCustomFilter] = useState<boolean>(false);
  const [dateFilter, setDateFilter] = useState<string>("ALL");
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const [replyPhone, setReplyPhone] = useState<string | null>(null);
  const [replyText, setReplyText] = useState("");

  const searchParams = useSearchParams();
  const isSidebarCollapsed = searchParams.get("sidebar") === "collapsed";

  const statsQuery = api.whatsapp.getStats.useQuery();
  const { data: ordersData, refetch: refetchOrders, isLoading: ordersLoading } = 
    api.whatsapp.getOrders.useQuery({ 
      status: statusFilter === "ALL" ? undefined : statusFilter,
      customOnly: customFilter || undefined
    });
  
  const { data: conversations, refetch: refetchConvos } = 
    api.whatsapp.getConversations.useQuery({ limit: 50 });

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
    
    if (dateFilter !== "ALL") {
      if (dateFilter === "TODAY") {
        const todayStr = new Date().toISOString().split('T')[0];
        filtered = filtered.filter(o => new Date(o.createdAt).toISOString().split('T')[0] === todayStr);
      } else if (dateFilter === "TOMORROW") {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const tomorrowStr = tomorrow.toISOString().split('T')[0];
        filtered = filtered.filter(o => new Date(o.createdAt).toISOString().split('T')[0] === tomorrowStr);
      } else {
        // Handle calendar date picker (YYYY-MM-DD)
        filtered = filtered.filter(o => new Date(o.createdAt).toISOString().split('T')[0] === dateFilter);
      }
    }
    
    // Explicitly sort by createdAt descending
    return [...filtered].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }, [ordersData?.orders, dateFilter]);



  // ─── Handlers ──────────────────────────────────────────────────────────



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

        {/* Filter Tabs */}
        <nav style={styles.filterNav}>
          <button
            style={{
              ...styles.filterBtn,
              ...(statusFilter === "ALL" ? styles.filterBtnActive : {}),
            }}
            onClick={() => {
              setStatusFilter("ALL");
              setCustomFilter(false);
            }}
          >
            All Orders
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
            🎨 Custom Requests
          </button>
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
                {cfg.emoji} {cfg.label}
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
            ❌ Cancelled
          </button>

          <div style={{ marginTop: 20, padding: "0 12px" }}>
            {/* Date filter removed from here */}
          </div>
        </nav>

        {/* Recent Conversations */}
        <div style={styles.convSection}>
          <h3 style={styles.convTitle}>💬 Recent Chats</h3>
          <div style={styles.convList}>
            {conversations?.map((c) => (
              <div key={c.id} style={styles.convItem}>
                <div style={styles.convAvatar}>
                  {(c.name ?? c.phone).charAt(0).toUpperCase()}
                </div>
                <div style={styles.convInfo}>
                  <span style={styles.convName}>{c.name ?? "Unknown"}</span>
                  <span style={styles.convPhone}>{c.phone}</span>
                </div>
                <button
                  style={styles.convReplyBtn}
                  onClick={() => setReplyPhone(c.phone)}
                  title="Reply via WhatsApp"
                >
                  💬
                </button>
              </div>
            ))}
            {(!conversations || conversations.length === 0) && (
              <p style={styles.emptyText}>No conversations yet</p>
            )}
          </div>
        </div>
      </aside>

      {/* ─── Main Content ────────────────────────────────────── */}
      <main style={styles.main}>
        {/* Stats Bar */}
        <div style={styles.statsBar}>
          <StatCard
            label="Today's Orders"
            value={stats?.todaysOrders ?? 0}
            emoji="📋"
          />
          <StatCard
            label="Pending"
            value={stats?.pendingOrders ?? 0}
            emoji="🕐"
            highlight
          />
          <StatCard
            label="Total Orders"
            value={stats?.totalOrders ?? 0}
            emoji="📦"
          />
          <StatCard
            label="Revenue"
            value={`₹${(stats?.totalRevenue ?? 0).toLocaleString("en-IN")}`}
            emoji="💰"
          />
          <StatCard
            label="Customers"
            value={stats?.totalConversations ?? 0}
            emoji="👥"
          />
          <StatCard
            label="Most Popular"
            value={stats?.popularCake ?? "N/A"}
            emoji="⭐"
            isText
          />
        </div>

        {/* Orders Table */}
        <div style={styles.tableWrapper}>
          <div style={styles.tableHeader}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              <h2 style={styles.tableTitle}>
                {statusFilter !== "ALL"
                  ? `${STATUS_CONFIG[statusFilter]?.emoji} ${STATUS_CONFIG[statusFilter]?.label} Orders`
                  : "📋 All Orders"}
              </h2>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginLeft: 8 }}>
                <span style={{ fontSize: 13, color: '#9A9A9A' }}>📅</span>
                <input 
                  type="date" 
                  value={dateFilter === "ALL" || dateFilter === "TODAY" || dateFilter === "TOMORROW" ? "" : dateFilter}
                  onChange={(e) => setDateFilter(e.target.value || "ALL")}
                  style={{
                    padding: '6px 12px',
                    borderRadius: 8,
                    border: '1px solid #E8DED4',
                    fontSize: 13,
                    color: '#5A3E36',
                    outline: 'none',
                    backgroundColor: '#FFFFFF'
                  }}
                />
                {dateFilter !== "ALL" && (
                  <button 
                    onClick={() => setDateFilter("ALL")}
                    style={{
                      background: 'none',
                      border: 'none',
                      color: '#D88C8C',
                      fontSize: 12,
                      cursor: 'pointer',
                      padding: 4
                    }}
                  >
                    Clear
                  </button>
                )}
              </div>
            </div>
            <span style={styles.orderCount}>{filteredOrders.length} orders</span>
          </div>

          {ordersLoading ? (
            <div style={styles.loading}>Loading orders...</div>
          ) : filteredOrders.length === 0 ? (
            <div style={styles.emptyState}>
              <span style={{ fontSize: 48 }}>🧁</span>
              <p style={styles.emptyText}>No orders found</p>
              <p style={styles.emptySubtext}>
                Orders placed via WhatsApp will appear here
              </p>
            </div>
          ) : (
            <div style={styles.orderGrid}>
              {filteredOrders.map((order) => {
                const cfg = STATUS_CONFIG[order.status] ?? STATUS_CONFIG.PENDING!;
                const isSelected = selectedOrderId === order.id;

                return (
                  <div
                    key={order.id}
                    style={{
                      ...styles.orderCard,
                      ...(isSelected ? styles.orderCardSelected : {}),
                    }}
                    onClick={() =>
                      setSelectedOrderId(isSelected ? null : order.id)
                    }
                  >
                    {/* Explicitly cast to our typed interface */}
                    {(() => {
                      const o = order as unknown as AdminOrder;
                      return (
                        <>
                          <div style={styles.orderCardTop}>
                            <span style={styles.orderNumber}>
                              #{o.orderNumber}
                            </span>
                            <span
                              style={{
                                ...styles.statusPill,
                                color: cfg.color,
                                backgroundColor: cfg.bg,
                              }}
                            >
                              {cfg.emoji} {cfg.label}
                            </span>
                            {o.isCustom && (
                              <span
                                style={{
                                  ...styles.statusPill,
                                  color: "#D88C8C",
                                  backgroundColor: "rgba(216,140,140,0.12)",
                                  marginLeft: 8
                                }}
                              >
                                ✨ Custom Design
                              </span>
                            )}
                          </div>

                          <h3 style={styles.cakeName}>
                            {o.items && o.items.length > 0 
                              ? (o.items.length > 1 
                                  ? `${o.items[0]?.cakeName} (+${o.items.length - 1})` 
                                  : o.items[0]?.cakeName)
                              : "No Items"}
                          </h3>

                          <div style={styles.customerLine}>
                            <span style={styles.customerLabel}>Customer:</span>
                            <a 
                              href={`https://wa.me/${o.phone}`} 
                              target="_blank" 
                              rel="noreferrer"
                              style={styles.customerLink}
                            >
                              👤 {o.customerName ?? "Guest"} • 📞 {o.phone}
                            </a>
                          </div>

                          <div style={styles.orderMeta}>
                            <span>💰 {o.totalPrice ?? "Quote Pending"}</span>
                            <span>📦 {o.items ? o.items.reduce((sum, item) => sum + item.quantity, 0) : 0} items</span>
                          </div>

                          {isSelected && o.items && o.items.length > 0 && (
                            <div style={{ marginBottom: 12, padding: '8px 12px', backgroundColor: '#F9F9F9', borderRadius: 8, fontSize: 12, color: '#5A3E36', border: '1px solid #E8DED4' }}>
                              {o.items.map(item => (
                                <div key={item.id} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                                  <span>• {item.cakeName} ({item.size})</span>
                                  <span>x{item.quantity}</span>
                                </div>
                              ))}
                            </div>
                          )}
                          {o.address && (
                            <div style={styles.orderNotes}>
                              <span style={styles.notesIcon}>📍</span>
                              <div style={styles.notesText}>
                                {o.address.split('\n').map((line, i) => {
                                  if (line.includes('https://')) {
                                    const url = line.split('🔗').pop()?.trim() ?? line;
                                    return (
                                      <a 
                                        key={i} 
                                        href={url} 
                                        target="_blank" 
                                        rel="noreferrer" 
                                        style={{ 
                                          color: '#4A90D9', 
                                          textDecoration: 'underline', 
                                          display: 'inline-flex', 
                                          alignItems: 'center',
                                          gap: 4,
                                          marginTop: 4,
                                          fontWeight: 600
                                        }}
                                      >
                                        🔗 Open in Google Maps
                                      </a>
                                    );
                                  }
                                  return <div key={i}>{line}</div>;
                                })}
                              </div>
                            </div>
                          )}

                          {o.notes && (
                            <div style={styles.orderNotes}>
                              <span style={styles.notesIcon}>📝</span>
                              <span style={styles.notesText}>{o.notes}</span>
                            </div>
                          )}

                          {o.customImageUrl && (
                            <div style={styles.imagePreview}>
                              <Image
                                src={o.customImageUrl}
                                alt="Custom Cake Reference"
                                style={styles.previewImg}
                                width={200}
                                height={150}
                                unoptimized
                              />
                            </div>
                          )}

                          <div style={styles.orderFooter}>
                            <span style={styles.customerName}>
                              {o.customerName ?? o.phone}
                            </span>
                            <span style={styles.orderDate}>
                              {new Date(o.createdAt).toLocaleDateString("en-IN", {
                                day: "numeric",
                                month: "short",
                                hour: "2-digit",
                                minute: "2-digit",
                              })}
                            </span>
                          </div>
                        </>
                      );
                    })()}

                    {/* Expanded actions */}
                    {isSelected && (
                      <div style={styles.orderActions}>
                        <div style={styles.actionRow}>
                          {STATUS_FLOW.filter(
                            (s) => s !== order.status
                          ).map((s) => {
                            const sCfg = STATUS_CONFIG[s]!;
                            return (
                              <button
                                key={s}
                                style={{
                                  ...styles.actionBtn,
                                  borderColor: sCfg.color,
                                  color: sCfg.color,
                                }}
                                onClick={(e) => {
                                  e.stopPropagation();
                                  updateStatus.mutate({
                                    id: order.id,
                                    status: s as OrderStatus,
                                    notifyCustomer: true,
                                  });
                                }}
                                disabled={updateStatus.isPending}
                              >
                                {sCfg.emoji} {sCfg.label}
                              </button>
                            );
                          })}
                          {order.status !== "CANCELLED" && (
                            <button
                              style={{
                                ...styles.actionBtn,
                                borderColor: "#D88C8C",
                                color: "#D88C8C",
                              }}
                              onClick={(e) => {
                                e.stopPropagation();
                                updateStatus.mutate({
                                  id: order.id,
                                  status: "CANCELLED",
                                  notifyCustomer: true,
                                });
                              }}
                              disabled={updateStatus.isPending}
                            >
                              ❌ Cancel
                            </button>
                          )}
                        </div>
                        <button
                          style={styles.replyBtn}
                          onClick={(e) => {
                            e.stopPropagation();
                            setReplyPhone(order.phone);
                          }}
                        >
                          💬 Message Customer
                        </button>
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
            <h3 style={styles.modalTitle}>💬 Send WhatsApp Message</h3>
            <p style={styles.modalPhone}>To: {replyPhone}</p>
            <textarea
              style={styles.modalTextarea}
              placeholder="Type your message..."
              value={replyText}
              onChange={(e) => setReplyText(e.target.value)}
              rows={4}
            />
            <div style={styles.modalActions}>
              <button
                style={styles.modalCancel}
                onClick={() => setReplyPhone(null)}
              >
                Cancel
              </button>
              <button
                style={styles.modalSend}
                onClick={() => {
                  if (replyText.trim()) {
                    sendMessage.mutate({
                      phone: replyPhone,
                      message: replyText.trim(),
                    });
                  }
                }}
                disabled={!replyText.trim() || sendMessage.isPending}
              >
                {sendMessage.isPending ? "Sending..." : "Send ✉️"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Stat Card ──────────────────────────────────────────────────────────────

function StatCard({
  label,
  value,
  emoji,
  highlight,
  isText,
}: {
  label: string;
  value: string | number;
  emoji: string;
  highlight?: boolean;
  isText?: boolean;
}) {
  return (
    <div
      style={{
        ...styles.statCard,
        ...(highlight ? styles.statCardHighlight : {}),
      }}
    >
      <span style={styles.statEmoji}>{emoji}</span>
      <span
        style={{
          ...styles.statValue,
          ...(isText ? { fontSize: 14 } : {}),
        }}
      >
        {value}
      </span>
      <span style={styles.statLabel}>{label}</span>
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

// ─── Styles (inline CSS-in-JS matching Sonna's design system) ───────────────

const styles: Record<string, React.CSSProperties> = {
  // Layout
  container: {
    display: "flex",
    height: "calc(100vh - 80px)",
    overflow: "hidden",
    fontFamily: "Inter, sans-serif",
    backgroundColor: "#FFF9F7",
  },

  // Sidebar
  sidebar: {
    width: 280,
    height: "100%",
    backgroundColor: "#2B2B2B",
    color: "#FFF9F7",
    display: "flex",
    flexDirection: "column",
    flexShrink: 0,
    overflow: "hidden",
    transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
  },
  sidebarHeader: {
    padding: "20px 24px",
    borderBottom: "1px solid rgba(255,255,255,0.08)",
    backgroundColor: "transparent",
  },
  sidebarTitle: {
    margin: 0,
    fontSize: 18,
    fontWeight: 700,
    color: "#F4C2C2",
    letterSpacing: "-0.01em",
  },
  filterSelect: {
    flex: 1,
    padding: "8px 10px",
    borderRadius: 8,
    border: "1px solid rgba(255,255,255,0.1)",
    fontSize: 12,
    backgroundColor: "rgba(255,255,255,0.05)",
    color: "#FFF",
    outline: "none",
    cursor: "pointer",
    minWidth: 0,
  },
  sidebarLogo: {
    fontFamily: "Playfair Display, serif",
    fontSize: 22,
    fontWeight: 700,
    color: "#F4C2C2",
    margin: 0,
    letterSpacing: 2,
  },
  sidebarSubtitle: {
    fontSize: 12,
    color: "#9A9A9A",
    letterSpacing: 1,
    textTransform: "uppercase" as const,
    marginTop: 4,
    display: "block",
  },

  // Filters
  filterNav: {
    padding: "16px 12px",
    display: "flex",
    flexDirection: "column",
    gap: 4,
    borderBottom: "1px solid rgba(255,255,255,0.08)",
  },
  filterBtn: {
    background: "none",
    border: "none",
    color: "#9A9A9A",
    fontSize: 13,
    padding: "8px 12px",
    borderRadius: 8,
    textAlign: "left" as const,
    cursor: "pointer",
    transition: "all 0.2s ease",
  },
  filterBtnActive: {
    backgroundColor: "rgba(244,194,194,0.12)",
    color: "#F4C2C2",
    fontWeight: 600,
  },

  // Conversations
  convSection: {
    padding: "16px 12px",
    flex: 1,
    overflow: "auto",
  },
  convTitle: {
    fontSize: 13,
    fontWeight: 600,
    color: "#9A9A9A",
    textTransform: "uppercase" as const,
    letterSpacing: 1,
    margin: "0 0 12px 4px",
  },
  convList: {
    display: "flex",
    flexDirection: "column",
    gap: 4,
  },
  convItem: {
    display: "flex",
    alignItems: "center",
    gap: 10,
    padding: "8px 10px",
    borderRadius: 8,
    cursor: "pointer",
    transition: "background 0.2s",
  },
  convAvatar: {
    width: 32,
    height: 32,
    borderRadius: "50%",
    backgroundColor: "#5A3E36",
    color: "#F4C2C2",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: 14,
    fontWeight: 600,
    flexShrink: 0,
  },
  convInfo: {
    flex: 1,
    display: "flex",
    flexDirection: "column",
    minWidth: 0,
  },
  convName: {
    fontSize: 13,
    fontWeight: 500,
    color: "#FFF9F7",
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap" as const,
  },
  convPhone: {
    fontSize: 11,
    color: "#6E6E6E",
  },
  convReplyBtn: {
    background: "none",
    border: "none",
    cursor: "pointer",
    fontSize: 16,
    padding: 4,
    borderRadius: 4,
    flexShrink: 0,
  },

  // Main
  main: {
    flex: 1,
    height: "100%",
    padding: "28px 32px",
    overflowY: "auto" as const,
    position: "relative" as const,
    transition: "padding 0.3s ease",
  },

  // Stats
  statsBar: {
    display: "grid",
    gridTemplateColumns: "repeat(6, 1fr)",
    gap: 16,
    marginBottom: 28,
  },
  statCard: {
    backgroundColor: "#FFFFFF",
    borderRadius: 12,
    padding: "18px 16px",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 4,
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
    border: "1px solid #E8DED4",
    transition: "transform 0.2s ease, box-shadow 0.2s ease",
  },
  statCardHighlight: {
    backgroundColor: "#FFF0F0",
    borderColor: "#F4C2C2",
  },
  statEmoji: {
    fontSize: 24,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 700,
    color: "#2B2B2B",
    fontFamily: "Playfair Display, serif",
  },
  statLabel: {
    fontSize: 11,
    color: "#9A9A9A",
    textTransform: "uppercase" as const,
    letterSpacing: 0.5,
  },

  // Table
  tableWrapper: {
    backgroundColor: "#FFFFFF",
    borderRadius: 16,
    border: "1px solid #E8DED4",
    overflow: "hidden",
    boxShadow: "0 4px 12px rgba(0,0,0,0.04)",
  },
  tableHeader: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "20px 24px",
    borderBottom: "1px solid #E8DED4",
  },
  tableTitle: {
    fontSize: 18,
    fontWeight: 600,
    color: "#2B2B2B",
    fontFamily: "Playfair Display, serif",
    margin: 0,
  },
  orderCount: {
    fontSize: 13,
    color: "#9A9A9A",
  },

  // Order Grid
  orderGrid: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fill, minmax(320, 1fr))",
    gap: 0,
  },

  orderCard: {
    padding: "20px 24px",
    borderBottom: "1px solid #F7F3EF",
    cursor: "pointer",
    transition: "background 0.15s ease",
  },
  orderCardSelected: {
    backgroundColor: "#FFF9F7",
    borderLeft: "3px solid #F4C2C2",
  },
  orderCardTop: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 8,
  },
  orderNumber: {
    fontSize: 13,
    fontWeight: 600,
    color: "#5A3E36",
    fontFamily: "monospace",
  },
  statusPill: {
    fontSize: 12,
    fontWeight: 600,
    padding: "4px 10px",
    borderRadius: 20,
    letterSpacing: 0.3,
  },
  cakeName: {
    fontSize: 16,
    fontWeight: 600,
    color: "#2B2B2B",
    margin: "0 0 8px",
    fontFamily: "Playfair Display, serif",
  },
  orderMeta: {
    display: "flex",
    gap: 16,
    fontSize: 13,
    color: "#6E6E6E",
    marginBottom: 8,
  },
  orderFooter: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    fontSize: 12,
    color: "#9A9A9A",
  },
  customerName: {
    fontWeight: 500,
    color: "#6E6E6E",
  },
  customerLine: {
    display: "flex",
    alignItems: "center",
    gap: 8,
    marginTop: 8,
    marginBottom: 8,
    padding: "8px 12px",
    backgroundColor: "rgba(37, 211, 102, 0.08)",
    borderRadius: 8,
    border: "1px solid rgba(37, 211, 102, 0.2)",
  },
  customerLabel: {
    fontSize: 12,
    fontWeight: 600,
    color: "#128C7E",
  },
  orderNotes: {
    display: "flex",
    gap: 10,
    marginTop: 8,
    padding: "10px 14px",
    backgroundColor: "#FDFCFB",
    borderRadius: 10,
    border: "1px solid #E8DED4",
    alignItems: "flex-start",
  },
  notesIcon: {
    fontSize: 16,
    flexShrink: 0,
  },
  notesText: {
    fontSize: 13,
    color: "#5A3E36",
    lineHeight: 1.6,
    flex: 1,
    whiteSpace: "pre-wrap",
  },
  customerLink: {
    fontSize: 13,
    color: "#075E54",
    textDecoration: "none",
    fontWeight: 600,
    display: "flex",
    alignItems: "center",
    gap: 6,
  },
  orderDate: {},

  // Order Actions
  orderActions: {
    marginTop: 16,
    paddingTop: 16,
    borderTop: "1px solid #E8DED4",
    display: "flex",
    flexDirection: "column",
    gap: 10,
  },
  actionRow: {
    display: "flex",
    flexWrap: "wrap" as const,
    gap: 8,
  },
  actionBtn: {
    fontSize: 12,
    fontWeight: 600,
    padding: "6px 14px",
    borderRadius: 8,
    border: "1.5px solid",
    backgroundColor: "transparent",
    cursor: "pointer",
    transition: "all 0.2s ease",
  },
  replyBtn: {
    fontSize: 13,
    fontWeight: 500,
    padding: "8px 16px",
    borderRadius: 8,
    border: "none",
    backgroundColor: "#2B2B2B",
    color: "#FFF9F7",
    cursor: "pointer",
    transition: "all 0.2s ease",
    alignSelf: "flex-start",
  },

  // Empty / Loading
  loading: {
    padding: 48,
    textAlign: "center" as const,
    color: "#9A9A9A",
    fontSize: 14,
  },
  emptyState: {
    padding: 64,
    textAlign: "center" as const,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 8,
  },
  emptyText: {
    color: "#6E6E6E",
    fontSize: 14,
    margin: 0,
  },
  emptySubtext: {
    color: "#9A9A9A",
    fontSize: 12,
    margin: 0,
  },

  // Reply Modal
  modalOverlay: {
    position: "fixed" as const,
    inset: 0,
    backgroundColor: "rgba(43,43,43,0.5)",
    backdropFilter: "blur(4px)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    zIndex: 50,
  },
  modal: {
    backgroundColor: "#FFFFFF",
    borderRadius: 16,
    padding: 32,
    width: 440,
    maxWidth: "90vw",
    boxShadow: "0 20px 60px rgba(0,0,0,0.15)",
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 600,
    color: "#2B2B2B",
    margin: "0 0 4px",
    fontFamily: "Playfair Display, serif",
  },
  modalPhone: {
    fontSize: 13,
    color: "#9A9A9A",
    margin: "0 0 16px",
  },
  modalTextarea: {
    width: "100%",
    padding: "12px 14px",
    borderRadius: 10,
    border: "1.5px solid #E8DED4",
    fontSize: 14,
    fontFamily: "Inter, sans-serif",
    resize: "vertical" as const,
    outline: "none",
    transition: "border-color 0.2s",
    boxSizing: "border-box" as const,
  },
  modalActions: {
    display: "flex",
    justifyContent: "flex-end",
    gap: 10,
    marginTop: 16,
  },
  modalCancel: {
    padding: "10px 20px",
    borderRadius: 8,
    border: "1px solid #E8DED4",
    backgroundColor: "transparent",
    color: "#6E6E6E",
    fontSize: 13,
    fontWeight: 500,
    cursor: "pointer",
  },
  modalSend: {
    padding: "10px 24px",
    borderRadius: 8,
    border: "none",
    backgroundColor: "#5A3E36",
    color: "#FFF9F7",
    fontSize: 13,
    fontWeight: 600,
    cursor: "pointer",
    transition: "background 0.2s ease",
  },
  imagePreview: {
    marginTop: 12,
    marginBottom: 12,
    borderRadius: 10,
    overflow: "hidden",
    border: "1px solid #E8DED4",
    width: 180,
    height: 140,
    backgroundColor: "#F7F3EF",
    boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
  },
  previewImg: {
    width: "100%",
    height: "100%",
    display: "block",
    objectFit: "cover" as const,
  },
  collapseBtnInternal: {
    backgroundColor: "transparent",
    border: "none",
    color: "#9A9A9A",
    fontSize: 20,
    cursor: "pointer",
    padding: "10px 20px",
    textAlign: "right" as const,
    width: "100%",
    transition: "color 0.2s",
  },
  expandBtn: {
    backgroundColor: "#F4C2C2",
    color: "#2B2B2B",
    border: "none",
    borderRadius: "0 20px 20px 0",
    padding: "10px 20px",
    fontSize: 13,
    fontWeight: 600,
    cursor: "pointer",
    position: "absolute" as const,
    left: 0,
    bottom: 40,
    zIndex: 40,
    boxShadow: "4px 0 12px rgba(0,0,0,0.1)",
    transition: "all 0.2s ease",
  },
};

// hi
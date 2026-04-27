"use client";

import { useState } from "react";
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

// ─── Page ───────────────────────────────────────────────────────────────────

export default function WhatsAppAdminPage() {
  const [statusFilter, setStatusFilter] = useState<string | undefined>(
    undefined
  );
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const [replyPhone, setReplyPhone] = useState<string | null>(null);
  const [replyText, setReplyText] = useState("");

  // Data queries
  const statsQuery = api.whatsapp.getStats.useQuery();
  const ordersQuery = api.whatsapp.getOrders.useQuery({
    status: statusFilter,
    limit: 50,
  });
  const conversationsQuery = api.whatsapp.getConversations.useQuery({
    limit: 20,
  });

  // Mutations
  const utils = api.useUtils();
  const updateStatus = api.whatsapp.updateOrderStatus.useMutation({
    onSuccess: () => {
      void utils.whatsapp.getOrders.invalidate();
      void utils.whatsapp.getStats.invalidate();
    },
  });

  const sendMessage = api.whatsapp.sendMessage.useMutation({
    onSuccess: () => {
      setReplyText("");
      setReplyPhone(null);
    },
  });

  const stats = statsQuery.data;
  const orders = ordersQuery.data?.orders ?? [];
  const conversations = conversationsQuery.data ?? [];

  // const selectedOrder = orders.find((o) => o.id === selectedOrderId);

  return (
    <div style={styles.container}>
      {/* ─── Sidebar ─────────────────────────────────────────── */}
      <aside style={styles.sidebar}>

        {/* Filter Tabs */}
        <nav style={styles.filterNav}>
          <button
            style={{
              ...styles.filterBtn,
              ...(statusFilter === undefined ? styles.filterBtnActive : {}),
            }}
            onClick={() => setStatusFilter(undefined)}
          >
            All Orders
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
                onClick={() => setStatusFilter(s)}
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
            onClick={() => setStatusFilter("CANCELLED")}
          >
            ❌ Cancelled
          </button>
        </nav>

        {/* Recent Conversations */}
        <div style={styles.convSection}>
          <h3 style={styles.convTitle}>💬 Recent Chats</h3>
          <div style={styles.convList}>
            {conversations.map((c) => (
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
            {conversations.length === 0 && (
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
            <h2 style={styles.tableTitle}>
              {statusFilter
                ? `${STATUS_CONFIG[statusFilter]?.emoji} ${STATUS_CONFIG[statusFilter]?.label} Orders`
                : "📋 All Orders"}
            </h2>
            <span style={styles.orderCount}>{orders.length} orders</span>
          </div>

          {ordersQuery.isLoading ? (
            <div style={styles.loading}>Loading orders...</div>
          ) : orders.length === 0 ? (
            <div style={styles.emptyState}>
              <span style={{ fontSize: 48 }}>🧁</span>
              <p style={styles.emptyText}>No orders found</p>
              <p style={styles.emptySubtext}>
                Orders placed via WhatsApp will appear here
              </p>
            </div>
          ) : (
            <div style={styles.orderGrid}>
              {orders.map((order) => {
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
                    <div style={styles.orderCardTop}>
                      <span style={styles.orderNumber}>
                        #{order.orderNumber}
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
                    </div>

                    <h3 style={styles.cakeName}>{order.cakeName}</h3>

                    <div style={styles.orderMeta}>
                      <span>📏 {order.size}</span>
                      <span>💰 {order.price}</span>
                    </div>
                    {order.address && (
                      <div style={styles.orderNotes}>
                        <span style={styles.notesIcon}>📍</span>
                        <span style={styles.notesText}>{order.address}</span>
                      </div>
                    )}

                    {order.notes && (
                      <div style={styles.orderNotes}>
                        <span style={styles.notesIcon}>📝</span>
                        <span style={styles.notesText}>{order.notes}</span>
                      </div>
                    )}

                    <div style={styles.orderFooter}>
                      <span style={styles.customerName}>
                        {order.customerName ?? order.phone}
                      </span>
                      <span style={styles.orderDate}>
                        {new Date(order.createdAt).toLocaleDateString("en-IN", {
                          day: "numeric",
                          month: "short",
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </span>
                    </div>

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

// ─── Styles (inline CSS-in-JS matching Sonna's design system) ───────────────

const styles: Record<string, React.CSSProperties> = {
  // Layout
  container: {
    display: "flex",
    minHeight: "100vh",
    fontFamily: "Inter, sans-serif",
    backgroundColor: "#FFF9F7",
  },

  // Sidebar
  sidebar: {
    width: 280,
    backgroundColor: "#2B2B2B",
    color: "#FFF9F7",
    display: "flex",
    flexDirection: "column",
    flexShrink: 0,
    overflow: "hidden",
  },
  sidebarHeader: {
    padding: "28px 24px 20px",
    borderBottom: "1px solid rgba(255,255,255,0.08)",
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
    padding: "28px 32px",
    overflowY: "auto" as const,
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
};

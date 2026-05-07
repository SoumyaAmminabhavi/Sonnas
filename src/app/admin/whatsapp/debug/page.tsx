
import { db } from "~/server/db";
import { auth } from "~/server/auth";
import { redirect } from "next/navigation";

export default async function DebugDBPage() {
  const session = await auth();
  if (!session) redirect("/api/auth/signin");

  let orders = [];
  let error = null;
  let dbUrl = "Hidden";

  try {
    orders = await db.whatsAppOrder.findMany({
      take: 5,
      orderBy: { createdAt: 'desc' }
    });
    dbUrl = process.env.DATABASE_URL?.split('@')[1] || "Not Found";
  } catch (err: any) {
    error = err.message || "Unknown Error";
  }

  return (
    <div style={{ padding: 40, fontFamily: 'monospace', color: '#5A3E36' }}>
      <h1>🛠️ Database Debugger</h1>
      <hr />
      <p><strong>DB Host:</strong> {dbUrl}</p>
      <p><strong>Total Orders in DB:</strong> {orders.length}</p>
      
      {error && (
        <div style={{ color: 'red', border: '1px solid red', padding: 10, marginTop: 20 }}>
          <h3>❌ Error:</h3>
          <pre>{error}</pre>
        </div>
      )}

      <h3>📋 Latest 5 Orders:</h3>
      <pre>
        {JSON.stringify(orders, null, 2)}
      </pre>

      <div style={{ marginTop: 40 }}>
        <a href="/admin/whatsapp" style={{ color: '#C9A27E' }}>← Back to Order Studio</a>
      </div>
    </div>
  );
}

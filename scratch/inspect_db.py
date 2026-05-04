import os
import json
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_ANON_KEY")
supabase: Client = create_client(url, key)

def inspect_data():
    # Inspect WhatsAppOrder
    orders = supabase.table("WhatsAppOrder").select("*").limit(1).execute()
    print("Sample Order:")
    print(json.dumps(orders.data, indent=2))
    
    if orders.data:
        order_id = orders.data[0]['id']
        # Inspect WhatsAppOrderItem
        items = supabase.table("WhatsAppOrderItem").select("*").eq("orderId", order_id).execute()
        print("\nSample Order Items:")
        print(json.dumps(items.data, indent=2))
        
        # Inspect Cake table
        cakes = supabase.table("Cake").select("*").limit(1).execute()
        print("\nSample Cake:")
        print(json.dumps(cakes.data, indent=2))

if __name__ == "__main__":
    inspect_data()

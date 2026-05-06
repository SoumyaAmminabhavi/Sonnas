Viewed manage_staff_page.dart:1-31

This is a critical part of securing your bakery’s data. Based on the roles we've established, here is a recommended **Permissions Matrix** to ensure everyone sees only what they need:

| Feature / Action                     | OWNER | MANAGER |  CHEF  | SUPPORT | CLEANING |
| :----------------------------------- | :----: | :-----: | :----: | :-----: | :------: |
| **View Revenue & Financials**  | ✅ Yes | ✅ Yes | ❌ No |  ❌ No  |  ❌ No  |
| **Add / Remove Staff**         | ✅ Yes | ✅ Yes | ❌ No |  ❌ No  |  ❌ No  |
| **Manage Menu (Price/Cakes)**  | ✅ Yes | ✅ Yes | ❌ No |  ❌ No  |  ❌ No  |
| **View Customer Orders**       | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |  ❌ No  |
| **Update Order Status**        | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |  ❌ No  |
| **View Inventory Levels**      | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |  ✅ Yes  |
| **Add Stock (Purchase Entry)** | ✅ Yes | ✅ Yes | ✅ Yes |  ❌ No  |  ❌ No  |
| **Delete Inventory Items**     | ✅ Yes | ✅ Yes | ❌ No |  ❌ No  |  ❌ No  |
| **View Cleaning Checklists**   | ✅ Yes | ✅ Yes | ❌ No |  ❌ No  |  ✅ Yes  |
| **Complete Hygiene Tasks**     | ✅ Yes | ✅ Yes | ❌ No |  ❌ No  |  ✅ Yes  |
| **System Settings (API/Keys)** | ✅ Yes |  ❌ No  | ❌ No |  ❌ No  |  ❌ No  |

### **Key Insights for your Boss:**

1. **The "Two-Gate" Rule**: Only the **Owner** and **Manager (Ashwini)** can see how much money the bakery is making.
2. **Chef Independence**: Mustafa and the kitchen team can add stock (e.g., when a bag of flour arrives), but they cannot delete items or change prices.
3. **Support Access**: Akshata needs to see orders to pack them, but she doesn't need to see the "Hygiene" checklist or "Recipe Costs."
4. **Cleaning Focus**: Manjula and Rajeshwari have the most restricted access. They only see the items they need to clean and can view stock levels (to report if soap/detergent is running low).

**Would you like me to implement these specific "Access Blocks" into the app code now?** (For example, making sure the "Delete" button only appears for Ashwini).

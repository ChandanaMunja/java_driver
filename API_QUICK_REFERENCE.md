# API Quick Reference - Driver Order System

## 🎯 Most Important API (Polled Every 3 Seconds)

### GET /users/{userId}
**Purpose:** Check for new orders

**Response Must Include:**
```json
{
  "success": true,
  "data": {
    "orderRequestData": ["order_1", "order_2"],  // ← NEW ORDERS HERE
    "inProgressOrderID": ["order_3"]             // ← ACTIVE DELIVERIES
  }
}
```

**Critical:** 
- These must be **JSON arrays**, not strings
- Empty arrays `[]` are OK
- Never return `null`

---

## 📦 Fetch Order Details

### GET /driver/get-current-reject-accept?order_id={id}
**Purpose:** Get full order information

**Response:**
```json
{
  "success": true,
  "order": {
    "id": "order_123",
    "status": "Driver Pending",
    "vendor": { "id": "...", "name": "...", "latitude": 15.2, "longitude": 79.8 },
    "author": { "id": "...", "firstName": "...", "location": {...} },
    "address": { "location": { "latitude": 15.3, "longitude": 79.9 } }
  }
}
```

---

## 💰 Get Payment Amount

### GET /mobile/orders/{orderId}/billing/to-pay
**Purpose:** Get amount customer needs to pay

**Response:**
```json
{
  "success": true,
  "data": {
    "found": true,
    "to_pay": 185.50
  }
}
```

**Critical:** Always return JSON, never HTML!

---

## 🔄 How Orders Flow

1. **Backend adds order ID to driver's `orderRequestData`**
   ```sql
   UPDATE users 
   SET orderRequestData = JSON_ARRAY_APPEND(orderRequestData, '$', 'new_order_id')
   WHERE id = 'driver_id';
   ```

2. **App polls GET /users/{userId} and sees new order ID**

3. **App calls GET /driver/get-current-reject-accept to get order details**

4. **Driver sees order and can accept/reject**

5. **When accepted:**
   - Remove from `orderRequestData`
   - Add to `inProgressOrderID`
   - Update order `status = "Driver Accepted"`

---

## ⚠️ Common Mistakes to Avoid

❌ **Wrong:** `orderRequestData: "[order1, order2]"` (JSON string)  
✅ **Right:** `orderRequestData: ["order1", "order2"]` (JSON array)

❌ **Wrong:** Returning HTML error page  
✅ **Right:** Always return JSON: `{"success": false, "message": "..."}`

❌ **Wrong:** `orderRequestData: null`  
✅ **Right:** `orderRequestData: []` (empty array)

❌ **Wrong:** Missing nested objects (`vendor`, `author`)  
✅ **Right:** Include full nested objects or JSON strings

---

## 🧪 Test Your APIs

```bash
# Test user endpoint
curl "https://web.jippymart.in/api/users/YOUR_DRIVER_ID"

# Test order endpoint  
curl "https://web.jippymart.in/api/driver/get-current-reject-accept?order_id=YOUR_ORDER_ID"

# Test to-pay endpoint
curl "https://web.jippymart.in/api/mobile/orders/YOUR_ORDER_ID/billing/to-pay"
```

---

For full details, see **API_GUIDE.md**



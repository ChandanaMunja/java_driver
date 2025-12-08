# Complete API Guide for Driver Order Delivery System

This document provides a comprehensive guide on all APIs required for the driver app to fetch and manage orders.

---

## Base URL

```
https://web.jippymart.in/api/
```

---

## 📋 API Endpoints Overview

### 1. **GET Driver Profile** - Primary API for Order Detection
### 2. **GET Current Order Details** - Fetch Order Information
### 3. **GET Order by ID** - Refresh Order Details
### 4. **GET To-Pay Amount** - Get Order Billing Info
### 5. **POST Driver Orders List** - Get All Driver Orders

---

## 🔄 Order Flow Architecture

```
1. Backend adds order IDs to driver's orderRequestData (via Firebase Cloud Functions)
   ↓
2. Driver app polls GET /users/{userId} every 3 seconds
   ↓
3. App detects new order IDs in orderRequestData array
   ↓
4. App calls GET /driver/get-current-reject-accept to fetch order details
   ↓
5. Order is displayed to driver
```

---

## 1. GET Driver Profile (User Data)

**Endpoint:** `GET /users/{userId}`

**Purpose:** This is the **primary API** that the app polls every 3 seconds to detect new orders. It returns driver information including:
- `orderRequestData`: Array of order IDs that are available for the driver to accept
- `inProgressOrderID`: Array of order IDs currently being delivered

**Request:**
```http
GET /api/users/{userId}
Headers:
  Accept: application/json
  Content-Type: application/json
```

**Example:**
```http
GET /api/users/gfjVARR8z2Sdp5feMzxO
```

**✅ Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "gfjVARR8z2Sdp5feMzxO",
    "firebase_id": "firebase_uid_123",
    "firstName": "John",
    "lastName": "Doe",
    "email": "driver@example.com",
    "phoneNumber": "1234567890",
    "countryCode": "+1",
    "profile_pic": "https://example.com/profile.jpg",
    "wallet_amount": 500.50,
    "deliveryAmount": 0,
    "active": true,
    "isActive": true,
    "role": "driver",
    "zoneId": "zone_123",
    "rotation": 0,
    "carName": "Toyota Camry",
    "carNumber": "ABC-1234",
    "fcmToken": "fcm_token_here",
    "location": {
      "latitude": 15.2258,
      "longitude": 79.8407
    },
    "inProgressOrderID": ["order_123", "order_456"],
    "orderRequestData": ["order_789", "order_101112"],
    "createdAt": 1699123456789
  }
}
```

**❌ Error Response (404 Not Found):**
```json
{
  "success": false,
  "message": "User not found"
}
```

**❌ Error Response (500 Internal Server Error):**
```json
{
  "success": false,
  "message": "Internal server error"
}
```

**Critical Fields:**
- `orderRequestData`: **Array of strings** - Order IDs available for acceptance
  - Empty array `[]` if no new orders
  - Example: `["Jippy33000314", "Jippy33000315"]`
  
- `inProgressOrderID`: **Array of strings** - Order IDs currently being delivered
  - Empty array `[]` if no orders in progress
  - Example: `["Jippy33000310"]`

**⚠️ Important Notes:**
1. These arrays must be actual JSON arrays, NOT JSON strings
2. Empty arrays are acceptable: `[]`
3. Do NOT return `null` - return empty array instead
4. Order IDs must be unique strings

---

## 2. GET Current Order Details

**Endpoint:** `GET /driver/get-current-reject-accept`

**Purpose:** Fetches full order details for a specific order ID. Called when:
- A new order ID appears in `orderRequestData`
- An existing order needs to be refreshed
- Driver navigates to order details

**Request:**
```http
GET /api/driver/get-current-reject-accept?order_id={orderId}&exclude_statuses={statuses}
Headers:
  Accept: application/json
  Content-Type: application/json
```

**Query Parameters:**
- `order_id` (required): The order ID to fetch
- `exclude_statuses` (optional): Comma-separated list of statuses to exclude
  - For pending orders: `"Order Cancelled,Driver Rejected"`
  - For in-progress orders: `"Order Cancelled,Driver Rejected,Order Completed"`

**Example:**
```http
GET /api/driver/get-current-reject-accept?order_id=Jippy33000314&exclude_statuses=Order%20Cancelled,Driver%20Rejected
```

**✅ Success Response (200 OK):**
```json
{
  "success": true,
  "order": {
    "id": "Jippy33000314",
    "status": "Driver Pending",
    "vendorID": "vendor_123",
    "driverID": null,
    "authorID": "customer_456",
    "payment_method": "cod",
    "deliveryCharge": "25",
    "tipAmount": "10",
    "discount": 50,
    "couponCode": "SAVE50",
    "adminCommission": "10",
    "adminCommissionType": "percentage",
    "notes": "Please deliver carefully",
    "createdAt": {
      "seconds": 1699123456,
      "nanoseconds": 789000000
    },
    "estimatedTimeToPrepare": "30",
    "products": [
      {
        "id": "product_1",
        "name": "Pizza Margherita",
        "quantity": 2,
        "price": "150",
        "image": "https://example.com/pizza.jpg"
      }
    ],
    "vendor": {
      "id": "vendor_123",
      "name": "Pizza Palace",
      "latitude": 15.2258,
      "longitude": 79.8407,
      "address": "123 Main St",
      "phoneNumber": "9876543210",
      "fcmToken": "vendor_fcm_token"
    },
    "author": {
      "id": "customer_456",
      "firstName": "Jane",
      "lastName": "Smith",
      "phoneNumber": "1234567890",
      "location": {
        "latitude": 15.2300,
        "longitude": 79.8500
      },
      "fcmToken": "customer_fcm_token"
    },
    "address": {
      "location": {
        "latitude": 15.2300,
        "longitude": 79.8500
      },
      "address": "456 Delivery St",
      "city": "City Name",
      "state": "State Name",
      "country": "Country",
      "zipCode": "12345"
    },
    "calculatedCharges": {
      "driverToRestaurantDistance": 2.5,
      "driverToRestaurantDuration": 5.0,
      "driverToRestaurantCharge": 5,
      "restaurantToCustomerDistance": 3.0,
      "restaurantToCustomerDuration": 6.0,
      "restaurantToCustomerCharge": 21,
      "tipsAmount": 10,
      "surgeAmount": "0",
      "totalCalculatedCharge": "36",
      "calculatedAt": {
        "seconds": 1699123500,
        "nanoseconds": 0
      }
    },
    "specialDiscount": {
      "type": "fixed",
      "amount": 20
    },
    "taxSetting": [
      {
        "id": "tax_1",
        "title": "GST",
        "type": "percentage",
        "value": "5"
      }
    ],
    "rejectedByDrivers": [],
    "toPay": "185.50"
  }
}
```

**❌ Order Not Found or Excluded (200 OK with success=false):**
```json
{
  "success": false,
  "message": "Order not found or status excluded"
}
```

**❌ Error Response (500 Internal Server Error):**
```json
{
  "success": false,
  "message": "Internal server error"
}
```

**⚠️ Important Notes:**
1. `vendor` and `author` can be:
   - **Object (Map)** - Preferred: Full nested object
   - **JSON String** - Also supported: `"{\"id\":\"vendor_123\",\"name\":\"Pizza Palace\"}"`
   
2. `address` field must include nested `location` object with `latitude` and `longitude`

3. `calculatedCharges` is optional but recommended for displaying delivery fees

4. Always return valid JSON - **NEVER return HTML error pages**

5. Order status values:
   - `"Driver Pending"` - Order available for acceptance
   - `"Driver Accepted"` - Driver accepted the order
   - `"Order Shipped"` - Order picked up, heading to customer
   - `"In Transit"` - Order being delivered
   - `"Order Completed"` - Delivery completed
   - `"Order Cancelled"` - Order cancelled
   - `"Driver Rejected"` - Driver rejected the order

---

## 3. GET Order by ID (Refresh Order)

**Endpoint:** `GET /restaurant/orders/{orderId}`

**Purpose:** Refreshes an existing order's details. Used to get the latest status and data.

**Request:**
```http
GET /api/restaurant/orders/{orderId}
Headers:
  Accept: application/json
  Content-Type: application/json
```

**Example:**
```http
GET /api/restaurant/orders/Jippy33000314
```

**✅ Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "Jippy33000314",
    "status": "Driver Accepted",
    "vendorID": "vendor_123",
    "driverID": "gfjVARR8z2Sdp5feMzxO",
    "authorID": "customer_456",
    "payment_method": "cod",
    "deliveryCharge": "25",
    "tipAmount": "10",
    "createdAt": {
      "seconds": 1699123456,
      "nanoseconds": 789000000
    },
    "products": [...],
    "vendor": {...},
    "author": {...},
    "address": {...}
  }
}
```

**❌ Order Not Found (200 OK with success=false):**
```json
{
  "success": false,
  "message": "Order not found"
}
```

---

## 4. GET To-Pay Amount (Order Billing)

**Endpoint:** `GET /mobile/orders/{orderId}/billing/to-pay`

**Purpose:** Gets the final amount the customer needs to pay (for COD orders).

**Request:**
```http
GET /api/mobile/orders/{orderId}/billing/to-pay
Headers:
  Accept: application/json
  Content-Type: application/json
```

**Example:**
```http
GET /api/mobile/orders/Jippy33000314/billing/to-pay
```

**✅ Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "found": true,
    "to_pay": 185.50
  }
}
```

**❌ Not Found (200 OK with success=false):**
```json
{
  "success": false,
  "data": {
    "found": false
  },
  "message": "Billing information not found"
}
```

**⚠️ Important Notes:**
1. **ALWAYS return JSON** - Never return HTML error pages
2. `to_pay` should be a number (not string)
3. Return `found: false` if billing info doesn't exist yet
4. This API is critical for completing COD orders

---

## 5. POST Driver Orders List

**Endpoint:** `POST /driver/orders`

**Purpose:** Gets a list of all orders for a specific driver (used in order history/list screen).

**Request:**
```http
POST /api/driver/orders
Headers:
  Content-Type: application/json
Body:
{
  "driver_id": "gfjVARR8z2Sdp5feMzxO"
}
```

**✅ Success Response (200 OK):**
```json
{
  "success": true,
  "orders": [
    {
      "id": "Jippy33000314",
      "status": "Order Completed",
      "vendorID": "vendor_123",
      "driverID": "gfjVARR8z2Sdp5feMzxO",
      "createdAt": {
        "seconds": 1699123456,
        "nanoseconds": 789000000
      },
      "payment_method": "cod",
      "deliveryCharge": "25",
      "tipAmount": "10",
      "products": [...],
      "vendor": {...},
      "author": {...},
      "address": {...}
    }
  ]
}
```

---

## 🔧 Backend Implementation Guide

### How to Add Orders to Driver's `orderRequestData`

**Option 1: Using Firebase Cloud Functions (Recommended)**

When a new order is created, your Firebase Cloud Function should:
1. Find nearby available drivers
2. Add the order ID to each driver's `orderRequestData` array
3. Sync this to your backend database

**Example (Firebase Cloud Function):**
```javascript
// In functions/index.js
exports.dispatch = onDocumentWritten("restaurant_orders/{orderID}", async (event) => {
    const orderId = event.params.orderID;
    const orderData = event.data.after.data();
    
    // Find nearby drivers
    const foundDrivers = await findNearbyDrivers(orderData.vendorLocation);
    
    // Add order to each driver's orderRequestData
    const batch = firestore.batch();
    foundDrivers.forEach(driver => {
        const driverRef = firestore.collection('users').doc(driver.id);
        batch.update(driverRef, {
            orderRequestData: admin.firestore.FieldValue.arrayUnion(orderId)
        });
    });
    await batch.commit();
    
    // IMPORTANT: Also update your backend database
    // Make API call to sync with backend
    await syncOrderRequestDataToBackend(foundDrivers, orderId);
});
```

**Option 2: Direct Backend Update**

When creating an order, your backend should:
1. Query drivers in the same zone
2. Add order ID to their `orderRequestData` in database

**Example SQL (MySQL):**
```sql
-- Add order to drivers' orderRequestData
UPDATE users 
SET orderRequestData = JSON_ARRAY_APPEND(
    COALESCE(orderRequestData, JSON_ARRAY()),
    '$',
    'Jippy33000314'
)
WHERE role = 'driver' 
  AND zoneId = 'zone_123'
  AND active = 1
  AND JSON_LENGTH(COALESCE(inProgressOrderID, JSON_ARRAY())) < 1; -- Not already delivering
```

**Example Laravel (PHP):**
```php
// In your OrderController
public function createOrder(Request $request) {
    $order = Order::create([...]);
    
    // Find nearby drivers
    $drivers = User::where('role', 'driver')
        ->where('zoneId', $order->vendor->zoneId)
        ->where('active', true)
        ->get();
    
    // Add order ID to each driver's orderRequestData
    foreach ($drivers as $driver) {
        $orderRequestData = $driver->orderRequestData ?? [];
        if (!in_array($order->id, $orderRequestData)) {
            $orderRequestData[] = $order->id;
            $driver->update(['orderRequestData' => $orderRequestData]);
        }
    }
    
    return response()->json(['success' => true, 'order' => $order]);
}
```

---

## 🔄 How Order Status Updates Work

### When Driver Accepts Order:

1. **Update Order:**
   ```sql
   UPDATE orders 
   SET status = 'Driver Accepted', 
       driverID = 'gfjVARR8z2Sdp5feMzxO'
   WHERE id = 'Jippy33000314';
   ```

2. **Update Driver:**
   ```sql
   -- Remove from orderRequestData
   UPDATE users 
   SET orderRequestData = JSON_REMOVE(
       orderRequestData,
       JSON_UNQUOTE(JSON_SEARCH(orderRequestData, 'one', 'Jippy33000314'))
   ),
   -- Add to inProgressOrderID
   inProgressOrderID = JSON_ARRAY_APPEND(
       COALESCE(inProgressOrderID, JSON_ARRAY()),
       '$',
       'Jippy33000314'
   )
   WHERE id = 'gfjVARR8z2Sdp5feMzxO';
   ```

3. **Remove from Other Drivers:**
   ```sql
   -- Remove order from all other drivers' orderRequestData
   UPDATE users 
   SET orderRequestData = JSON_REMOVE(
       orderRequestData,
       JSON_UNQUOTE(JSON_SEARCH(orderRequestData, 'one', 'Jippy33000314'))
   )
   WHERE role = 'driver' 
     AND id != 'gfjVARR8z2Sdp5feMzxO'
     AND JSON_CONTAINS(orderRequestData, '"Jippy33000314"');
   ```

### When Driver Rejects Order:

1. **Add to Rejected List:**
   ```sql
   UPDATE orders 
   SET rejectedByDrivers = JSON_ARRAY_APPEND(
       COALESCE(rejectedByDrivers, JSON_ARRAY()),
       '$',
       'gfjVARR8z2Sdp5feMzxO'
   )
   WHERE id = 'Jippy33000314';
   ```

2. **Remove from Driver:**
   ```sql
   UPDATE users 
   SET orderRequestData = JSON_REMOVE(
       orderRequestData,
       JSON_UNQUOTE(JSON_SEARCH(orderRequestData, 'one', 'Jippy33000314'))
   )
   WHERE id = 'gfjVARR8z2Sdp5feMzxO';
   ```

### When Order is Completed:

1. **Update Order Status:**
   ```sql
   UPDATE orders 
   SET status = 'Order Completed'
   WHERE id = 'Jippy33000314';
   ```

2. **Remove from Driver's inProgressOrderID:**
   ```sql
   UPDATE users 
   SET inProgressOrderID = JSON_REMOVE(
       inProgressOrderID,
       JSON_UNQUOTE(JSON_SEARCH(inProgressOrderID, 'one', 'Jippy33000314'))
   )
   WHERE id = 'gfjVARR8z2Sdp5feMzxO';
   ```

---

## ✅ Checklist for Backend Implementation

### GET /users/{userId}
- [ ] Returns `orderRequestData` as JSON array (not string)
- [ ] Returns `inProgressOrderID` as JSON array (not string)
- [ ] Returns empty arrays `[]` instead of `null`
- [ ] Includes all required driver fields (location, zoneId, etc.)
- [ ] Returns 200 OK with JSON response (never HTML)

### GET /driver/get-current-reject-accept
- [ ] Accepts `order_id` query parameter
- [ ] Accepts optional `exclude_statuses` query parameter
- [ ] Returns full order object with nested `vendor` and `author`
- [ ] Handles `vendor` and `author` as objects or JSON strings
- [ ] Returns 200 OK even if order not found (with `success: false`)
- [ ] Never returns HTML error pages

### GET /mobile/orders/{orderId}/billing/to-pay
- [ ] Returns JSON format always (never HTML)
- [ ] Returns `to_pay` as number, not string
- [ ] Returns `found: false` if billing not available
- [ ] Calculates correct total including taxes, delivery charges, etc.

### Order Assignment Logic
- [ ] Adds new order IDs to `orderRequestData` when orders are created
- [ ] Removes order from `orderRequestData` when driver accepts
- [ ] Moves order to `inProgressOrderID` when accepted
- [ ] Removes order from other drivers when one accepts
- [ ] Cleans up `inProgressOrderID` when order is completed

---

## 🐛 Common Issues & Solutions

### Issue 1: Orders Not Appearing
**Problem:** `orderRequestData` is empty or not updating

**Solution:**
- Verify backend is adding order IDs to `orderRequestData` when orders are created
- Check that driver's `zoneId` matches order's zone
- Ensure driver's `active` status is `true`

### Issue 2: HTML Response Instead of JSON
**Problem:** API returns HTML error page instead of JSON

**Solution:**
- Ensure all API routes return JSON responses
- Add error handling middleware to catch exceptions
- Return proper JSON error responses:
  ```json
  {
    "success": false,
    "message": "Error description"
  }
  ```

### Issue 3: Order Details Missing Nested Objects
**Problem:** `vendor` or `author` fields are null

**Solution:**
- Ensure API joins/loads related data
- Include nested objects in API response
- Verify foreign key relationships are correct

### Issue 4: Arrays Returned as Strings
**Problem:** `orderRequestData` is returned as JSON string `"[...]"` instead of array

**Solution:**
- Use proper JSON encoding in backend
- Don't double-encode JSON fields
- Use database JSON type, not TEXT type

---

## 📞 Testing Checklist

1. **Test GET /users/{userId}:**
   ```bash
   curl -X GET "https://web.jippymart.in/api/users/gfjVARR8z2Sdp5feMzxO" \
     -H "Accept: application/json"
   ```
   - Verify `orderRequestData` is an array
   - Verify `inProgressOrderID` is an array

2. **Test GET /driver/get-current-reject-accept:**
   ```bash
   curl -X GET "https://web.jippymart.in/api/driver/get-current-reject-accept?order_id=Jippy33000314&exclude_statuses=Order%20Cancelled,Driver%20Rejected" \
     -H "Accept: application/json"
   ```
   - Verify order object is returned
   - Verify nested objects (`vendor`, `author`) are present

3. **Test GET /mobile/orders/{orderId}/billing/to-pay:**
   ```bash
   curl -X GET "https://web.jippymart.in/api/mobile/orders/Jippy33000314/billing/to-pay" \
     -H "Accept: application/json"
   ```
   - Verify JSON response (not HTML)
   - Verify `to_pay` is a number

---

## 📱 App Polling Behavior

The driver app:
- Polls `GET /users/{userId}` **every 3 seconds**
- Immediately fetches order when new ID appears in `orderRequestData`
- Refreshes orders when app comes to foreground
- Automatically cleans up completed/cancelled orders

**Recommended Backend Actions:**
- Ensure APIs can handle frequent polling (optimize queries)
- Use database indexes on `orderRequestData` and `inProgressOrderID`
- Consider caching user data for short periods
- Monitor API performance and scale as needed

---

## 🎯 Summary

**Key APIs:**
1. `GET /users/{userId}` - Polled every 3 seconds (most critical)
2. `GET /driver/get-current-reject-accept` - Fetches order details
3. `GET /mobile/orders/{orderId}/billing/to-pay` - Gets payment amount

**Critical Requirements:**
- Always return JSON (never HTML)
- `orderRequestData` and `inProgressOrderID` must be arrays
- Include nested objects for `vendor` and `author`
- Update arrays correctly when orders are accepted/rejected/completed

---

**Last Updated:** December 2024
**App Version:** Driver Delivery App



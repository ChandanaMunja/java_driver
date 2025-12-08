# 🧪 Complete API Testing Guide - Driver App

## 📋 All APIs Used in Driver App

This document tests **ALL** APIs used in the driver app with expected responses.

---

## 🔧 Base URL

```
https://web.jippymart.in/api/
```

---

## 1. ✅ GET Driver Profile (User Data)

**Endpoint:** `GET /users/{userId}`  
**Frequency:** Polled every 3 seconds  
**Purpose:** Get driver data including `orderRequestData` and `inProgressOrderID`

### Test Command:
```bash
curl -X GET "https://web.jippymart.in/api/users/j77nu4rNRzV2YZi8tqbdJxQ6Msh1" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json"
```

### ✅ Expected Success Response (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "j77nu4rNRzV2YZi8tqbdJxQ6Msh1",
    "firstName": "A",
    "lastName": "1",
    "email": "A1@gmail.com",
    "phone": "8790490405",
    "phoneNumber": "8790490405",
    "profile_pic": null,
    "countryCode": "91",
    "role": "driver",
    "active": 1,
    "isActive": true,
    "isDocumentVerify": "1",
    "zoneId": "BmSTwRFzmP13PnVNFJZJ",
    "vendorID": null,
    "wallet_amount": 3164,
    "deliveryAmount": 79,
    "location": {
      "latitude": 15.4968519,
      "longitude": 80.0511298
    },
    "inProgressOrderID": ["Jippy33000024"],
    "orderRequestData": [],
    "rotation": 0,
    "carName": null,
    "carNumber": null,
    "carPictureURL": null,
    "fcmToken": "optional_fcm_token",
    "createdAt": 1699123456789
  }
}
```

### ⚠️ Critical Fields:
- ✅ `orderRequestData` - **MUST be array** `[]` or `["order1", "order2"]`
- ✅ `inProgressOrderID` - **MUST be array** `[]` or `["order1"]`
- ✅ `location` - **MUST have** `latitude` and `longitude`
- ✅ `zoneId` - Required for order assignment

### ❌ Common Errors:
- `orderRequestData: null` → Should be `[]`
- `orderRequestData: "[order1]"` → Should be `["order1"]` (array, not string)
- Missing `location` → App needs driver location

---

## 2. ✅ GET Current Order (Primary Endpoint)

**Endpoint:** `GET /driver/get-current-reject-accept?order_id={id}&exclude_statuses={statuses}`  
**Purpose:** Fetch full order details  
**Fallback:** Uses `/restaurant/orders/{id}` if this fails

### Test Command:
```bash
curl -X GET "https://web.jippymart.in/api/driver/get-current-reject-accept?order_id=Jippy33000024&exclude_statuses=Order%20Cancelled,Driver%20Rejected,Order%20Completed" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json"
```

### ✅ Expected Success Response (200 OK):
```json
{
  "success": true,
  "order": {
    "id": "Jippy33000024",
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
      "totalCalculatedCharge": "36"
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

### ❌ Error Response (500 - Current Issue):
```json
{
  "error": "Internal Server Error",
  "message": "Method not found or database error"
}
```

**Status:** This endpoint currently returns 500 - app uses fallback

### ⚠️ Critical Fields:
- ✅ `vendor` - **MUST be object** (not string)
- ✅ `author` - **MUST be object** with nested `location`
- ✅ `address` - **MUST have** nested `location` with `latitude` and `longitude`
- ✅ `products` - Array of product objects

---

## 3. ✅ GET Order by ID (Fallback Endpoint)

**Endpoint:** `GET /restaurant/orders/{orderId}`  
**Purpose:** Fallback when primary endpoint fails  
**Used When:** Primary endpoint returns 500 error

### Test Command:
```bash
curl -X GET "https://web.jippymart.in/api/restaurant/orders/Jippy33000024" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json"
```

### ✅ Expected Success Response (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "Jippy33000024",
    "status": "Driver Pending",
    "vendorID": "vendor_123",
    "driverID": null,
    "authorID": "customer_456",
    "payment_method": "cod",
    "deliveryCharge": "25",
    "tipAmount": "10",
    "products": [...],
    "vendor": {...},
    "author": {...},
    "address": {...}
  }
}
```

**Note:** Response structure uses `data` instead of `order` (app handles both)

---

## 4. ✅ GET To-Pay Amount (Order Billing)

**Endpoint:** `GET /mobile/orders/{orderId}/billing/to-pay`  
**Purpose:** Get final amount customer needs to pay (COD orders)

### Test Command:
```bash
curl -X GET "https://web.jippymart.in/api/mobile/orders/Jippy33000024/billing/to-pay" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json"
```

### ✅ Expected Success Response (200 OK):
```json
{
  "success": true,
  "data": {
    "found": true,
    "to_pay": 185.50
  }
}
```

### ❌ Error Response (200 OK with success=false):
```json
{
  "success": false,
  "data": {
    "found": false
  },
  "message": "Billing information not found"
}
```

### ⚠️ Critical:
- ✅ **MUST return JSON** (never HTML)
- ✅ `to_pay` should be **number**, not string
- ✅ Return `found: false` if billing doesn't exist

---

## 5. ✅ POST Driver Orders List

**Endpoint:** `POST /driver/orders`  
**Purpose:** Get list of all orders for driver (order history)

### Test Command:
```bash
curl -X POST "https://web.jippymart.in/api/driver/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "driver_id": "j77nu4rNRzV2YZi8tqbdJxQ6Msh1"
  }'
```

### ✅ Expected Success Response (200 OK):
```json
{
  "success": true,
  "orders": [
    {
      "id": "Jippy33000024",
      "status": "Order Completed",
      "vendorID": "vendor_123",
      "driverID": "j77nu4rNRzV2YZi8tqbdJxQ6Msh1",
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

## 6. ✅ POST Assign Order to Driver

**Endpoint:** `POST /driver-sql/orders/assign`  
**Purpose:** Assign order to driver (when accepting)

### Test Command:
```bash
curl -X POST "https://web.jippymart.in/api/driver-sql/orders/assign" \
  -H "Content-Type: application/json" \
  -d '{
    "driver_id": "j77nu4rNRzV2YZi8tqbdJxQ6Msh1",
    "order_id": "Jippy33000024"
  }'
```

### ✅ Expected Success Response (200 OK):
```json
{
  "success": true,
  "message": "Order assigned successfully"
}
```

### ❌ Error Response:
```json
{
  "success": false,
  "message": "Order already assigned to another driver"
}
```

---

## 7. ✅ POST Remove Order from Other Drivers

**Endpoint:** `POST /driver-sql/orders/remove-from-others`  
**Purpose:** Remove order from other drivers when one accepts

### Test Command:
```bash
curl -X POST "https://web.jippymart.in/api/driver-sql/orders/remove-from-others" \
  -H "Content-Type: application/json" \
  -d '{
    "assigned_driver_id": "j77nu4rNRzV2YZi8tqbdJxQ6Msh1",
    "order_id": "Jippy33000024"
  }'
```

### ✅ Expected Success Response (200 OK):
```json
{
  "success": true,
  "message": "Order removed from other drivers"
}
```

---

## 8. ✅ GET Today's Completed Orders Count

**Endpoint:** `GET /orders/completed/today/{driverId}`  
**Purpose:** Get count of orders completed today (for bonus calculation)

### Test Command:
```bash
curl -X GET "https://web.jippymart.in/api/orders/completed/today/j77nu4rNRzV2YZi8tqbdJxQ6Msh1" \
  -H "Accept: application/json"
```

### ✅ Expected Success Response (200 OK):
```json
{
  "success": true,
  "count": 5
}
```

---

## 9. ✅ POST Zone Bonus by Zone ID

**Endpoint:** `POST /zone/bonus/byZoneId`  
**Purpose:** Get zone bonus information

### Test Command:
```bash
curl -X POST "https://web.jippymart.in/api/zone/bonus/byZoneId" \
  -H "Content-Type: application/json" \
  -d '{
    "zone_id": "BmSTwRFzmP13PnVNFJZJ"
  }'
```

### ✅ Expected Success Response (200 OK):
```json
{
  "success": true,
  "data": {
    "requiredOrdersForBonus": 5,
    "bonusAmount": 100
  }
}
```

---

## 🧪 Complete Test Script

### Test All APIs (Bash Script):

```bash
#!/bin/bash

BASE_URL="https://web.jippymart.in/api"
DRIVER_ID="j77nu4rNRzV2YZi8tqbdJxQ6Msh1"
ORDER_ID="Jippy33000024"
ZONE_ID="BmSTwRFzmP13PnVNFJZJ"

echo "🧪 Testing All Driver App APIs..."
echo ""

# Test 1: Get Driver Profile
echo "1️⃣ Testing GET /users/{userId}"
curl -s -X GET "$BASE_URL/users/$DRIVER_ID" \
  -H "Accept: application/json" | jq '.'
echo ""
echo "✅ Expected: success=true, orderRequestData and inProgressOrderID as arrays"
echo ""

# Test 2: Get Current Order (Primary)
echo "2️⃣ Testing GET /driver/get-current-reject-accept"
curl -s -X GET "$BASE_URL/driver/get-current-reject-accept?order_id=$ORDER_ID&exclude_statuses=Order%20Cancelled,Driver%20Rejected,Order%20Completed" \
  -H "Accept: application/json" | jq '.'
echo ""
echo "✅ Expected: success=true with order object (or 500 if broken)"
echo ""

# Test 3: Get Order by ID (Fallback)
echo "3️⃣ Testing GET /restaurant/orders/{orderId} (Fallback)"
curl -s -X GET "$BASE_URL/restaurant/orders/$ORDER_ID" \
  -H "Accept: application/json" | jq '.'
echo ""
echo "✅ Expected: success=true with data object"
echo ""

# Test 4: Get To-Pay Amount
echo "4️⃣ Testing GET /mobile/orders/{orderId}/billing/to-pay"
curl -s -X GET "$BASE_URL/mobile/orders/$ORDER_ID/billing/to-pay" \
  -H "Accept: application/json" | jq '.'
echo ""
echo "✅ Expected: success=true, found=true, to_pay as number"
echo ""

# Test 5: Get Driver Orders List
echo "5️⃣ Testing POST /driver/orders"
curl -s -X POST "$BASE_URL/driver/orders" \
  -H "Content-Type: application/json" \
  -d "{\"driver_id\": \"$DRIVER_ID\"}" | jq '.'
echo ""
echo "✅ Expected: success=true with orders array"
echo ""

# Test 6: Assign Order
echo "6️⃣ Testing POST /driver-sql/orders/assign"
curl -s -X POST "$BASE_URL/driver-sql/orders/assign" \
  -H "Content-Type: application/json" \
  -d "{\"driver_id\": \"$DRIVER_ID\", \"order_id\": \"$ORDER_ID\"}" | jq '.'
echo ""
echo "✅ Expected: success=true"
echo ""

# Test 7: Get Today's Completed Orders
echo "7️⃣ Testing GET /orders/completed/today/{driverId}"
curl -s -X GET "$BASE_URL/orders/completed/today/$DRIVER_ID" \
  -H "Accept: application/json" | jq '.'
echo ""
echo "✅ Expected: success=true with count"
echo ""

# Test 8: Get Zone Bonus
echo "8️⃣ Testing POST /zone/bonus/byZoneId"
curl -s -X POST "$BASE_URL/zone/bonus/byZoneId" \
  -H "Content-Type: application/json" \
  -d "{\"zone_id\": \"$ZONE_ID\"}" | jq '.'
echo ""
echo "✅ Expected: success=true with bonus data"
echo ""

echo "🎉 All API tests completed!"
```

**Save as:** `test_all_apis.sh`  
**Run:** `chmod +x test_all_apis.sh && ./test_all_apis.sh`

---

## 📱 Full App Testing Checklist

### Pre-Test Setup

- [ ] Driver account exists and is active
- [ ] Driver has valid `zoneId`
- [ ] Driver location is set
- [ ] At least one order exists in database
- [ ] Order is in driver's `orderRequestData` or `inProgressOrderID`

### Test 1: Driver Profile API

**Test:** `GET /users/{userId}`

- [ ] Returns 200 OK
- [ ] `success: true`
- [ ] `orderRequestData` is array (not string, not null)
- [ ] `inProgressOrderID` is array (not string, not null)
- [ ] `location` has `latitude` and `longitude`
- [ ] `zoneId` is present

**Expected in App:**
- [ ] Driver profile loads
- [ ] No crashes
- [ ] App logs show: "Driver profile fetched & order flow executed"

### Test 2: Order Fetching (Primary)

**Test:** `GET /driver/get-current-reject-accept`

- [ ] Returns 200 OK (or 500 if broken)
- [ ] If 200: Returns JSON with `success: true` and `order` object
- [ ] If 500: App should try fallback automatically

**Expected in App:**
- [ ] If primary works: Order displays immediately
- [ ] If primary fails: App tries fallback (check logs)
- [ ] No crashes

### Test 3: Order Fetching (Fallback)

**Test:** `GET /restaurant/orders/{orderId}`

- [ ] Returns 200 OK
- [ ] Returns JSON with `success: true` and `data` object
- [ ] Order data includes `vendor`, `author`, `address`

**Expected in App:**
- [ ] Order displays via fallback
- [ ] Logs show: "✅ Order fetched via FALLBACK endpoint"
- [ ] Map shows order location
- [ ] Order details are visible

### Test 4: Polling Mechanism

**Test:** App polls every 3 seconds

- [ ] App calls `GET /users/{userId}` every 3 seconds
- [ ] New orders detected within 3 seconds
- [ ] Orders appear automatically

**Expected in App:**
- [ ] Logs show: "Periodic order check completed" every 3 seconds
- [ ] New orders appear without manual refresh
- [ ] App doesn't freeze or crash

### Test 5: Order Acceptance

**Test:** Accept an order

- [ ] Click "Accept" on order
- [ ] `POST /driver-sql/orders/assign` is called
- [ ] Order moves from `orderRequestData` to `inProgressOrderID`
- [ ] Order status changes to "Driver Accepted"

**Expected in App:**
- [ ] Order accepted successfully
- [ ] Order removed from request list
- [ ] Order appears in active deliveries
- [ ] Map updates with route

### Test 6: Order Delivery

**Test:** Complete an order

- [ ] Mark order as delivered
- [ ] `GET /mobile/orders/{orderId}/billing/to-pay` is called
- [ ] Payment amount is fetched
- [ ] Order is completed

**Expected in App:**
- [ ] To-pay amount displays correctly
- [ ] Order can be marked as completed
- [ ] Order removed from `inProgressOrderID`
- [ ] Wallet updated

### Test 7: Error Handling

**Test:** API failures

- [ ] Primary API returns 500 → Fallback works
- [ ] Network error → App retries automatically
- [ ] Invalid order ID → Order removed from lists
- [ ] HTML response → App handles gracefully

**Expected in App:**
- [ ] No crashes on API errors
- [ ] Errors logged clearly
- [ ] App continues polling
- [ ] User sees appropriate messages

### Test 8: App Lifecycle

**Test:** App resume/foreground

- [ ] App goes to background
- [ ] App comes to foreground
- [ ] Orders refresh immediately

**Expected in App:**
- [ ] Logs show: "App resumed - triggering immediate order refresh"
- [ ] Orders refresh within 1 second
- [ ] No duplicate orders

---

## 🐛 Common Issues & Solutions

### Issue 1: Orders Not Appearing

**Check:**
1. Is `orderRequestData` array populated?
2. Does primary API return 500? (Check fallback)
3. Does fallback API work?
4. Are order IDs valid?

**Fix:**
- Add order ID to `orderRequestData` in database
- Test fallback endpoint manually
- Check app logs for errors

### Issue 2: Primary API Returns 500

**Check:**
- Laravel logs: `tail -f storage/logs/laravel.log`
- Route exists: `php artisan route:list | grep get-current-reject-accept`
- Controller method exists

**Fix:**
- See `BACKEND_500_ERROR_FIX.md`
- Implement controller method
- Test with curl

### Issue 3: Fallback Also Fails

**Check:**
- Does `/restaurant/orders/{id}` endpoint exist?
- Does it return JSON (not HTML)?
- Is order in database?

**Fix:**
- Verify endpoint exists
- Check database for order
- Test endpoint manually

### Issue 4: Arrays Returned as Strings

**Check:**
- `orderRequestData: "[order1]"` instead of `["order1"]`

**Fix:**
- Use JSON type in database, not TEXT
- Don't double-encode JSON
- Use proper JSON encoding in backend

---

## ✅ Success Criteria

### All APIs Working:
- [x] GET /users/{userId} - Returns driver data
- [x] GET /driver/get-current-reject-accept - Returns order (or 500 with fallback)
- [x] GET /restaurant/orders/{id} - Returns order (fallback)
- [x] GET /mobile/orders/{id}/billing/to-pay - Returns payment amount
- [x] POST /driver/orders - Returns order list
- [x] POST /driver-sql/orders/assign - Assigns order
- [x] GET /orders/completed/today/{id} - Returns count
- [x] POST /zone/bonus/byZoneId - Returns bonus data

### App Working:
- [x] Orders appear automatically
- [x] Polling works every 3 seconds
- [x] Fallback mechanism works
- [x] Orders can be accepted
- [x] Orders can be delivered
- [x] No crashes on errors

---

## 🎯 Quick Test Commands

```bash
# Test driver profile
curl "https://web.jippymart.in/api/users/j77nu4rNRzV2YZi8tqbdJxQ6Msh1" | jq '.data.orderRequestData, .data.inProgressOrderID'

# Test primary order endpoint
curl "https://web.jippymart.in/api/driver/get-current-reject-accept?order_id=Jippy33000024&exclude_statuses=Order%20Cancelled,Driver%20Rejected" | jq '.success'

# Test fallback endpoint
curl "https://web.jippymart.in/api/restaurant/orders/Jippy33000024" | jq '.success'

# Test to-pay endpoint
curl "https://web.jippymart.in/api/mobile/orders/Jippy33000024/billing/to-pay" | jq '.data.to_pay'
```

---

**Run all tests and verify each API returns expected responses!** 🚀



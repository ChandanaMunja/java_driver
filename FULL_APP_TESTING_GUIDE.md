# 🧪 Complete Full App Testing Guide - Driver App

## 📋 Overview

This guide provides **step-by-step instructions** to test the entire driver app, including all screens, features, and API integrations.

---

## 🚀 Pre-Testing Setup

### 1. Update Test IDs in Script
```bash
# Edit test_all_apis.sh and update these variables:
DRIVER_ID="j77nu4rNRzV2YZi8tqbdJxQ6Msh1"  # Your driver ID
ORDER_ID="Jippy33000024"                   # An existing order ID
ZONE_ID="BmSTwRFzmP13PnVNFJZJ"            # Your zone ID
```

### 2. Run API Tests First
```bash
chmod +x test_all_apis.sh
./test_all_apis.sh
```

**Expected:** All APIs should return 200 OK (except `/driver/get-current-reject-accept` which may return 500 - that's OK, app uses fallback).

---

## 📱 Screen-by-Screen Testing

### **Screen 1: Splash Screen** ✅

**What to Test:**
- App launches and shows splash screen
- Automatically redirects to login or dashboard

**Expected Behavior:**
- Splash screen appears for 1-2 seconds
- If logged in → Goes to Dashboard
- If not logged in → Goes to Login Screen

**API Calls:**
- None (uses local storage)

---

### **Screen 2: Login Screen** ✅

**What to Test:**
- Enter phone number
- Enter OTP (if applicable)
- Login button works

**Expected Behavior:**
- Phone number validation
- OTP sent successfully
- Login redirects to Dashboard

**API Calls:**
- `POST /auth/login` or similar
- `GET /users/{userId}` (after login)

**Check Logs For:**
```
✅ Login successful
✅ User profile loaded
✅ Redirecting to Dashboard
```

---

### **Screen 3: Dashboard (Home Screen)** 🎯 **CRITICAL**

**What to Test:**
1. **Order Polling**
   - Orders should appear automatically every 3 seconds
   - Check logs for polling messages

2. **Order Display**
   - New orders appear in `orderRequestData`
   - In-progress orders appear in `inProgressOrderID`
   - Order card shows correct details

3. **App Lifecycle**
   - Put app in background, then resume
   - Orders should refresh immediately

**Expected Behavior:**
- Orders appear within 3 seconds of assignment
- Order cards show: Order ID, Customer Name, Address, Amount
- No duplicate orders
- Orders move from "New" to "In Progress" when accepted

**API Calls (Every 3 seconds):**
- `GET /users/{userId}` - Primary polling
- `GET /driver/get-current-reject-accept?order_id={id}` - Fetch order details
- `GET /restaurant/orders/{orderId}` - Fallback if primary fails

**Check Logs For:**
```
✅ Starting automatic order polling every 3 seconds
✅ Periodic order check completed
✅ Order fetched via PRIMARY endpoint - ID: {orderId}
✅ Order fetched via FALLBACK endpoint - ID: {orderId} (if primary fails)
```

**Common Issues:**
- ❌ Orders not appearing → Check `orderRequestData` in `/users/{userId}` response
- ❌ 500 error → App should automatically use fallback endpoint
- ❌ Duplicate orders → Check backend data consistency

---

### **Screen 4: Order Details (Accept/Reject)** 🎯 **CRITICAL**

**What to Test:**
1. **Accept Order**
   - Tap "Accept" button
   - Order should move to "In Progress"
   - Order should disappear from "New Orders"

2. **Reject Order**
   - Tap "Reject" button
   - Order should be removed from `orderRequestData`
   - Order should not appear again

**Expected Behavior:**
- Accept button updates order status
- Order moves to `inProgressOrderID`
- Order removed from `orderRequestData`
- Map updates with delivery location

**API Calls:**
- `POST /driver-sql/orders/assign` - Accept order
- `POST /driver/reject-order` - Reject order (if exists)
- `GET /users/{userId}` - Refresh driver data

**Check Logs For:**
```
✅ Order accepted successfully
✅ Order status updated
✅ Driver data refreshed
```

**Common Issues:**
- ❌ Accept fails → Check order status in database
- ❌ Order still in `orderRequestData` → Backend issue (see `API_RESPONSE_ANALYSIS.md`)

---

### **Screen 5: Delivery Order Screen** 🎯 **CRITICAL**

**What to Test:**
1. **Order Information**
   - Customer name, phone, address displayed
   - Order items listed correctly
   - Total amount shown

2. **Navigation**
   - "Navigate" button opens map
   - Map shows correct delivery location

3. **Mark as Delivered**
   - Tap "Mark as Delivered"
   - Enter payment method (COD/Online)
   - Enter amount received
   - Confirm delivery

**Expected Behavior:**
- All order details displayed correctly
- Navigation works
- Delivery confirmation updates order status
- Wallet amount increases

**API Calls:**
- `GET /mobile/orders/{orderId}/billing/to-pay` - Get amount to pay
- `POST /orders/{orderId}/deliver` - Mark as delivered
- `GET /users/{userId}` - Refresh wallet amount

**Check Logs For:**
```
✅ ToPay fetched: {amount}
✅ Order delivered successfully
✅ Wallet updated
```

**Common Issues:**
- ❌ `toPay` is null → Check API response (should not be HTML)
- ❌ HTML response error → API returning error page (app should handle gracefully)

---

### **Screen 6: Order List Screen**

**What to Test:**
- View all past orders
- Filter by date/status
- View order details

**Expected Behavior:**
- List shows completed orders
- Order details accessible
- Filters work correctly

**API Calls:**
- `POST /driver/orders` - Get driver orders
- `GET /restaurant/orders/{orderId}` - Get order details

---

### **Screen 7: Wallet Screen**

**What to Test:**
- View wallet balance
- View transaction history
- Withdraw funds (if applicable)

**Expected Behavior:**
- Wallet amount matches backend
- Transaction history accurate
- Withdraw button works (if enabled)

**API Calls:**
- `GET /users/{userId}` - Get wallet_amount
- `GET /wallet/transactions` - Get transaction history (if exists)

---

### **Screen 8: Profile/Edit Profile**

**What to Test:**
- View profile information
- Edit name, phone, photo
- Save changes

**Expected Behavior:**
- Profile data loads correctly
- Edits save successfully
- Changes reflect immediately

**API Calls:**
- `GET /users/{userId}` - Get profile
- `PUT /users/{userId}` - Update profile

---

### **Screen 9: Verification Screen**

**What to Test:**
- View verification status
- Upload documents
- Check verification progress

**Expected Behavior:**
- Status displayed correctly
- Document upload works
- Verification updates

---

### **Screen 10: Chat/Inbox**

**What to Test:**
- View messages
- Send messages
- Receive notifications

**Expected Behavior:**
- Messages load
- Sending works
- Real-time updates

---

## 🔄 Order Flow Testing (End-to-End)

### **Test Scenario 1: Complete Order Flow** 🎯

**Steps:**
1. ✅ **Driver logs in** → Dashboard appears
2. ✅ **New order assigned** → Order appears in "New Orders" within 3 seconds
3. ✅ **Driver accepts order** → Order moves to "In Progress"
4. ✅ **Driver navigates** → Map opens with delivery location
5. ✅ **Driver arrives** → Can mark as "Arrived" (if feature exists)
6. ✅ **Driver delivers** → Enters payment, confirms delivery
7. ✅ **Order completed** → Order moves to "Completed Orders"
8. ✅ **Wallet updated** → Balance increases

**Expected Timeline:**
- Order appears: **Within 3 seconds** of assignment
- Accept action: **Immediate** (< 1 second)
- Delivery confirmation: **Immediate** (< 2 seconds)

**Check All Logs:**
```
✅ Order polling started
✅ Order fetched - ID: {orderId}
✅ Order accepted
✅ Order delivered
✅ Wallet updated
```

---

### **Test Scenario 2: Order Rejection**

**Steps:**
1. ✅ New order appears
2. ✅ Driver taps "Reject"
3. ✅ Order disappears from list
4. ✅ Order does not reappear

**Expected:**
- Order removed from `orderRequestData`
- Order status updated to "Driver Rejected"

---

### **Test Scenario 3: Multiple Orders**

**Steps:**
1. ✅ Multiple orders assigned
2. ✅ All orders appear in list
3. ✅ Driver accepts one
4. ✅ Other orders remain visible
5. ✅ Driver can accept another after completing first

**Expected:**
- All orders in `orderRequestData` appear
- Orders don't interfere with each other
- Order prioritization works (inProgressOrderID first)

---

### **Test Scenario 4: App Background/Foreground**

**Steps:**
1. ✅ App running, orders visible
2. ✅ Put app in background (home button)
3. ✅ Wait 10 seconds
4. ✅ Resume app
5. ✅ Orders should refresh immediately

**Expected:**
- App resumes
- `forceRefreshOrders()` called
- Orders refresh within 1 second

**Check Logs:**
```
✅ App resumed - triggering immediate order refresh
✅ Order check completed
```

---

## 🐛 Error Handling Tests

### **Test 1: API 500 Error Handling**

**Steps:**
1. Simulate `/driver/get-current-reject-accept` returning 500
2. App should automatically use fallback endpoint
3. Order should still appear

**Expected:**
- Primary API fails (500)
- Fallback API succeeds
- Order displayed correctly

**Check Logs:**
```
⚠️ Primary API returned 500 - will try fallback endpoint
✅ Order fetched via FALLBACK endpoint
```

---

### **Test 2: Network Timeout**

**Steps:**
1. Disable internet
2. App should handle gracefully
3. Re-enable internet
4. Orders should resume polling

**Expected:**
- No crashes
- Error messages shown
- Polling resumes when connection restored

---

### **Test 3: Invalid JSON Response**

**Steps:**
1. Simulate API returning HTML instead of JSON
2. App should detect and handle gracefully

**Expected:**
- HTML response detected
- Error logged
- App continues working
- Fallback used if available

**Check Logs:**
```
⚠️ API returned HTML instead of JSON
✅ Using fallback mechanism
```

---

## 📊 API Response Validation

### **Critical API Responses to Verify:**

#### 1. `GET /users/{userId}` ✅
```json
{
  "success": true,
  "data": {
    "orderRequestData": ["Jippy33000024"],  // ✅ Array of order IDs
    "inProgressOrderID": ["Jippy33000025"], // ✅ Array of order IDs
    "wallet_amount": 3164,                   // ✅ Number
    "location": {                            // ✅ Object
      "latitude": 15.4968519,
      "longitude": 80.0511298
    }
  }
}
```

**❌ Common Issues:**
- `orderRequestData` is `null` instead of `[]`
- Same order ID in both `orderRequestData` and `inProgressOrderID`
- `location` is `null`

---

#### 2. `GET /driver/get-current-reject-accept` ✅
```json
{
  "success": true,
  "order": {
    "id": "Jippy33000024",
    "status": "Order Placed",
    "vendor": { ... },      // ✅ Object or JSON string
    "driver": { ... },      // ✅ Object or JSON string
    "address": { ... }     // ✅ Object or JSON string
  }
}
```

**❌ Common Issues:**
- Returns 500 Internal Server Error
- Returns HTML instead of JSON
- `order` is `null`

**✅ App Fix:** Automatically uses fallback endpoint if this fails

---

#### 3. `GET /restaurant/orders/{orderId}` ✅ (Fallback)
```json
{
  "success": true,
  "data": {
    "id": "Jippy33000024",
    "status": "Order Placed",
    "vendor": { ... },
    "driver": { ... },
    "address": { ... }
  }
}
```

**Expected:** Always returns 200 OK with order data

---

#### 4. `GET /mobile/orders/{orderId}/billing/to-pay` ✅
```json
{
  "success": true,
  "data": {
    "found": true,
    "to_pay": 150.50
  }
}
```

**❌ Common Issues:**
- Returns HTML error page
- `to_pay` is `null`
- `found` is `false`

**✅ App Fix:** Falls back to order's `toPay` value if API fails

---

## ✅ Testing Checklist

### **Pre-Launch Checklist:**
- [ ] All APIs return 200 OK (or expected errors)
- [ ] `test_all_apis.sh` script passes
- [ ] Driver ID, Order ID, Zone ID are valid
- [ ] Backend database has test orders

### **Functional Testing:**
- [ ] Login works
- [ ] Dashboard loads
- [ ] Orders appear within 3 seconds
- [ ] Accept order works
- [ ] Reject order works
- [ ] Navigation works
- [ ] Mark as delivered works
- [ ] Wallet updates correctly
- [ ] Order list shows completed orders
- [ ] Profile editing works

### **Error Handling:**
- [ ] 500 errors handled gracefully
- [ ] Network timeouts handled
- [ ] HTML responses detected
- [ ] Fallback mechanisms work
- [ ] No app crashes

### **Performance:**
- [ ] Orders appear within 3 seconds
- [ ] No UI freezing
- [ ] Smooth navigation
- [ ] Efficient polling (not too frequent)

### **Lifecycle:**
- [ ] App resume triggers refresh
- [ ] Background/foreground handled
- [ ] Polling continues after resume

---

## 🔍 Debugging Tips

### **If Orders Don't Appear:**

1. **Check API Response:**
   ```bash
   curl -X GET "https://web.jippymart.in/api/users/{driverId}" \
     -H "Accept: application/json"
   ```
   - Verify `orderRequestData` has order IDs
   - Verify `inProgressOrderID` doesn't have duplicates

2. **Check App Logs:**
   - Look for "Order fetched" messages
   - Check for API errors
   - Verify polling is active

3. **Check Backend:**
   - Order status is correct
   - Order assigned to correct driver
   - Database consistency

### **If toPay is Null:**

1. **Check API:**
   ```bash
   curl -X GET "https://web.jippymart.in/api/mobile/orders/{orderId}/billing/to-pay"
   ```
   - Should return JSON, not HTML
   - Should have `to_pay` value

2. **Check App Logs:**
   - Look for "Error fetching toPay"
   - Check if fallback is used

### **If 500 Errors:**

1. **Check Backend Logs:**
   - Laravel error logs
   - Database connection
   - SQL query errors

2. **App Should:**
   - Automatically use fallback
   - Still display orders
   - Log the error

---

## 📝 Test Report Template

**Date:** _______________  
**Tester:** _______________  
**App Version:** _______________  
**Device:** _______________

### **API Tests:**
- [ ] All APIs return expected responses
- [ ] Fallback mechanisms work
- [ ] Error handling works

### **Order Flow:**
- [ ] Orders appear within 3 seconds
- [ ] Accept works
- [ ] Delivery works
- [ ] Wallet updates

### **Issues Found:**
1. ________________________________
2. ________________________________
3. ________________________________

### **Notes:**
________________________________
________________________________

---

## 🎯 Quick Test Commands

### **Test All APIs:**
```bash
./test_all_apis.sh
```

### **Test Single API:**
```bash
# Get driver profile
curl -X GET "https://web.jippymart.in/api/users/j77nu4rNRzV2YZi8tqbdJxQ6Msh1" \
  -H "Accept: application/json" | jq

# Get order
curl -X GET "https://web.jippymart.in/api/restaurant/orders/Jippy33000024" \
  -H "Accept: application/json" | jq

# Get toPay
curl -X GET "https://web.jippymart.in/api/mobile/orders/Jippy33000024/billing/to-pay" \
  -H "Accept: application/json" | jq
```

### **Monitor App Logs:**
```bash
# Android
adb logcat | grep -i flutter

# Filter for specific tags
adb logcat | grep -E "API|Polling|Order"
```

---

## 🚨 Critical Issues to Watch For

1. **Orders Not Appearing:**
   - Check `orderRequestData` in `/users/{userId}`
   - Check polling logs
   - Check API responses

2. **500 Errors:**
   - App should use fallback
   - Backend needs fixing (see `BACKEND_500_ERROR_FIX.md`)

3. **Duplicate Orders:**
   - Same order in `orderRequestData` and `inProgressOrderID`
   - Backend data inconsistency (see `API_RESPONSE_ANALYSIS.md`)

4. **toPay Null:**
   - API returning HTML
   - App should use fallback value

5. **Polling Not Working:**
   - Check timer initialization
   - Check app lifecycle
   - Check network connectivity

---

## 📚 Related Documentation

- `API_GUIDE.md` - Complete API documentation
- `API_QUICK_REFERENCE.md` - Quick API reference
- `BACKEND_500_ERROR_FIX.md` - Backend fix for 500 errors
- `API_RESPONSE_ANALYSIS.md` - Data consistency analysis
- `COMPLETE_FIX_AND_TEST.md` - App-side fixes summary
- `test_all_apis.sh` - Automated API testing script

---

## ✅ Success Criteria

**App is working correctly if:**
- ✅ Orders appear within 3 seconds of assignment
- ✅ All API calls return expected responses (or use fallback)
- ✅ Accept/Reject orders work
- ✅ Delivery confirmation works
- ✅ Wallet updates correctly
- ✅ No crashes or freezes
- ✅ App handles errors gracefully
- ✅ Polling continues reliably

---

**🎉 Happy Testing!**

If you encounter any issues, refer to the debugging tips or check the related documentation files.



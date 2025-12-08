# ✅ Quick Testing Checklist - Driver App

## 🚀 Quick Start (5 Minutes)

### Step 1: Test APIs (2 minutes)
```bash
chmod +x test_all_apis.sh
./test_all_apis.sh
```
**Expected:** All APIs return 200 OK (or expected errors)

---

### Step 2: Test App Flow (3 minutes)

#### ✅ Login
- [ ] Login successful
- [ ] Dashboard appears

#### ✅ Order Display
- [ ] Orders appear within 3 seconds
- [ ] Order cards show correct info
- [ ] No duplicate orders

#### ✅ Accept Order
- [ ] Tap "Accept"
- [ ] Order moves to "In Progress"
- [ ] Order disappears from "New Orders"

#### ✅ Deliver Order
- [ ] Navigate to delivery location
- [ ] Mark as delivered
- [ ] Enter payment details
- [ ] Wallet amount increases

---

## 📋 Full Testing Checklist

### **APIs** (Run `./test_all_apis.sh`)
- [ ] `GET /users/{userId}` → Returns driver data with `orderRequestData`
- [ ] `GET /driver/get-current-reject-accept` → Returns order (or 500 - OK, uses fallback)
- [ ] `GET /restaurant/orders/{orderId}` → Returns order (fallback)
- [ ] `GET /mobile/orders/{orderId}/billing/to-pay` → Returns amount
- [ ] `POST /driver/orders` → Returns order list
- [ ] `POST /driver-sql/orders/assign` → Accepts order

### **Screens**
- [ ] Splash Screen → Redirects correctly
- [ ] Login Screen → Login works
- [ ] Dashboard → Orders appear
- [ ] Order Details → Accept/Reject works
- [ ] Delivery Screen → Navigation works
- [ ] Delivery Screen → Mark delivered works
- [ ] Order List → Shows completed orders
- [ ] Wallet → Shows correct balance
- [ ] Profile → Edit works

### **Order Flow**
- [ ] New order appears within 3 seconds
- [ ] Accept order → Status updates
- [ ] Reject order → Order removed
- [ ] Deliver order → Status updates
- [ ] Wallet updates after delivery
- [ ] Order appears in completed list

### **Error Handling**
- [ ] 500 errors → Uses fallback endpoint
- [ ] Network timeout → Handles gracefully
- [ ] HTML responses → Detected and handled
- [ ] Invalid JSON → No crashes

### **App Lifecycle**
- [ ] App resume → Orders refresh immediately
- [ ] Background/Foreground → Polling continues
- [ ] No crashes on resume

### **Performance**
- [ ] Orders appear within 3 seconds
- [ ] No UI freezing
- [ ] Smooth navigation
- [ ] Efficient polling

---

## 🐛 Common Issues & Quick Fixes

| Issue | Quick Check | Fix |
|-------|-------------|-----|
| Orders not appearing | Check `orderRequestData` in API | Backend data issue |
| 500 error | Check logs for fallback | App uses fallback automatically |
| toPay is null | Check API response | App uses fallback value |
| Duplicate orders | Check `inProgressOrderID` vs `orderRequestData` | Backend data inconsistency |
| Polling not working | Check app logs | Restart app |

---

## 📊 Expected API Responses

### ✅ Good Response Examples:

**`/users/{userId}`:**
```json
{
  "success": true,
  "data": {
    "orderRequestData": ["Jippy33000024"],
    "inProgressOrderID": [],
    "wallet_amount": 3164
  }
}
```

**`/driver/get-current-reject-accept`:**
```json
{
  "success": true,
  "order": {
    "id": "Jippy33000024",
    "status": "Order Placed"
  }
}
```

**`/mobile/orders/{orderId}/billing/to-pay`:**
```json
{
  "success": true,
  "data": {
    "found": true,
    "to_pay": 150.50
  }
}
```

---

## 🎯 Critical Test Scenarios

### Scenario 1: New Order Assignment
1. Assign order to driver (via backend/admin)
2. **Expected:** Order appears in app within 3 seconds
3. **Check:** Logs show "Order fetched"

### Scenario 2: Accept Order
1. Tap "Accept" on new order
2. **Expected:** Order moves to "In Progress"
3. **Check:** `inProgressOrderID` contains order ID

### Scenario 3: Deliver Order
1. Navigate to delivery location
2. Mark as delivered
3. Enter payment
4. **Expected:** Order completed, wallet updated
5. **Check:** Wallet amount increases

### Scenario 4: App Resume
1. Put app in background
2. Wait 10 seconds
3. Resume app
4. **Expected:** Orders refresh immediately
5. **Check:** Logs show "App resumed - triggering refresh"

---

## ✅ Success Indicators

**App is working if:**
- ✅ Orders appear within 3 seconds
- ✅ All buttons work (Accept, Reject, Deliver)
- ✅ No crashes
- ✅ Wallet updates correctly
- ✅ Polling continues reliably

---

## 📝 Test Report

**Date:** _______________  
**Tester:** _______________  
**Status:** [ ] Pass [ ] Fail  
**Issues:** _______________

---

**💡 Tip:** Run `./test_all_apis.sh` first, then test the app manually.



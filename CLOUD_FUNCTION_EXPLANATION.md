# Cloud Function: How `orderRequestData` Works

## Overview
The Cloud Function automatically adds orders to drivers' `orderRequestData` array when a new order is created or when an order status changes to "Order Accepted".

## Flow Diagram

```
Order Created/Updated
    ↓
Status = "Order Accepted"?
    ↓ YES
Find Eligible Drivers (within radius)
    ↓
For each eligible driver:
    ↓
Check if orderId NOT already in orderRequestData
    ↓
Add orderId to driver.orderRequestData array
    ↓
Send Push Notification to Driver
    ↓
Set Order Status = "Driver Pending"
```

## Key Code Sections

### 1. **Trigger Point** (Line 7)
```javascript
exports.dispatch = onDocumentWritten("restaurant_orders/{orderID}", async (event) => {
```
- Triggers when ANY order document is created or updated in Firestore
- Watches the `restaurant_orders` collection

### 2. **Status Check** (Line 40)
```javascript
if (orderData.status === "Order Accepted" || orderData.status === "Driver Rejected") {
```
- Only processes orders with status "Order Accepted" or "Driver Rejected"
- Skips "Order Placed", "Order Cancelled", etc.

### 3. **Finding Eligible Drivers** (Lines 79-108)
```javascript
const snapshot = await firestore
    .collection("users")
    .where('role', '==', "driver")
    .where('isActive', '==', true)
    .where('wallet_amount', '>=', minimumDepositToRideAccept)
    .get();
```

**Driver Eligibility Criteria:**
- ✅ Role = "driver"
- ✅ isActive = true
- ✅ wallet_amount >= minimumDepositToRideAccept
- ✅ Same zoneId as order
- ✅ Has FCM token (for notifications)
- ✅ Has location data
- ✅ NOT in rejectedByDrivers list
- ✅ No in-progress orders (or only empty array)
- ✅ Within radius distance from vendor

### 4. **Adding to orderRequestData** (Lines 114-118)
```javascript
if (!driver.orderRequestData.includes(orderId)) {
    const ref = firestore.collection('users').doc(driver.id);
    batch.update(ref, {
        orderRequestData: admin.firestore.FieldValue.arrayUnion(orderId)
    });
}
```

**What happens:**
- Checks if orderId is NOT already in driver's `orderRequestData` array
- Uses `arrayUnion()` to add the orderId (prevents duplicates)
- Uses batch write for efficiency (updates all drivers at once)

### 5. **Setting Order Status** (Line 135)
```javascript
await change.data.after.ref.set({ status: "Driver Pending" }, { merge: true });
```
- Changes order status from "Order Accepted" to "Driver Pending"
- This tells the app that the order is waiting for driver acceptance

### 6. **Cleanup Function** (Lines 229-250)
```javascript
exports.cleanUpOrderRequestData = onDocumentUpdated("restaurant_orders/{orderId}", async (event) => {
    if (before.status === "Driver Pending" && after.status === "Driver Accepted") {
        // Remove orderId from all OTHER drivers' orderRequestData
        // Keep it only for the assigned driver
    }
});
```

**What happens when driver accepts:**
- When order status changes from "Driver Pending" → "Driver Accepted"
- Finds all drivers who have this orderId in their `orderRequestData`
- Removes the orderId from all drivers EXCEPT the one who accepted it
- This prevents other drivers from seeing an already-accepted order

## Timing Issue Explanation

### The Problem:
1. Order is created with status "Order Accepted"
2. Cloud Function triggers (takes 1-3 seconds)
3. Cloud Function finds drivers and adds to `orderRequestData` (takes 1-2 seconds)
4. Driver app polls every 5 seconds
5. **Gap**: Order exists but not yet in `orderRequestData` → Bottom sheet doesn't show

### The Solution (in our code):
- Show orders with "Driver Pending" or "Order Accepted" status even if not in `orderRequestData` yet
- Keep displaying orders temporarily even if they're not in arrays (handles Cloud Function delays)
- Periodic polling will eventually sync, but order is visible immediately

## Radius Search Strategy

The function searches in expanding radii:
```javascript
const RADIUS_STEPS = [1, 2, 3, 5, 10, 20]; // in km
```

- Starts with 1km radius
- If no drivers found, expands to 2km
- Continues up to 20km
- Stops as soon as drivers are found
- This ensures nearby drivers get orders first

## Example Scenario

1. **Customer places order** → Status: "Order Placed"
2. **Restaurant accepts** → Status: "Order Accepted" (Cloud Function triggers)
3. **Cloud Function finds 3 drivers within 2km**
4. **Adds orderId to each driver's orderRequestData:**
   ```
   Driver A: orderRequestData = ["Jippy33000144"]
   Driver B: orderRequestData = ["Jippy33000144"]
   Driver C: orderRequestData = ["Jippy33000144"]
   ```
5. **Sets order status** → "Driver Pending"
6. **Sends push notifications** to all 3 drivers
7. **Driver A accepts** → Status: "Driver Accepted"
8. **Cleanup function removes from Driver B and C:**
   ```
   Driver A: orderRequestData = ["Jippy33000144"] (keeps it - they accepted)
   Driver B: orderRequestData = [] (removed)
   Driver C: orderRequestData = [] (removed)
   ```

## Important Notes

- **Asynchronous**: Cloud Function runs asynchronously, so there's a delay (1-5 seconds)
- **Batch Updates**: Uses Firestore batch writes for efficiency
- **Duplicate Prevention**: Checks `includes()` before adding to prevent duplicates
- **Zone Matching**: Only sends to drivers in the same zone as the order
- **Distance Calculation**: Uses Haversine formula to calculate distance between driver and vendor



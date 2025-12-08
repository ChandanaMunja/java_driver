# 🐛 Issue Found: Data Inconsistency

## ❌ The Problem

Your API response shows the **same order ID in BOTH arrays**:

```json
{
  "inProgressOrderID": ["Jippy33000024"],  // ← Order is in progress
  "orderRequestData": ["Jippy33000024"]    // ← Same order still in requests! ❌
}
```

**This is WRONG!** An order should only be in ONE array:
- ✅ If order is **accepted/in-progress** → Only in `inProgressOrderID`
- ✅ If order is **pending/new** → Only in `orderRequestData`
- ❌ **NEVER in both!**

## 🔍 Why This Happens

When a driver accepts an order, your backend should:
1. ✅ Add order to `inProgressOrderID` 
2. ❌ **REMOVE order from `orderRequestData`** ← This step is missing!

## ✅ The Fix

### Option 1: SQL Fix (Immediate)

Run this SQL to clean up the duplicate:

```sql
-- Remove order from orderRequestData if it's already in inProgressOrderID
UPDATE users 
SET orderRequestData = JSON_REMOVE(
    orderRequestData,
    JSON_UNQUOTE(
        JSON_SEARCH(orderRequestData, 'one', 'Jippy33000024')
    )
)
WHERE id = 'j77nu4rNRzV2YZi8tqbdJxQ6Msh1'
  AND JSON_CONTAINS(inProgressOrderID, '"Jippy33000024"')
  AND JSON_CONTAINS(orderRequestData, '"Jippy33000024"');
```

**Or simpler (if using MySQL 8.0+):**
```sql
UPDATE users 
SET orderRequestData = JSON_REMOVE(
    orderRequestData,
    JSON_SEARCH(orderRequestData, 'one', 'Jippy33000024')
)
WHERE id = 'j77nu4rNRzV2YZi8tqbdJxQ6Msh1';
```

### Option 2: Fix in Your Backend Code

When order is accepted, update BOTH arrays:

**Laravel Example:**
```php
// When driver accepts order
public function acceptOrder($orderId, $driverId) {
    $driver = User::find($driverId);
    
    // Add to inProgressOrderID
    $inProgress = $driver->inProgressOrderID ?? [];
    if (!in_array($orderId, $inProgress)) {
        $inProgress[] = $orderId;
    }
    
    // REMOVE from orderRequestData
    $orderRequest = $driver->orderRequestData ?? [];
    $orderRequest = array_values(array_filter($orderRequest, function($id) use ($orderId) {
        return $id !== $orderId;
    }));
    
    $driver->update([
        'inProgressOrderID' => $inProgress,
        'orderRequestData' => $orderRequest
    ]);
    
    // Update order status
    Order::where('id', $orderId)->update([
        'status' => 'Driver Accepted',
        'driverID' => $driverId
    ]);
}
```

**Raw SQL Example:**
```sql
-- When accepting order
UPDATE users 
SET 
    -- Add to inProgressOrderID
    inProgressOrderID = JSON_ARRAY_APPEND(
        COALESCE(inProgressOrderID, JSON_ARRAY()),
        '$',
        'Jippy33000024'
    ),
    -- REMOVE from orderRequestData
    orderRequestData = JSON_REMOVE(
        orderRequestData,
        JSON_UNQUOTE(JSON_SEARCH(orderRequestData, 'one', 'Jippy33000024'))
    )
WHERE id = 'j77nu4rNRzV2YZi8tqbdJxQ6Msh1';

-- Update order
UPDATE orders 
SET status = 'Driver Accepted', driverID = 'j77nu4rNRzV2YZi8tqbdJxQ6Msh1'
WHERE id = 'Jippy33000024';
```

## 🧪 Test the Order API

After fixing the duplicate, test if the order API works:

```bash
curl "https://web.jippymart.in/api/driver/get-current-reject-accept?order_id=Jippy33000024&exclude_statuses=Order%20Cancelled,Driver%20Rejected,Order%20Completed"
```

**Expected Response:**
```json
{
  "success": true,
  "order": {
    "id": "Jippy33000024",
    "status": "Driver Accepted",
    "vendor": {...},
    "author": {...},
    "address": {...}
  }
}
```

**If it returns HTML or error:**
- The order API endpoint might be broken
- Check backend logs
- Verify the order exists in database

## 📋 Correct Flow

### When Order is Created:
```json
{
  "orderRequestData": ["Jippy33000024"],  // ✅ New order
  "inProgressOrderID": []                 // ✅ Empty
}
```

### When Driver Accepts:
```json
{
  "orderRequestData": [],                 // ✅ Removed
  "inProgressOrderID": ["Jippy33000024"]   // ✅ Added
}
```

### When Order is Completed:
```json
{
  "orderRequestData": [],                 // ✅ Empty
  "inProgressOrderID": []                 // ✅ Removed
}
```

## 🔧 Backend Cleanup Function

Add this to your backend to automatically clean up duplicates:

**Laravel (in User Model or Controller):**
```php
public function cleanupDuplicateOrders() {
    $drivers = User::where('role', 'driver')->get();
    
    foreach ($drivers as $driver) {
        $inProgress = $driver->inProgressOrderID ?? [];
        $orderRequest = $driver->orderRequestData ?? [];
        
        // Remove any orders from orderRequestData that are in inProgressOrderID
        $orderRequest = array_values(array_filter($orderRequest, function($orderId) use ($inProgress) {
            return !in_array($orderId, $inProgress);
        }));
        
        if ($orderRequest !== ($driver->orderRequestData ?? [])) {
            $driver->update(['orderRequestData' => $orderRequest]);
        }
    }
}
```

**SQL Cleanup (Run periodically):**
```sql
-- Clean up all drivers with duplicate orders
UPDATE users u
SET orderRequestData = (
    SELECT JSON_ARRAYAGG(order_id)
    FROM (
        SELECT DISTINCT JSON_UNQUOTE(JSON_EXTRACT(orderRequestData, CONCAT('$[', idx, ']'))) as order_id
        FROM users u2,
        JSON_TABLE(
            JSON_ARRAY(1),
            '$[*]' COLUMNS (idx INT PATH '$')
        ) AS t
        WHERE u2.id = u.id
        AND JSON_EXTRACT(u2.orderRequestData, CONCAT('$[', idx, ']')) IS NOT NULL
        AND JSON_UNQUOTE(JSON_EXTRACT(u2.orderRequestData, CONCAT('$[', idx, ']'))) 
            NOT IN (
                SELECT JSON_UNQUOTE(JSON_EXTRACT(inProgressOrderID, CONCAT('$[', idx2, ']')))
                FROM users u3,
                JSON_TABLE(
                    JSON_ARRAY(1),
                    '$[*]' COLUMNS (idx2 INT PATH '$')
                ) AS t2
                WHERE u3.id = u.id
                AND JSON_EXTRACT(u3.inProgressOrderID, CONCAT('$[', idx2, ']')) IS NOT NULL
            )
    ) AS filtered
)
WHERE role = 'driver'
AND JSON_LENGTH(COALESCE(orderRequestData, JSON_ARRAY())) > 0;
```

**Simpler SQL (if above is too complex):**
```sql
-- For each driver, manually check and clean
-- This is a simpler approach - run for specific driver
UPDATE users 
SET orderRequestData = JSON_REMOVE(
    orderRequestData,
    JSON_UNQUOTE(JSON_SEARCH(orderRequestData, 'one', 'Jippy33000024'))
)
WHERE id = 'j77nu4rNRzV2YZi8tqbdJxQ6Msh1'
  AND JSON_CONTAINS(COALESCE(inProgressOrderID, JSON_ARRAY()), '"Jippy33000024"')
  AND JSON_CONTAINS(COALESCE(orderRequestData, JSON_ARRAY()), '"Jippy33000024"');
```

## ✅ Quick Fix (Run This Now)

```sql
UPDATE users 
SET orderRequestData = JSON_REMOVE(
    orderRequestData,
    JSON_UNQUOTE(JSON_SEARCH(orderRequestData, 'one', 'Jippy33000024'))
)
WHERE id = 'j77nu4rNRzV2YZi8tqbdJxQ6Msh1';
```

After running this, your response should be:
```json
{
  "inProgressOrderID": ["Jippy33000024"],  // ✅ Only here
  "orderRequestData": []                    // ✅ Clean!
}
```

## 🎯 Summary

**The Issue:**
- Same order ID in both arrays (data inconsistency)

**The Fix:**
1. Remove order from `orderRequestData` when it's in `inProgressOrderID`
2. Update your backend code to do this automatically
3. Test the order API endpoint

**After Fix:**
- App should display the order from `inProgressOrderID`
- No more duplicates
- Clean data structure

---

**Run the SQL fix above, then test the app again!**



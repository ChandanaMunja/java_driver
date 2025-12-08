# 🚨 CRITICAL: 500 Internal Server Error Fix

## ❌ The Problem

**API Endpoint:** `GET /api/driver/get-current-reject-accept?order_id=Jippy30001672&exclude_statuses=Order%20Cancelled,Driver%20Rejected,Order%20Completed`

**Error:** `500 Internal Server Error`

**Impact:** Orders cannot be fetched, so drivers cannot see any orders!

---

## 🔍 Root Cause Analysis

A 500 error means the backend code is **crashing**. Common causes:

1. **Method name typo/mismatch** - Controller method doesn't exist
2. **Database query error** - SQL/query is failing
3. **Missing data/relationships** - Trying to access null relationships
4. **JSON encoding error** - Response formatting issue
5. **Missing dependencies** - Required classes/files not found

---

## ✅ Backend Implementation Guide

### Laravel Implementation

**Route (routes/api.php):**
```php
Route::get('driver/get-current-reject-accept', [DriverSqlBridgeController::class, 'getCurrentRejectAccept']);
```

**Controller Method (app/Http/Controllers/Api/DriverSqlBridgeController.php):**
```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DriverSqlBridgeController extends Controller
{
    /**
     * Get current order for driver (reject/accept flow)
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getCurrentRejectAccept(Request $request)
    {
        try {
            // Get query parameters
            $orderId = $request->query('order_id');
            $excludeStatuses = $request->query('exclude_statuses', '');
            
            // Validate order_id
            if (empty($orderId)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Order ID is required'
                ], 400);
            }
            
            // Parse exclude statuses
            $excludeStatusArray = [];
            if (!empty($excludeStatuses)) {
                $excludeStatusArray = array_map('trim', explode(',', $excludeStatuses));
            }
            
            // Fetch order with relationships
            $order = DB::table('orders')
                ->where('id', $orderId)
                ->first();
            
            // Check if order exists
            if (!$order) {
                return response()->json([
                    'success' => false,
                    'message' => 'Order not found'
                ], 200); // Return 200 with success=false
            }
            
            // Check if order status is excluded
            if (in_array($order->status, $excludeStatusArray)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Order status is excluded'
                ], 200);
            }
            
            // Fetch vendor details
            $vendor = null;
            if (!empty($order->vendorID)) {
                $vendor = DB::table('users')
                    ->where('id', $order->vendorID)
                    ->where('role', 'vendor')
                    ->first();
            }
            
            // Fetch customer (author) details
            $author = null;
            if (!empty($order->authorID)) {
                $author = DB::table('users')
                    ->where('id', $order->authorID)
                    ->where('role', 'customer')
                    ->first();
            }
            
            // Fetch address
            $address = null;
            if (!empty($order->addressID)) {
                $address = DB::table('shipping_addresses')
                    ->where('id', $order->addressID)
                    ->first();
            }
            
            // Fetch products
            $products = DB::table('order_products')
                ->where('orderID', $orderId)
                ->get();
            
            // Build response
            $orderData = [
                'id' => $order->id,
                'status' => $order->status,
                'vendorID' => $order->vendorID,
                'driverID' => $order->driverID,
                'authorID' => $order->authorID,
                'payment_method' => $order->payment_method,
                'deliveryCharge' => $order->deliveryCharge,
                'tipAmount' => $order->tipAmount ?? '0',
                'discount' => $order->discount ?? 0,
                'couponCode' => $order->couponCode,
                'adminCommission' => $order->adminCommission,
                'adminCommissionType' => $order->adminCommissionType,
                'notes' => $order->notes,
                'createdAt' => $order->createdAt,
                'estimatedTimeToPrepare' => $order->estimatedTimeToPrepare,
                'products' => $products->map(function($product) {
                    return [
                        'id' => $product->id,
                        'name' => $product->name,
                        'quantity' => $product->quantity,
                        'price' => $product->price,
                        'image' => $product->image
                    ];
                }),
            ];
            
            // Add vendor (as object, not string)
            if ($vendor) {
                $orderData['vendor'] = [
                    'id' => $vendor->id,
                    'name' => $vendor->firstName . ' ' . $vendor->lastName,
                    'latitude' => $vendor->latitude ?? 0,
                    'longitude' => $vendor->longitude ?? 0,
                    'address' => $vendor->address ?? '',
                    'phoneNumber' => $vendor->phone ?? '',
                    'fcmToken' => $vendor->fcmToken ?? ''
                ];
            }
            
            // Add author/customer (as object, not string)
            if ($author) {
                $orderData['author'] = [
                    'id' => $author->id,
                    'firstName' => $author->firstName,
                    'lastName' => $author->lastName,
                    'phoneNumber' => $author->phone ?? '',
                    'location' => [
                        'latitude' => $author->latitude ?? 0,
                        'longitude' => $author->longitude ?? 0
                    ],
                    'fcmToken' => $author->fcmToken ?? ''
                ];
            }
            
            // Add address with location
            if ($address) {
                $orderData['address'] = [
                    'location' => [
                        'latitude' => $address->latitude ?? 0,
                        'longitude' => $address->longitude ?? 0
                    ],
                    'address' => $address->address ?? '',
                    'city' => $address->city ?? '',
                    'state' => $address->state ?? '',
                    'country' => $address->country ?? '',
                    'zipCode' => $address->zipCode ?? ''
                ];
            }
            
            // Add calculated charges if exists
            if (!empty($order->calculatedCharges)) {
                $orderData['calculatedCharges'] = is_string($order->calculatedCharges) 
                    ? json_decode($order->calculatedCharges, true) 
                    : $order->calculatedCharges;
            }
            
            // Add special discount if exists
            if (!empty($order->specialDiscount)) {
                $orderData['specialDiscount'] = is_string($order->specialDiscount)
                    ? json_decode($order->specialDiscount, true)
                    : $order->specialDiscount;
            }
            
            // Add tax settings
            if (!empty($order->taxSetting)) {
                $orderData['taxSetting'] = is_string($order->taxSetting)
                    ? json_decode($order->taxSetting, true)
                    : $order->taxSetting;
            }
            
            // Add rejected drivers
            if (!empty($order->rejectedByDrivers)) {
                $orderData['rejectedByDrivers'] = is_string($order->rejectedByDrivers)
                    ? json_decode($order->rejectedByDrivers, true)
                    : $order->rejectedByDrivers;
            }
            
            // Add toPay
            $orderData['toPay'] = $order->toPay ?? null;
            
            return response()->json([
                'success' => true,
                'order' => $orderData
            ], 200);
            
        } catch (\Exception $e) {
            // Log the error
            Log::error('Error in getCurrentRejectAccept: ' . $e->getMessage(), [
                'order_id' => $request->query('order_id'),
                'trace' => $e->getTraceAsString()
            ]);
            
            // Return error response (NOT 500, return 200 with success=false)
            return response()->json([
                'success' => false,
                'message' => 'Error fetching order: ' . $e->getMessage()
            ], 200);
        }
    }
}
```

---

## 🔧 Alternative: Using Eloquent Models

If you're using Eloquent models:

```php
public function getCurrentRejectAccept(Request $request)
{
    try {
        $orderId = $request->query('order_id');
        $excludeStatuses = $request->query('exclude_statuses', '');
        
        if (empty($orderId)) {
            return response()->json([
                'success' => false,
                'message' => 'Order ID is required'
            ], 400);
        }
        
        // Parse exclude statuses
        $excludeStatusArray = [];
        if (!empty($excludeStatuses)) {
            $excludeStatusArray = array_map('trim', explode(',', $excludeStatuses));
        }
        
        // Fetch order with relationships
        $order = Order::with(['vendor', 'author', 'address', 'products'])
            ->where('id', $orderId)
            ->first();
        
        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found'
            ], 200);
        }
        
        // Check excluded statuses
        if (in_array($order->status, $excludeStatusArray)) {
            return response()->json([
                'success' => false,
                'message' => 'Order status is excluded'
            ], 200);
        }
        
        // Format response
        $orderData = $order->toArray();
        
        // Ensure vendor and author are objects
        if ($order->vendor) {
            $orderData['vendor'] = $order->vendor->toArray();
        }
        
        if ($order->author) {
            $orderData['author'] = $order->author->toArray();
            // Add location if exists
            if ($order->author->location) {
                $orderData['author']['location'] = [
                    'latitude' => $order->author->location->latitude ?? 0,
                    'longitude' => $order->author->location->longitude ?? 0
                ];
            }
        }
        
        if ($order->address) {
            $orderData['address'] = $order->address->toArray();
            // Ensure location is nested
            if (isset($orderData['address']['latitude'])) {
                $orderData['address'] = [
                    'location' => [
                        'latitude' => $orderData['address']['latitude'],
                        'longitude' => $orderData['address']['longitude']
                    ],
                    'address' => $orderData['address']['address'] ?? '',
                    'city' => $orderData['address']['city'] ?? '',
                    'state' => $orderData['address']['state'] ?? '',
                    'country' => $orderData['address']['country'] ?? '',
                    'zipCode' => $orderData['address']['zipCode'] ?? ''
                ];
            }
        }
        
        return response()->json([
            'success' => true,
            'order' => $orderData
        ], 200);
        
    } catch (\Exception $e) {
        Log::error('Error in getCurrentRejectAccept: ' . $e->getMessage(), [
            'order_id' => $request->query('order_id'),
            'trace' => $e->getTraceAsString()
        ]);
        
        return response()->json([
            'success' => false,
            'message' => 'Error fetching order'
        ], 200);
    }
}
```

---

## 🐛 Debugging Steps

### 1. Check Laravel Logs

```bash
tail -f storage/logs/laravel.log
```

Look for the error message when calling the endpoint.

### 2. Check Route Registration

```bash
php artisan route:list | grep get-current-reject-accept
```

Should show:
```
GET|HEAD  api/driver/get-current-reject-accept ... DriverSqlBridgeController@getCurrentRejectAccept
```

### 3. Test the Endpoint Directly

```bash
curl -X GET "https://web.jippymart.in/api/driver/get-current-reject-accept?order_id=Jippy30001672&exclude_statuses=Order%20Cancelled,Driver%20Rejected,Order%20Completed" \
  -H "Accept: application/json"
```

### 4. Check Database

```sql
-- Verify order exists
SELECT * FROM orders WHERE id = 'Jippy30001672';

-- Check vendor exists
SELECT * FROM users WHERE id = (SELECT vendorID FROM orders WHERE id = 'Jippy30001672');

-- Check customer exists
SELECT * FROM users WHERE id = (SELECT authorID FROM orders WHERE id = 'Jippy30001672');
```

---

## ⚠️ Common Issues & Fixes

### Issue 1: Method Name Mismatch

**Error:** `Method App\Http\Controllers\Api\DriverSqlBridgeController::getOrderCancelRejectCompleated does not exist`

**Fix:** Check your route - method name must match exactly:
```php
// ❌ Wrong
Route::get('driver/get-current-reject-accept', [DriverSqlBridgeController::class, 'getOrderCancelRejectCompleated']);

// ✅ Correct
Route::get('driver/get-current-reject-accept', [DriverSqlBridgeController::class, 'getCurrentRejectAccept']);
```

### Issue 2: Missing Database Columns

**Error:** `Column not found: 1054 Unknown column 'addressID' in 'field list'`

**Fix:** Check your database schema. Adjust column names:
```php
// If your column is named differently:
$address = DB::table('shipping_addresses')
    ->where('orderID', $orderId)  // or 'order_id'
    ->first();
```

### Issue 3: JSON Encoding Error

**Error:** `json_encode(): Invalid UTF-8 sequence`

**Fix:** Clean data before encoding:
```php
// Remove invalid UTF-8 characters
$orderData = array_map(function($value) {
    if (is_string($value)) {
        return mb_convert_encoding($value, 'UTF-8', 'UTF-8');
    }
    return $value;
}, $orderData);
```

### Issue 4: Null Relationship

**Error:** `Trying to get property of non-object`

**Fix:** Always check for null:
```php
if ($vendor && isset($vendor->latitude)) {
    $orderData['vendor']['latitude'] = $vendor->latitude;
}
```

---

## ✅ Expected Response Format

**Success Response:**
```json
{
  "success": true,
  "order": {
    "id": "Jippy30001672",
    "status": "Driver Pending",
    "vendorID": "vendor_123",
    "driverID": null,
    "authorID": "customer_456",
    "payment_method": "cod",
    "deliveryCharge": "25",
    "tipAmount": "10",
    "vendor": {
      "id": "vendor_123",
      "name": "Pizza Palace",
      "latitude": 15.2258,
      "longitude": 79.8407
    },
    "author": {
      "id": "customer_456",
      "firstName": "John",
      "lastName": "Doe",
      "location": {
        "latitude": 15.2300,
        "longitude": 79.8500
      }
    },
    "address": {
      "location": {
        "latitude": 15.2300,
        "longitude": 79.8500
      },
      "address": "123 Main St"
    },
    "products": [...]
  }
}
```

**Error Response (200 OK with success=false):**
```json
{
  "success": false,
  "message": "Order not found"
}
```

**⚠️ IMPORTANT:** Always return HTTP 200, even on errors. Use `success: false` in JSON body.

---

## 🚀 Quick Fix Checklist

- [ ] Check Laravel logs for exact error
- [ ] Verify route is registered correctly
- [ ] Ensure controller method exists
- [ ] Check database schema matches queries
- [ ] Test endpoint with curl
- [ ] Verify order exists in database
- [ ] Check vendor/author relationships exist
- [ ] Ensure response is JSON (not HTML)
- [ ] Return HTTP 200 even on errors
- [ ] Add try-catch error handling

---

## 📞 Testing After Fix

```bash
# Test with valid order
curl "https://web.jippymart.in/api/driver/get-current-reject-accept?order_id=Jippy30001672&exclude_statuses=Order%20Cancelled,Driver%20Rejected,Order%20Completed"

# Test with invalid order
curl "https://web.jippymart.in/api/driver/get-current-reject-accept?order_id=INVALID&exclude_statuses=Order%20Cancelled"

# Test without order_id
curl "https://web.jippymart.in/api/driver/get-current-reject-accept"
```

All should return JSON (not HTML) with proper status codes.

---

**After fixing this, orders should start appearing in the driver app!** 🎉



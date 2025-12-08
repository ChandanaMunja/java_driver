#!/bin/bash

# Complete API Testing Script for Driver App
# Run: chmod +x test_all_apis.sh && ./test_all_apis.sh

BASE_URL="https://web.jippymart.in/api"
DRIVER_ID="j77nu4rNRzV2YZi8tqbdJxQ6Msh1"
ORDER_ID="Jippy33000024"
ZONE_ID="BmSTwRFzmP13PnVNFJZJ"

echo "🧪 ========================================="
echo "🧪 Testing All Driver App APIs"
echo "🧪 ========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Get Driver Profile
echo "1️⃣ Testing GET /users/{userId}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$BASE_URL/users/$DRIVER_ID" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | jq '.success, .data.orderRequestData, .data.inProgressOrderID, .data.location' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Status: $HTTP_STATUS${NC}"
    echo "$BODY"
fi
echo ""
echo "Expected: success=true, orderRequestData and inProgressOrderID as arrays"
echo ""

# Test 2: Get Current Order (Primary)
echo "2️⃣ Testing GET /driver/get-current-reject-accept"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$BASE_URL/driver/get-current-reject-accept?order_id=$ORDER_ID&exclude_statuses=Order%20Cancelled,Driver%20Rejected,Order%20Completed" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | jq '.success, .order.id, .order.status' 2>/dev/null || echo "$BODY"
elif [ "$HTTP_STATUS" = "500" ]; then
    echo -e "${YELLOW}⚠️  Status: $HTTP_STATUS (Expected - will use fallback)${NC}"
    echo "$BODY" | head -20
else
    echo -e "${RED}❌ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | head -20
fi
echo ""
echo "Expected: success=true with order object (or 500 if broken - app uses fallback)"
echo ""

# Test 3: Get Order by ID (Fallback)
echo "3️⃣ Testing GET /restaurant/orders/{orderId} (Fallback)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$BASE_URL/restaurant/orders/$ORDER_ID" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | jq '.success, .data.id, .data.status' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | head -20
fi
echo ""
echo "Expected: success=true with data object"
echo ""

# Test 4: Get To-Pay Amount
echo "4️⃣ Testing GET /mobile/orders/{orderId}/billing/to-pay"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$BASE_URL/mobile/orders/$ORDER_ID/billing/to-pay" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | jq '.success, .data.found, .data.to_pay' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | head -20
fi
echo ""
echo "Expected: success=true, found=true, to_pay as number"
echo ""

# Test 5: Get Driver Orders List
echo "5️⃣ Testing POST /driver/orders"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$BASE_URL/driver/orders" \
  -H "Content-Type: application/json" \
  -d "{\"driver_id\": \"$DRIVER_ID\"}")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | jq '.success, (.orders | length)' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | head -20
fi
echo ""
echo "Expected: success=true with orders array"
echo ""

# Test 6: Assign Order
echo "6️⃣ Testing POST /driver-sql/orders/assign"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$BASE_URL/driver-sql/orders/assign" \
  -H "Content-Type: application/json" \
  -d "{\"driver_id\": \"$DRIVER_ID\", \"order_id\": \"$ORDER_ID\"}")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | jq '.success' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | head -20
fi
echo ""
echo "Expected: success=true"
echo ""

# Test 7: Get Today's Completed Orders
echo "7️⃣ Testing GET /orders/completed/today/{driverId}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$BASE_URL/orders/completed/today/$DRIVER_ID" \
  -H "Accept: application/json")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | jq '.success, .count' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | head -20
fi
echo ""
echo "Expected: success=true with count"
echo ""

# Test 8: Get Zone Bonus
echo "8️⃣ Testing POST /zone/bonus/byZoneId"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$BASE_URL/zone/bonus/byZoneId" \
  -H "Content-Type: application/json" \
  -d "{\"zone_id\": \"$ZONE_ID\"}")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | jq '.success, .data' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Status: $HTTP_STATUS${NC}"
    echo "$BODY" | head -20
fi
echo ""
echo "Expected: success=true with bonus data"
echo ""

echo "🎉 ========================================="
echo "🎉 All API tests completed!"
echo "🎉 ========================================="
echo ""
echo "📋 Summary:"
echo "  - Check ✅ for working APIs"
echo "  - Check ⚠️  for expected failures (will use fallback)"
echo "  - Check ❌ for unexpected failures"
echo ""
echo "💡 Tip: Update DRIVER_ID, ORDER_ID, and ZONE_ID at the top of this script"



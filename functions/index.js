const { onDocumentWritten, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const firestore = admin.firestore();

const RADIUS_STEPS = [1, 2, 3, 5, 10, 20]; // in km, expand as needed

exports.dispatch = onDocumentWritten("restaurant_orders/{orderID}", async (event) => {
    const change = event;
    const orderData = change.data.after && change.data.after.data();
    const beforeData = change.data.before && change.data.before.data();
    if (beforeData && orderData) {
        const keysChanged = Object.keys(orderData).filter(
            key => JSON.stringify(orderData[key]) !== JSON.stringify(beforeData[key])
        );
        if (keysChanged.length === 1 && keysChanged.includes('orderAutoCancelAt')) {
            console.log("orderAutoCancelAt update detected, skipping dispatch logic.");
            return null;
        }
    }
    if (!orderData) {
        console.log("No order data");
        return;
    }

    if (orderData.status === "Order Cancelled") {
        console.log("Order #" + change.data.after.id + " was cancelled.")
        return null
    }

    if (orderData.status === "Order Placed") {
        console.log("Order #" + change.data.after.id + " was sent to vendor for approval.")
        return null
    }

    if (orderData.takeAway === true) {
        console.log("Order #" + change.data.after.id + " was sent as takeAway to vendor for approval.")
        return null
    }

    if (orderData.status === "Order Accepted" || orderData.status === "Driver Rejected") {
        console.log("Finding drivers for order #" + change.data.after.id)

        const rejectedByDrivers = orderData.rejectedByDrivers ? orderData.rejectedByDrivers : []
        var orderId = change.data.after.id;
        var driverNearByData = await getDriverNearByData();
        var minimumDepositToRideAccept = 0;
        var orderAcceptRejectDuration = 0;
        var orderAutoCancelDuration = 0;
        var singleOrderReceive = false;

        var zone_id = null;
        if(orderData.address.location.longitude && orderData.address.location.latitude){
            zone_id = await getUserZoneId(orderData.address.location.longitude,orderData.address.location.latitude);
            console.log('Zone id by address',zone_id);
        }

        if(driverNearByData !== undefined){
            if(driverNearByData.minimumDepositToRideAccept !== undefined){
                minimumDepositToRideAccept = parseInt(driverNearByData.minimumDepositToRideAccept);
            }
            if(driverNearByData.driverOrderAcceptRejectDuration !== undefined){
                orderAcceptRejectDuration = parseInt(driverNearByData.driverOrderAcceptRejectDuration);
            }
            if(driverNearByData.orderAutoCancelDuration !== undefined){
                orderAutoCancelDuration = parseInt(driverNearByData.orderAutoCancelDuration);
            }
            if(driverNearByData.singleOrderReceive !== undefined){
                singleOrderReceive = driverNearByData.singleOrderReceive;
            }
        }

        const vendor = orderData.vendor;
        if (!vendor || !vendor.latitude || !vendor.longitude) {
            console.log("Vendor location missing, cannot dispatch order.");
            return null;
        }

        let foundDrivers = [];
        for (let radius of RADIUS_STEPS) {
            // 1. Query all eligible drivers (active, wallet, not rejected, etc.)
            const snapshot = await firestore
                .collection("users")
                .where('role', '==', "driver")
                .where('isActive', '==', true)
                .where('wallet_amount', '>=', minimumDepositToRideAccept)
                .get();

            foundDrivers = [];
            for (const doc of snapshot.docs) {
                const driver = doc.data();
                // Check if driver has any in-progress order
                const inProgressOrderID = driver.inProgressOrderID || [];
                if (
                    driver.fcmToken &&
                    driver.zoneId === zone_id &&
                    driver.location &&
                    rejectedByDrivers.indexOf(driver.id) === -1 &&
                    (!inProgressOrderID || inProgressOrderID.length === 0 || (inProgressOrderID.length === 1 && inProgressOrderID[0] === ""))
                ) {
                    const distance = distanceRadius(
                        driver.location.latitude, driver.location.longitude,
                        vendor.latitude, vendor.longitude
                    );
                    if (distance <= radius) {
                        foundDrivers.push({ id: driver.id, fcmToken: driver.fcmToken, orderRequestData: driver.orderRequestData || [] });
                    }
                }
            }

            if (foundDrivers.length > 0) {
                // Broadcast to all found drivers
                const batch = firestore.batch();
                foundDrivers.forEach(driver => {
                    if (!driver.orderRequestData.includes(orderId)) {
                        const ref = firestore.collection('users').doc(driver.id);
                        batch.update(ref, {
                            orderRequestData: admin.firestore.FieldValue.arrayUnion(orderId)
                        });
                    }
                    // Send notification
                    var time = Math.floor(orderAcceptRejectDuration / 60) + ":" + (orderAcceptRejectDuration % 60 ? orderAcceptRejectDuration % 60 : '00');
                    var message = {
                        notification: {
                            title: 'New order received',
                            body: `You have a new order within ${radius} km! Please accept the order in ${time} mins`
                        },
                        token: driver.fcmToken
                    };
                    admin.messaging().send(message).catch((error) => {
                        console.log('Notification Error:', error);
                    });
                });
                await batch.commit();
                // Set order status to Driver Pending
                await change.data.after.ref.set({ status: "Driver Pending" }, { merge: true });
                console.log(`Order ${orderId} broadcast to ${foundDrivers.length} drivers within ${radius} km.`);
                return null;
            }
        }

        // If no drivers found in any radius
        const currentTime = new Date();
        const futureTime = new Date(currentTime.getTime() + orderAutoCancelDuration * 60 * 1000);
        const firebaseTimestamp = admin.firestore.Timestamp.fromDate(futureTime);
        await firestore.collection('restaurant_orders').doc(orderId).update({orderAutoCancelAt: firebaseTimestamp})
        console.log("Could not find an available driver for order #" + change.data.after.id + " in any radius.");
        return null;
    }

    if (orderData.status === "Driver Accepted") {
        change.data.after.ref.set({ status: "Order Shipped" }, {merge: true})
        console.log("Order #" + change.data.after.id + " was shipped")
        return null
    }
    return null
});

// --- Helper functions (unchanged) ---

const distanceRadius = (lat1, lon1, lat2, lon2) => {
    if ((lat1 === lat2) && (lon1 === lon2)) {
        return 0;
    }
    var radlat1 = Math.PI * lat1/180;
    var radlat2 = Math.PI * lat2/180;
    var theta = lon1-lon2;
    var radtheta = Math.PI * theta/180;
    var dist = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta);
    if (dist > 1) dist = 1;
    dist = Math.acos(dist);
    dist = dist * 180/Math.PI;
    dist = dist * 60 * 1.1515;
    dist = dist * 1.60934; // Convert to kilometers
    return dist;
}

async function getDriverNearByData(){
    var snapshot =  await firestore.collection("settings").doc('DriverNearBy').get();
    return snapshot.data();
}

async function getUserZoneId(address_lng,address_lat){
    var zone_id = null;
    var zone_list = [];
    var snapshots = await firestore.collection('zone').where("publish","==",true).get();
    if(snapshots.docs.length > 0){
        snapshots.docs.forEach((snapshot) => {
            var zone_data = snapshot.data();
            zone_list.push(zone_data);
        });   
    }
    if(zone_list.length > 0){
        for (i = 0; i < zone_list.length; i++) {
            var zone = zone_list[i];
            var vertices_x = [];
            var vertices_y = [];
            for (j = 0; j < zone.area.length; j++) {
                var geopoint = zone.area[j];
                vertices_x.push(geopoint.longitude);
                vertices_y.push(geopoint.latitude);
            }
            var points_polygon = (vertices_x.length)-1; 
            if(is_in_polygon(points_polygon, vertices_x, vertices_y, address_lng, address_lat)){
                zone_id = zone.id;
                console.log("Matched zone id by address",zone_id);
                break; 
            }
        }
    }
    return zone_id;
}

function is_in_polygon($points_polygon, $vertices_x, $vertices_y, $longitude_x, $latitude_y){
    $i = $j = $c = $point = 0;
    for ($i = 0, $j = $points_polygon ; $i < $points_polygon; $j = $i++) {
        $point = $i;
        if( $point === $points_polygon )
            $point = 0;
        if ( (($vertices_y[$point]  >  $latitude_y !== ($vertices_y[$j] > $latitude_y)) && ($longitude_x < ($vertices_x[$j] - $vertices_x[$point]) * ($latitude_y - $vertices_y[$point]) / ($vertices_y[$j] - $vertices_y[$point]) + $vertices_x[$point]) ) )
            $c = !$c;
    }
    return $c;
}

//
// --- CLEANUP FUNCTION: Remove order from all other drivers after assignment ---
//

exports.cleanUpOrderRequestData = onDocumentUpdated("restaurant_orders/{orderId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === "Driver Pending" && after.status === "Driver Accepted") {
        const orderId = event.params.orderId;
        const assignedDriverId = after.driverID;
        const driversSnap = await firestore.collection("users")
            .where('orderRequestData', 'array-contains', orderId)
            .get();

        const batch = firestore.batch();
        driversSnap.forEach(doc => {
            if (doc.id !== assignedDriverId) {
                batch.update(doc.ref, {
                    orderRequestData: admin.firestore.FieldValue.arrayRemove(orderId)
                });
            }
        });
        await batch.commit();
        console.log(`Order ${orderId} removed from other drivers' orderRequestData`);
    }
}); 
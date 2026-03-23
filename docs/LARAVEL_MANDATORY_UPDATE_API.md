# Laravel API: Mandatory Update (Driver Settings)

The driver app checks for mandatory update via **GET** `{baseUrl}driver-sql/forceupdate`. You can also expose the same payload in `driver-sql/settings` under `data.Version` if you use that endpoint for other settings.

---

## 1. Force-update endpoint (used by the app)

**GET** `{baseURL}driver-sql/forceupdate`

The app calls this on launch and uses the response to decide whether to show the mandatory update screen.

- **Same version** (e.g. app is 2.2.5 and `min_app_version` is 2.2.5) → **do not** show the update screen.
- **Lower version** (e.g. app is 2.2.4 and `min_app_version` is 2.2.5) → **show** the update screen.

### Response shape

You can return the object **directly** (no wrapper) or inside `data`:

**Option A – direct object (recommended):**

```json
{
  "googlePlayLink": "https://play.google.com/store/apps/details?id=com.jippymart.driver",
  "appStoreLink": "",
  "app_version": "2.2.5",
  "force_update": true,
  "min_app_version": "2.2.5"
}
```

**Option B – wrapped in `data`:**

```json
{
  "success": true,
  "data": {
    "googlePlayLink": "https://play.google.com/store/apps/details?id=com.jippymart.driver",
    "appStoreLink": "",
    "app_version": "2.2.5",
    "force_update": true,
    "min_app_version": "2.2.5"
  }
}
```

| Field              | Type   | Description |
|--------------------|--------|-------------|
| `googlePlayLink`   | string | Play Store URL (used when user taps Update on Android). |
| `appStoreLink`     | string | App Store URL (used on iOS). |
| `app_version`      | string | Latest app version (e.g. `"2.2.5"`). |
| `force_update`     | bool   | Optional; app ignores this for “show or not” and only compares versions. |
| `min_app_version`  | string | Minimum allowed version. App shows update screen **only when** current version is **less than** this. Same version = no screen. |
| `show_update`      | bool   | **Required.** When `true`, app checks version and shows update screen if needed. When `false`, update check is skipped. |

---

## 2. Laravel implementation

### Option A: Add columns to existing `settings` / config

If you already have a `settings` table or a config that builds the `Version` object:

**Migration (optional – only if you store Version in DB):**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('settings', function (Blueprint $table) {
            $table->boolean('force_update')->default(false)->after('app_version');
            $table->string('min_app_version', 20)->nullable()->after('force_update');
        });
    }

    public function down(): void
    {
        Schema::table('settings', function (Blueprint $table) {
            $table->dropColumn(['force_update', 'min_app_version']);
        });
    }
};
```

**Config (e.g. `config/driver_app.php`) – alternative to DB:**

```php
<?php

return [
    'version' => [
        'google_play_link'  => env('DRIVER_GOOGLE_PLAY_LINK', ''),
        'app_store_link'   => env('DRIVER_APP_STORE_LINK', ''),
        'app_version'      => env('DRIVER_APP_VERSION', '2.2.5'),
        'force_update'     => env('DRIVER_FORCE_UPDATE', false),
        'min_app_version'  => env('DRIVER_MIN_APP_VERSION', ''),
    ],
];
```

**.env example:**

```env
DRIVER_GOOGLE_PLAY_LINK=https://play.google.com/store/apps/details?id=com.jippymart.driver
DRIVER_APP_STORE_LINK=https://apps.apple.com/app/...
DRIVER_APP_VERSION=2.2.5
DRIVER_FORCE_UPDATE=false
DRIVER_MIN_APP_VERSION=2.2.5
```

---

### Controller: include `Version` in settings response

Ensure your settings endpoint returns `data.Version` with the new fields. Example:

```php
<?php

namespace App\Http\Controllers\Api\DriverSql;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class SettingsController extends Controller
{
    /**
     * GET /api/driver-sql/settings
     * Driver app fetches this on launch; Version controls mandatory update.
     */
    public function index(): JsonResponse
    {
        $data = [
            'globalSettings'   => $this->getGlobalSettings(),
            'googleMapKey'    => $this->getGoogleMapKey(),
            'Version'         => $this->getVersion(),
            'notification_setting' => $this->getNotificationSetting(),
            'RestaurantNearBy'=> $this->getRestaurantNearBy(),
            'privacyPolicy'   => $this->getPrivacyPolicy(),
            'termsAndConditions' => $this->getTermsAndConditions(),
            'referral_amount' => $this->getReferralAmount(),
            'DriverNearBy'    => $this->getDriverNearBy(),
            'document_verification_settings' => $this->getDocumentVerificationSettings(),
            // ... other keys your app expects
        ];

        return response()->json([
            'success' => true,
            'data'    => $data,
        ]);
    }

    /**
     * Version object – used for store links and mandatory update.
     */
    private function getVersion(): array
    {
        // Option 1: From config
        $version = config('driver_app.version', []);

        return [
            'googlePlayLink'   => $version['google_play_link'] ?? '',
            'appStoreLink'    => $version['app_store_link'] ?? '',
            'app_version'     => $version['app_version'] ?? '',
            'force_update'    => (bool) ($version['force_update'] ?? false),
            'min_app_version' => (string) ($version['min_app_version'] ?? ''),
        ];

        // Option 2: From DB (if you have a settings table)
        // $row = DB::table('settings')->where('key', 'driver_version')->first();
        // return [
        //     'googlePlayLink'   => $row->google_play_link ?? '',
        //     'appStoreLink'     => $row->app_store_link ?? '',
        //     'app_version'      => $row->app_version ?? '',
        //     'force_update'     => (bool) ($row->force_update ?? false),
        //     'min_app_version'  => (string) ($row->min_app_version ?? ''),
        // ];
    }

    private function getGlobalSettings(): array
    {
        // Your existing logic
        return [];
    }

    private function getGoogleMapKey(): array|string
    {
        // Your existing logic
        return ['key' => config('services.google_maps.key', '')];
    }

    private function getNotificationSetting(): array
    {
        return [];
    }

    private function getRestaurantNearBy(): array
    {
        return [];
    }

    private function getPrivacyPolicy(): array
    {
        return [];
    }

    private function getTermsAndConditions(): array
    {
        return [];
    }

    private function getReferralAmount(): array
    {
        return [];
    }

    private function getDriverNearBy(): array
    {
        return [];
    }

    private function getDocumentVerificationSettings(): array
    {
        return [];
    }
}
```

---

### Route (e.g. `routes/api.php`)

```php
use App\Http\Controllers\Api\DriverSql\SettingsController;
use App\Http\Controllers\Api\DriverSql\ForceUpdateController;

// Driver app settings
Route::get('driver-sql/settings', [SettingsController::class, 'index']);

// Force-update check (called on app launch)
Route::get('driver-sql/forceupdate', [ForceUpdateController::class, 'index']);
```

### Force-update controller (driver-sql/forceupdate)

```php
<?php

namespace App\Http\Controllers\Api\DriverSql;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class ForceUpdateController extends Controller
{
    /**
     * GET /api/driver-sql/forceupdate
     * Returns version and store links. App shows update screen only when current version < min_app_version.
     */
    public function index(): JsonResponse
    {
        $version = config('driver_app.version', []);

        $data = [
            'googlePlayLink'   => $version['google_play_link'] ?? '',
            'appStoreLink'     => $version['app_store_link'] ?? '',
            'app_version'      => $version['app_version'] ?? '2.2.5',
            'force_update'     => (bool) ($version['force_update'] ?? false),
            'min_app_version'  => (string) ($version['min_app_version'] ?? '2.2.5'),
            'show_update'      => (bool) ($version['show_update'] ?? true),
        ];

        return response()->json($data);
    }
}
```

---

## 3. How to use from backend

- **Force update for everyone (e.g. critical fix):**  
  Set `force_update` to `true` (and optionally set `min_app_version` for display). No version comparison; all users see the mandatory update screen.

- **Force update only for old versions:**  
  Set `min_app_version` to the minimum allowed version (e.g. `"2.2.5"`) and leave `force_update` false. The app compares installed version with `min_app_version` and shows the mandatory update screen only if installed version is lower.

- **No mandatory update:**  
  Set `force_update` to `false` and `min_app_version` to empty string (or omit it).

---

## 4. Quick test

```bash
curl -s "http://your-domain.com/api/driver-sql/settings" | jq '.data.Version'
```

Expected:

```json
{
  "googlePlayLink": "https://play.google.com/...",
  "appStoreLink": "https://apps.apple.com/...",
  "app_version": "2.2.5",
  "force_update": false,
  "min_app_version": "2.2.5"
}
```

The Flutter app reads both `force_update` and `min_app_version` (and supports `minAppVersion` as an alternate key) and shows the mandatory update screen when required.

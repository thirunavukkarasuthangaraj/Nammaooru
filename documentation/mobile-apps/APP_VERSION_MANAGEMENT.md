# App Version Management System

## Overview
The app version management system allows you to control which app versions are active and force users to update when necessary. This is especially important for the customer app which will be updated frequently.

## Database Structure

### `app_version` Table
```sql
- id: BIGSERIAL PRIMARY KEY
- app_name: VARCHAR(50) - 'CUSTOMER_APP', 'SHOP_OWNER_APP', 'DELIVERY_PARTNER_APP'
- platform: VARCHAR(20) - 'ANDROID', 'IOS'
- current_version: VARCHAR(20) - Latest available version (e.g., '1.2.0')
- minimum_version: VARCHAR(20) - Minimum required version (e.g., '1.0.0')
- update_url: TEXT - Play Store / App Store URL
- is_mandatory: BOOLEAN - If true, force update even if above minimum
- release_notes: TEXT - What's new in this version
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

## How It Works

### 1. **Version Check Flow**
```
App Startup → Check API → Compare Versions → Show Dialog (if needed)
```

### 2. **Update Scenarios**

#### Scenario A: Below Minimum Version (Force Update)
```
Current: 0.9.0
Minimum: 1.0.0
Current: 1.2.0
Result: MANDATORY UPDATE - Cannot skip dialog
```

#### Scenario B: Update Available (Optional)
```
Current: 1.0.0
Minimum: 1.0.0
Current: 1.2.0
Result: OPTIONAL UPDATE - Can skip dialog
```

#### Scenario C: is_mandatory = true (Force Update)
```
Current: 1.1.0
Minimum: 1.0.0
Current: 1.2.0
is_mandatory: true
Result: MANDATORY UPDATE - Cannot skip dialog
```

#### Scenario D: Up to Date
```
Current: 1.2.0
Minimum: 1.0.0
Current: 1.2.0
Result: No dialog shown
```

## API Endpoints

### Check Version
```http
GET /api/app-version/check?appName=CUSTOMER_APP&platform=ANDROID&currentVersion=1.0.0
```

**Response:**
```json
{
  "updateRequired": false,
  "updateAvailable": true,
  "isMandatory": false,
  "currentVersion": "1.2.0",
  "minimumVersion": "1.0.0",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.nammaooru.app",
  "releaseNotes": "- New features\n- Bug fixes\n- Performance improvements"
}
```

### Update Version (Admin)
```http
PUT /api/app-version/update
Content-Type: application/json

{
  "appName": "CUSTOMER_APP",
  "platform": "ANDROID",
  "currentVersion": "1.2.0",
  "minimumVersion": "1.1.0",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.nammaooru.app",
  "isMandatory": false,
  "releaseNotes": "What's new in this version..."
}
```

## Usage Guide

### For Customer App (Frequently Updated)

#### Step 1: Update App Version in Code
Edit `mobile/nammaooru_mobile_app/lib/core/services/app_update_service.dart`:
```dart
static const String APP_VERSION = '1.2.0'; // Update this with each release
```

Also update `pubspec.yaml`:
```yaml
version: 1.2.0+2
```

#### Step 2: Build and Release to Play Store
```bash
cd mobile/nammaooru_mobile_app
flutter build apk --release
# or
flutter build appbundle --release
```

#### Step 3: Update Database
Once the new version is live on Play Store, update the database:

**Option A: Using SQL**
```sql
UPDATE app_version
SET current_version = '1.2.0',
    minimum_version = '1.0.0',  -- Set this to force older users to update
    is_mandatory = false,        -- Set true to force all users to update
    release_notes = '- New features\n- Bug fixes',
    updated_at = NOW()
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';
```

**Option B: Using API**
```bash
curl -X PUT http://localhost:8080/api/app-version/update \
  -H "Content-Type: application/json" \
  -d '{
    "appName": "CUSTOMER_APP",
    "platform": "ANDROID",
    "currentVersion": "1.2.0",
    "minimumVersion": "1.0.0",
    "updateUrl": "https://play.google.com/store/apps/details?id=com.nammaooru.app",
    "isMandatory": false,
    "releaseNotes": "• New checkout flow\n• Performance improvements\n• Bug fixes"
  }'
```

## Best Practices

### 1. **Version Numbering**
Use semantic versioning: `MAJOR.MINOR.PATCH`
- `MAJOR`: Breaking changes
- `MINOR`: New features (backward compatible)
- `PATCH`: Bug fixes

### 2. **Minimum Version Strategy**
- Keep `minimum_version` 2-3 versions behind `current_version`
- Only update `minimum_version` for critical security fixes or breaking API changes
- Example: If current is 1.5.0, minimum can be 1.3.0

### 3. **Mandatory Updates**
Use `is_mandatory = true` only when:
- Critical security vulnerability
- Breaking backend API changes
- Database migration that affects older versions

### 4. **Release Notes**
Write clear, user-friendly release notes:
```
✅ Good:
• Added dark mode
• Faster checkout process
• Fixed crash on order history

❌ Bad:
• Fixed bug in OrderService.java line 234
• Updated dependencies
```

## Testing

### Test Update Dialog
1. Change APP_VERSION in app to an old version (e.g., '0.9.0')
2. Set database current_version to '1.0.0'
3. Set minimum_version to '1.0.0'
4. Launch app → Should show mandatory update dialog

### Test Optional Update
1. Set APP_VERSION to '1.0.0'
2. Set database current_version to '1.1.0'
3. Set minimum_version to '1.0.0'
4. Set is_mandatory to false
5. Launch app → Should show optional update dialog with "Later" button

## Mobile App Integration

### Customer App
- ✅ Implemented in `customer_dashboard.dart`
- Checks version 2 seconds after dashboard loads
- Shows dialog if update is available

### Shop Owner App
- Not yet implemented (can add later if needed)

### Delivery Partner App
- Not yet implemented (can add later if needed)

## Current Versions

| App | Platform | Current Version | Minimum Version | Status |
|-----|----------|----------------|-----------------|--------|
| CUSTOMER_APP | ANDROID | 1.0.0 | 1.0.0 | Active |
| SHOP_OWNER_APP | ANDROID | 1.0.0 | 1.0.0 | Active |
| DELIVERY_PARTNER_APP | ANDROID | 1.0.0 | 1.0.0 | Active |

## Troubleshooting

### Dialog Not Showing
1. Check backend logs for API errors
2. Verify `EnvConfig.apiUrl` is correct
3. Check internet connection
4. Verify database has correct app_name and platform

### Wrong Update URL
1. Update `update_url` in database
2. Ensure URL opens Play Store correctly
3. Test URL format: `https://play.google.com/store/apps/details?id=com.nammaooru.app`

## Future Enhancements

1. **Admin Dashboard**: Web UI to manage versions instead of SQL
2. **Gradual Rollout**: Release updates to percentage of users first
3. **Analytics**: Track how many users are on each version
4. **In-App Updates**: Use Play Store API for seamless updates
5. **Regional Updates**: Different update urls for different countries

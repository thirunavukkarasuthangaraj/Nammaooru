# WhatsApp & Email Bill Delivery — Setup and Operations

POS bills are sent to customers as a **PDF file** via WhatsApp (direct Meta Cloud API) and/or email.
Last updated: 2026-08-02.

## How it works

1. Shop owner creates a bill in POS (web frontend) → clicks **Send WhatsApp** or **Send Email**
2. Backend generates a receipt-style PDF (`BillPdfService`, OpenPDF, matches the printed thermal receipt:
   ITEM/MRP/RATE/QTY/AMT, MRP total, You Save, payment method)
3. WhatsApp: PDF is saved under `<uploads>/bills/` and served publicly at
   `https://api.nammaoorudelivary.in/uploads/bills/<file>.pdf`; Meta fetches it and delivers it
   as a **document attachment** with the `bill_receipt` template message
4. Email: PDF is attached directly to the mail (`EmailService.sendBillEmail`)

## API endpoints (backend)

- `POST /api/pos/orders/{orderId}/send-whatsapp-bill` — body: `{"customerPhone": "...", "customerName": "..."}` (both optional if order has a customer)
- `POST /api/pos/orders/{orderId}/send-email-bill` — body: `{"customerEmail": "...", "customerName": "..."}`
- Roles: SUPER_ADMIN / ADMIN / SHOP_OWNER

## WhatsApp provider switch

`WhatsAppNotificationService` supports two providers, chosen by env var — **no code change to switch**:

| `WHATSAPP_PROVIDER` | Path |
|---|---|
| `meta` (current production) | Direct Meta Graph API (`graph.facebook.com`) |
| `msg91` (default fallback) | MSG91 relay (config intact, on standby) |

## Meta (Facebook) asset IDs

| Asset | Value |
|---|---|
| Business portfolio | NAMMA OORU Delivery (`1394368262077842`) — verified |
| Developer app | **NammaOoru API** (`1031771696443198`) — created 2026-08-02, linked to the portfolio above |
| WhatsApp Business Account (WABA) | `2567084310475176` ("Test Number" account) |
| Test sender number | +1 555-657-2240, **Phone Number ID `1200309309838861`** |
| System user | `nammaooru-api` (ID `61592450323388`) — holds the permanent token |
| Template | `bill_receipt` (Utility, en, DOCUMENT header + 4 body vars) — ID `3107501356127115` |
| Old app (DO NOT USE) | `nammaooru` (`1284266042571977`) — linked to old restricted portfolio "Namma ooru" |
| MSG91-managed WABA (leave alone) | "Nammaooru" (`1890385731546898`), has Jio Haptik credit line |

## Server environment (`/opt/shop-management/.env`)

```
WHATSAPP_PROVIDER=meta
META_WA_PHONE_NUMBER_ID=1200309309838861
META_WA_ACCESS_TOKEN=<permanent system-user token — never expires>
# optional: META_WA_API_VERSION=v21.0, META_WA_TEMPLATE_LANGUAGE=en, META_WA_APP_SECRET=
```

Passed to the container via `docker-compose.yml`. After editing `.env`:
`cd /opt/shop-management && docker compose up -d backend`

## Tokens — IMPORTANT

- Tokens from the app dashboard "API Setup" page are **temporary** (hours). Never use in production.
- The production token is a **System User token** (Business Settings → Users → System users →
  `nammaooru-api` → Generate token → app NammaOoru API → expiry **Never** →
  scopes `whatsapp_business_messaging` + `whatsapp_business_management`). Verify with
  `GET /debug_token` → `expires_at: 0`.
- If the token ever leaks: System users → Revoke tokens → generate a new one → update `.env`.

## Template `bill_receipt`

Body: `Hi {{1}}, thank you for shopping at {{2}}. Your bill {{3}} for Rs. {{4}} is attached as a PDF.`
Variables are filled per order: customer name, **shop name (dynamic per shop)**, order number, amount.
Header: DOCUMENT (the PDF). Footer: "Thank you for shopping with us!"

Created via API (needs a sample-file upload handle for the DOCUMENT header). Check status:
Business Suite → WhatsApp Manager → Message templates, or
`GET /v21.0/2567084310475176/message_templates?name=bill_receipt`.

## Current limitations (test phase)

1. Sender is Meta's **test number** → can only deliver to up to 5 registered recipient numbers
   (registered: 6374217724, 8144002155). Real customers CANNOT receive yet.
2. Template messages require the template status **APPROVED** (was still In review on 2026-08-02).

## Go-live checklist (to send to real customers)

1. Verify a real business number on the WABA (the number must NOT be active in any WhatsApp app —
   delete the app account first or use a fresh SIM). This yields a new **Phone Number ID**.
2. Update `META_WA_PHONE_NUMBER_ID` in `.env`, restart backend.
3. Add a payment method: WhatsApp Manager → Payment configurations (India).
   Pricing (approx): utility template ~₹0.12/message; 1,000 free service conversations/month.
4. Recreate/confirm `bill_receipt` template exists on the WABA (it is per-WABA; same WABA → nothing to do).
5. Security hardening (optional but recommended):
   - App dashboard → Settings → Advanced → **Server IP allow list**: `65.21.4.236`
   - Set `META_WA_APP_SECRET` in `.env` (app secret from App settings → Basic), redeploy —
     backend then sends `appsecret_proof` with every call
   - Only after the above works, enable **"Require app secret proof"** in app Advanced settings

## Troubleshooting

- **"Template name does not exist in en" (132001)** → template not approved yet, or wrong WABA
- **"Recipient phone number not in allowed list" (131030)** → test number restriction; register the
  recipient on the app's API Setup page, or go live with a real number
- **"Session has expired" (190)** → token expired (temporary token was used); swap to system-user token
- **Document not delivered but message arrives** → PDF URL not publicly reachable; check
  `https://api.nammaoorudelivary.in/uploads/bills/...` opens in a browser
- Real API error appears in backend logs: `docker compose logs backend | grep -i whatsapp`

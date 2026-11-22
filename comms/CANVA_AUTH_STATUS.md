# وضعیت اتصال Canva — ۲۲ نوامبر ۲۰۲۶
- Client ID: `AAHOGMIrddw` ✓ دریافت شد
- لینک authorize (PKCE/S256) آماده است؛ در چت به مالک داده شد.
- **باقیمانده:** (۱) مالک لینک را باز کند و Allow بزند، (۲) `code` برگشتی را بدهد، (۳) **Client Secret** را بدهد.
- Redirect باید در Developer Portal دقیقاً `http://localhost:8765/callback` ثبت شده باشد.
- بعد از دریافت code+secret، مدیر توکن می‌گیرد و ۷ منوی G5 را با `craft_v1_2k` تولید و کامیت می‌کند.
- نکتهٔ امنیتی: code_verifier فقط در حافظهٔ نشست مدیر است؛ در مخزن نوشته نمی‌شود.

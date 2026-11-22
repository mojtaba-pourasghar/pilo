# اتصال به Canva برای تولید G5 — برنامهٔ اجرایی (۲۲ نوامبر ۲۰۲۶)

## یافتهٔ فنی
Canva از اکتبر ۲۰۲۶ **API تولید تصویر** دارد (Connect API، مدل اختصاصی **Canva Craft / craft_v1_2k**، تا ۲K، هر نسبت ابعادی از جمله landscape 16:9):
- `POST https://api.canva.com/rest/v1/image-generations` با body: `{prompt, model:"craft_v1_2k", aspect_ratio:"landscape", idempotency_key:<uuid>, asset_upload:{type:"upload"}}`
- سپس `GET /rest/v1/image-generations/{jobId}` تا `status=success` (حدود ۵۰–۶۰ ثانیه) ← دانلود URL (۲۴ ساعت اعتبار) یا ذخیره در Uploads حساب.
- **احراز هویت: فقط OAuth 2.0.** توکن شخصی ساده وجود ندارد. دو راه:
  1. **اپ Private در Developer Portal** (روی حساب خود مالک): client_id + client_secret ← جریان PKCE ← یک‌بار authorize در مرورگر ← access_token با scope `asset:write` (+ `asset:read`). از اعتبار AI خود حساب استفاده می‌کند.
  2. اپ Service (نیاز به خرید کردیت تیمی دارد — توصیه نمی‌شود).

## چیزی که از مالک لازم است (یک‌بار، ~۵ دقیقه)
1. ورود به https://www.canva.dev/ → Your apps → Create app → نوع **Private**
2. Scopes: `asset:read asset:write design:meta:read`
3. Redirect URL: `http://localhost:8765/callback` (یا هر آدرس ساده)
4. کپی **Client ID** و **Client Secret** و دادن به مدیر پروژه
5. مدیر لینک authorize می‌سازد؛ مالک یک‌بار کلیک و Allow می‌زند؛ کدِ برگشتی را می‌دهد ← مدیر توکن می‌گیرد و ۷ منو را با Craft تولید و در مخزن کامیت می‌کند.

## جایگزین بدون ثبت اپ
مالک در همان چت قبلی Claude (که اتصال Canva MCP دارد) این فایل را بدهد: `comms/ART_REQUESTS_G5_CANVA.md` — پرامپت‌ها آماده‌اند؛ خروجی‌ها را دانلود و به این چت بدهد تا برش/ثبت شود.

## پرامپت‌ها
هفت پرامپت آماده در `comms/ART_REQUESTS_G5_CANVA.md` (سبک ذخیره‌شده + توصیف هر صفحه). هنگام تولید، `sheet_ui_kit_v1.png` و `screen_pause_settings_v1.png` به‌عنوان مرجع سبک آپلود شوند.

# طرح صفحه‌های رابط (تأییدشده — ۱۶ نوامبر ۲۰۲۶)
> هر صفحه یک تصویر طرح دارد. ساخت در Godot **عین همین طرح** (قانون CLAUDE.md). متن‌ها در تصویر نیست؛ از `strings_fa.json`.

| صفحه | فایل طرح | وضعیت |
|---|---|---|
| کیت رابط (دکمه، نوار، قاب) | `assets/art/p9_ui/sheet_ui_kit_v1.png` + برش‌ها `p9_ui_*.png` | ✅ تأیید |
| (صفحه‌های بعدی با ساخته‌شدن اضافه می‌شوند) | | |

## صفحه‌ها (فایل کامل در `assets/art/p9_ui/`) — ✅ تأییدشده، آمادهٔ ساخت
| صفحه | فایل طرح | یادداشت پیاده‌سازی |
|---|---|---|
| منوی اصلی | `sheet_screen_main_menu_v1.png` | ۳ دکمهٔ آبی شش‌ضلعی سمت راست (متن از strings_fa)؛ لوگو بالا-وسط جای خالی؛ پس‌زمینه `ParallaxBackground` یا تصویر ثابت |
| نقشهٔ مراحل فصل ۱ | `sheet_screen_level_map_v1.png` | ۱۲ گره (طلایی=تمام، آبی=جاری، قفل=بسته)، غار خرس = نگهبان؛ نوار بالا: سکه/الماس/جان؛ بازگشت سبز چپ، تنظیمات بنفش راست |
| HUD حین بازی | `sheet_screen_hud_v1.png` | جان+شارژ لنز بالا-چپ، ۲ کلید (آبی گذشته/نارنجی حال) بالا-وسط، سکه+مکث بالا-راست، جوی‌استیک پایین-چپ، ۳ دکمهٔ عمل (تیر/جهش/لنز) پایین-راست، ۳ اسلات ابزار؛ **برای Godot لایهٔ HUD جدا از صحنه** |
| کارگاه/انتخاب | `sheet_screen_loadout_v1.png` | ۳ تب بالا؛ پرتره قهرمان چپ؛ شبکهٔ ۴×۳ اسلات؛ کارت همراه راست با ۳ اسلات تجهیز؛ ستارهٔ سطح؛ دکمه‌های ارتقا (طلایی) و تأیید (آبی) |

> عنصرهای تعاملی با قطعه‌های `p9_ui_*.png` ساخته شوند، نه برش از این تصاویر صفحه (آن‌ها فقط **طرح مرجع** هستند).

## G5 — منوهای جفت ۱ (۲۲ نوامبر ۲۰۲۶ — draft، منتظر تأیید مالک)
| صفحه | فایل طرح |
|---|---|
| نقشهٔ ۶ گرهٔ دوتایی | `assets/art/pair1_sheets/g5_map_dual_nodes_v1.png` |
| HUD + جوی‌استیک شناور | `assets/art/pair1_sheets/g5_hud_joystick_v1.png` |
| ساعت بزرگ + پنل اثر | `assets/art/pair1_sheets/g5_great_clock_v1.png` |
| نتیجه (پولاروید) | `assets/art/pair1_sheets/g5_result_polaroid_v1.png` |
| کارت Auraling | `assets/art/pair1_sheets/g5_auraling_card_v1.png` |
| نام قهرمان | `assets/art/pair1_sheets/g5_name_entry_v1.png` |
| انرژی/قلب | `assets/art/pair1_sheets/g5_heart_lock_v1.png` |

مشخصات کامل: `docs/design_sheets/G5_PAIR1_MENUS.md`.

## G5 v2 — رد شد (۲۲ نوامبر ۲۰۲۶)
> مالک: «نه خوب نشد، پاکش کن.» هر ۷ فایل g5v2 حذف شدند. طراحی بعدی باید از **Canva** با سبک ذخیره‌شده خوانده و ساخته شود (گردش `02_style_prompt.md`). این نشست ابزار Canva ندارد؛ درخواست در comms/ART_REQUESTS.md ثبت شد.

## G5 v3 — طرح نهایی با سبک هنر اصلی (۲۲ نوامبر ۲۰۲۶ — تأیید مالک ✅)
> مالک هر ۷ تصویر را با ابزار خارجی و پرامپت‌های دقیق مدیر پروژه تولید کرد. سبک = عین `p9_ui` موجود در مخزن.
> این نسخه **نهایی** است و Qwen Code باید عین همین طرح‌ها را پیاده کند.

| صفحه | فایل | وضعیت |
|---|---|---|
| HUD gameplay | `assets/art/pair1_sheets/g5v3_hud_v3.png` | ✅ final |
| Heart/energy popup | `assets/art/pair1_sheets/g5v3_heart_v3.png` | ✅ final |
| Name entry | `assets/art/pair1_sheets/g5v3_name_v3.png` | ✅ final |
| Result screen | `assets/art/pair1_sheets/g5v3_result_v3.png` | ✅ final |
| Great clock transition | `assets/art/pair1_sheets/g5v3_clock_v3.png` | ✅ final |
| Chapter map (6 dual nodes) | `assets/art/pair1_sheets/g5v3_map_v3.png` | ✅ final |
| Auraling card reveal | `assets/art/pair1_sheets/g5v3_card_v3.png` | ✅ final |

## G5 v3 — طرح نهایی با سبک هنر اصلی (۲۲ نوامبر ۲۰۲۶ — تأیید مالک ✅)
> مالک هر ۷ تصویر را با ابزار خارجی و پرامپت‌های دقیق مدیر پروژه تولید کرد. سبک = عین `p9_ui` موجود در مخزن.
> این نسخه **نهایی** است و Qwen Code باید عین همین طرح‌ها را پیاده کند.

| صفحه | فایل | وضعیت |
|---|---|---|
| HUD gameplay | `assets/art/pair1_sheets/g5v3_hud_v3.png` | ✅ final |
| Heart/energy popup | `assets/art/pair1_sheets/g5v3_heart_v3.png` | ✅ final |
| Name entry | `assets/art/pair1_sheets/g5v3_name_v3.png` | ✅ final |
| Result screen | `assets/art/pair1_sheets/g5v3_result_v3.png` | ✅ final |
| Great clock transition | `assets/art/pair1_sheets/g5v3_clock_v3.png` | ✅ final |
| Chapter map (6 dual nodes) | `assets/art/pair1_sheets/g5v3_map_v3.png` | ✅ final |
| Auraling card reveal | `assets/art/pair1_sheets/g5v3_card_v3.png` | ✅ final |
| Market hub v3 (6 tabs, bundles) | `assets/art/v3/v3_ui_market_hub.png` | ✅ built (`scenes/menus/market.tscn`) |
| Market: tool upgrade kit | `assets/art/v3/v3_ui_tools_upgrade.png` | ✅ built (tab 1) |
| Market: companions + evolution | `assets/art/v3/v3_ui_companions_shop.png` | ✅ built |
| Market: coins / video / daily gift | `assets/art/v3/v3_ui_coins_shop.png` | ✅ built (hearts tab) |
| Market: heroes | `assets/art/v3/v3_ui_heroes_shop.png` | ⏸ Q17 (heroes not in the story) |

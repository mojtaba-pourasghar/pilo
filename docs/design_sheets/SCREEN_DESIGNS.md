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

## G5 v2 — بازطراحی با سبک هنر اصلی (۲۲ نوامبر ۲۰۲۶ — draft، منتظر تأیید مالک)
> حکم مالک: «هنر اصلی اینه؛ با این سبک باید طراحی بشه.» مرجع سبک = `assets/art/p9_ui/sheet_ui_kit_v1.png`، `screen_pause_settings_v1.png`، `screen_hub_v2.png`، `sheet_screen_main_menu_v1.png`، `screen_dialogue_v1.png`.
> نسخه‌های v1 قبلی **منسوخ** شدند. این v2ها با FLUX و توصیف دقیق همان سبک ساخته شد.

| صفحه | فایل v2 |
|---|---|
| نقشهٔ ۶ گرهٔ دوتایی | `assets/art/pair1_sheets/g5v2_map_v2.png` |
| HUD + جوی‌استیک | `assets/art/pair1_sheets/g5v2_hud_v2.png` |
| ساعت بزرگ + پنل اثر | `assets/art/pair1_sheets/g5v2_clock_v2.png` |
| نتیجه (پولاروید) | `assets/art/pair1_sheets/g5v2_result_v2.png` |
| کارت Auraling | `assets/art/pair1_sheets/g5v2_card_v2.png` |
| نام قهرمان | `assets/art/pair1_sheets/g5v2_name_v2.png` |
| انرژی/قلب | `assets/art/pair1_sheets/g5v2_heart_v2.png` |

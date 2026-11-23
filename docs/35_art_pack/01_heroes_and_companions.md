# ۰۱ — قهرمان‌ها و همراهان (طراحی + سناریوی تکمیلی)

> پیشوند سبک و پسوند صورتی: `00_README_rules_index.md` §۱ — **هر پرامپت زیر = [پیشوند سبک] + متن + [پسوند صورتی]**.
> «برگه» یک تصویر است. شناسه = نام فایل.

## ۱. قهرمان‌ها — فهرست و شناسه‌ها
| شناسه | قهرمان | دنیا | عنصر | ابزار اصلی | همراه خانگی (§۳) |
|---|---|---|---|---|---|
| H01 | **آرسام** (۱۲) | جدید | نور | کمان زمان | Tikkit |
| H02 | **پدربزرگ جوان** (≈۲۰) | قدیم | زمین/رویش | عصای ریشه + فلاخن + فانوس | Ancient Tanurik (از جفت ۲؛ در جفت ۱ فقط تخم را حمل می‌کند) |
| H03 | Nerissa | جدید | آب | نیزه و حباب | Blubbit |
| H04 | Sirocca | جدید | باد | شلاق روبان | Loomling |
| H05 | Glacia | جدید | یخ | تیغهٔ یخی | Glimmerk |
| H06 | Nimbus | جدید | باد | پرتاب غبار | Loomling |
| H07 | Orlo | جدید | گیاه | تله و چاقو | Burrowl |
| H08 | Echo | جدید | صدا | شاخ/موج صدا | Burrowl |
| H09 | Cogsy | جدید | آتش | آچار و فنر | Tanurik |
| H10 | Umbral | جدید | سایه | شمشیر سایه | Glimmerk |
| H11 | Ember | جدید | آتش | چکش | Tanurik |
| H12 | Stella | جدید | نور | ستاره‌پران | Glimmerk |
| H13 | Inverse | جدید (آخرین) | سایه/زمان | تغییر جاذبه | Tikkit |

> **برگه‌های هر قهرمان:** `H<nn>A` مدل‌شیت (چرخش + چهره‌ها + ژست‌ها) · `H<nn>P` اجزای برش (فقط H03–H13؛ برای H01/H02 داریم) · `H<nn>F` فرم Fuse (Auraform) · `H<nn>T` ابزارها (فایل ۰۳).
> **تکلیف نام (D2):** نام‌های انگلیسی ستون ۲ پیشنهاد من‌اند و جای «ماهک، گل‌نار، سیمین، غبارک، آرش، نوا، ساعتک، شاه‌سایه، آذر، ستاره، زروان» می‌آیند. تغییر نام = فقط یک خط در `strings_fa.json`.

---

## ۲. قهرمان‌ها — شخصیت، سناریوی تکمیلی و پرامپت

### H01 — آرسام «تیرانداز زمان» (P0)
- **داریم:** اجزای برش، مو، دست‌های کمان. **کم داریم:** چهره‌ها، ژست‌های کلیدی (مرجع ریگ)، Fuse.
- **سناریوی تکمیلی (کمبود فعلی):** آرسام از ترسش جوک می‌گوید؛ اولین بار که تیر می‌زند چشم‌هایش را می‌بندد و تیر به هدف می‌خورد (کات‌سین جزئی در آموزش تیر: «بسته‌چشم، درست‌زدن»). در جدید ۱ هنگام دیدن درخت پدربزرگ آرام می‌شود (چهرهٔ «غرق‌شده در خاطره»). اگر `none`: ابرویش کج، می‌گوید «همان دشت… ولی خسته».
- **H01A (P0)** — مدل‌شیت. چیدمان: سطر ۱: چهرهٔ ۸ حالت (عادی، مصمم، متعجب، شاد، نگران، ترسیده، خندهٔ شیطنت، غرق‌خاطره) + ۴ شکل دهان (بسته/نیم‌باز/باز/گرد) + چشم بسته؛ سطر ۲: تمام‌قد روبه‌رو، نیم‌رخ، پشت؛ سطر ۳: ۸ ژست کلیدی (دویدن، پرش اوج، فرود، دیوارپرش، سُر، شلیک ۳ زاویه، آسیب، پیروزی).
```
Character model sheet of Arsam, a 12-year-old boy time-archer: round-oval head, straight dark eyebrows, big warm-brown eyes, calm smile, messy dark hair with one stubborn cowlick, turquoise tunic, small leather quiver, golden scarf. Row 1: 8 head expressions (neutral, determined, surprised, happy, worried, scared, mischievous laugh, dreamy) plus 4 mouth shapes and closed eyes. Row 2: full body front, side, back. Row 3: 8 key action poses (run, jump apex, landing squash, wall-slide, ground slide, aiming bow at 3 angles, hurt recoil, victory). Same face as the approved Arsam parts sheet.
```
- **H01F (P0)** — Fuse آرسام+Tikkit (معرفی کوچک در K1، ۴ث): آرسام با **بال‌های شن‌نور** و شالی که به ریبون زمان بدل شده؛ تیرها طلایی. سه نما: ورود (ایستاده با هاله)، دویدن، شلیک؛ + نمای Tikkit درون بدنش (نقش مهر روی سینه).
```
Fusion form "Auraform" of Arsam merged with a tiny time spirit: translucent golden sand-light wings made of ribbon sand, scarf turned into flowing hourglass-sand ribbon, faint clock-ring halo, arrows glowing gold, small egg-shaped spirit emblem glowing on his chest. Three poses: arrival with halo, running, shooting bow. Keep Arsam's face and tunic.
```

### H02 — پدربزرگ جوان «باغبان زمان» (P0)
- **داریم:** اجزا. **کم:** چهره، ژست‌ها (حمل تخم، کاشت، فلاخن، عصا-پرش، فانوس).
- **سناریوی تکمیلی:** او **دفترچه‌نویس** است؛ هنگام استراحت (idle طولانی ۱۲ث) چیزی در دفترچه می‌کشد (نقشهٔ دشت). وقتی آرسام در جدید از دفترچه می‌خواند، همین صفحه‌ها دیده می‌شود (پیوند دو دنیا). اول مرحله از خواب بیدار می‌شود (A0)؛ کش‌وقوس، شالش را می‌بندد.
- **H02A (P0):** چهره ۵ حالت (عادی، مصمم، متعجب، شاد، نگران) + خواب‌آلو + دهان ۴ شکل؛ تمام‌قد ۳ نما؛ ۸ ژست: **حمل تخم (دو دست)، گذاشتن تخم، کاشت با عصا، پرش بلند با عصا، چرخش فلاخن، فانوس بالا، خم‌شدن (پایین)، آسیب**.
```
Character model sheet of the young grandfather (about 20 years old), "time gardener": tidy dark hair, navy scarf, leather backpack, walking staff with a root-shaped tip, small slingshot, brass lantern. Row 1: 5 head expressions (neutral, determined, surprised, happy, worried) plus sleepy face and 4 mouth shapes. Row 2: full body front, side, back. Row 3: 8 poses (carrying a glowing egg with both hands, placing the egg in a nest, planting a seed with the staff, pole-vault jump with staff, spinning slingshot, raising lantern, crouching, hurt recoil). Warmer golden palette, light-blue rim light.
```
- **H02F (P1):** Fuse کهن با Ancient Tanurik: پدربزرگ با **زره سفالی-خاکی و نقش کاشی**، عصا شعله‌دار. (همان قالب H01F با رنگ خاک و مس.)

### H03 Nerissa (آب، فصل ۲) — P2
- **شخصیت:** دختر ساحل، ۱۳ ساله، شنایی ماهر، شوخ و پرانرژی؛ در فصل ۲ آرسام را از گرداب می‌رهاند. **سناریوی تکمیلی:** او همیشه «صدف گوش» دارد و آن را به گوش آرسام می‌گذارد (صدای آیندهٔ ساحل)؛ اولین دیدار: در حباب بزرگ از آب بیرون می‌پرد.
- **ظاهر:** موی فیروزه‌ای بلند بافته با مروارید، لباس تکه‌تکه ماهی‌پوست با نقش موج ایرانی، دست‌بند صدف، پای برهنه با باله‌های کوچک روی ساق (در شنا باز می‌شوند).
- **ژست‌های ویژه:** شنا (دو حالت)، شیرجه، نیزه-ضربه، حباب-پرتاب، ایستادن روی موج.
### H04 Sirocca (باد، فصل ۳) — P2
- **شخصیت:** دختر بیابان، ۱۴ ساله، آرام و تیز؛ دلش به مادربزرگ کاکتوس‌ها خوش است. **سناریوی تکمیلی:** او نقش ساعت وارونه روی دیوار هرم را از کودکی خواب می‌بیند.
- **ظاهر:** روسری بلند طلایی-نارنجی که **شلاق روبانی** هم هست، لباس سبک با نقش کاشی، عینک شن روی پیشانی، کفش شن‌سوار.
- **ژست‌ها:** سُر روی شن (تخته‌مانند)، شلاق دورانی، چرخش، تعادل روی پرتگاه.
### H05 Glacia (یخ، فصل ۴) — P2
- **شخصیت:** دختر کوهستان، ۱۳ ساله، محتاط و وفادار؛ بهمن آرسام را به غار انداخت و او نجاتش داد. **سناریوی تکمیلی:** قلبش از یخ نیست؛ هر بار می‌خندد برف‌دانه‌ها آب می‌شوند (جلوهٔ شادی).
- **ظاهر:** کلاه پشمی با گوش، شنل سفید-آبی با نقش بلور، تیغهٔ یخی روی بازو، اسکیت-چکمه.
- **ژست‌ها:** دَش یخی، سُر، تیغه ضربه، سپر یخ.
### H06 Nimbus (باد/غبار، فصل ۵) — P2
- **شخصیت:** پسر جزیره‌های آسمانی، ۱۲ ساله، بازیگوش؛ **اعتراف:** در برج را او باز گذاشته (شاه‌سایه دزد نیست). **سناریوی تکمیلی:** اعتراف در قالب کات‌سین کوتاه با پرتره‌ای غمگین؛ سپس می‌پیوندد تا جبران کند.
- **ظاهر:** پیراهن ابری پف‌دار، کیسه غبار، عینک خلبان، چتر کوچک پشتش، پروازک.
- **ژست‌ها:** پرواز سبک، پرتاب غبار، چتر فرود، اعتراف (سر پایین).
### H07 Orlo (گیاه، فصل ۶) — P2
- **شخصیت:** بازرگان جوان بازار قدیم، ۱۵ ساله، زرنگ و دقیق؛ دفتر حساب پدر را می‌جوید. **سناریوی تکمیلی:** هر سکه را با دندان امتحان می‌کند (اشارهٔ شوخی)؛ در پایان فصل ۶ دفتر را می‌دهد و می‌گوید «حساب‌ها برابر شد».
- **ظاهر:** کلاه حصیری، کمربند ابزار با تله‌های کوچک، چاقوی کوچک (فقط برای بریدن طناب/تله؛ بی‌خشونت)، لباس سبز-قهوه‌ای با گل.
- **ژست‌ها:** دیوارپرش، گذاشتن تله، بریدن طناب.
### H08 Echo (صدا، فصل ۷) — P2
- **شخصیت:** دختر غارهای بلور، ۱۴ ساله، ساکت و شنوا؛ در تاریکی می‌بیند. **سناریوی تکمیلی:** صدا «رنگ» دارد؛ او امواج را به شکل نور می‌بیند (نشانهٔ گرافیکی: حلقه‌های رنگی دور گوش‌ها).
- **ظاهر:** موی بنفش-فیروزه‌ای با بلورک، گوشی از صدف بلور، شاخ/ساز کوچک (کارنای نقره)، شنل بلور.
- **ژست‌ها:** نواختن، حرکت آهسته در تاریکی، گوش دادن (دست پشت گوش).
### H09 Cogsy (آتش/مکانیک، فصل ۹) — P2
- **شخصیت:** مکانیک کوچک کارخانه، ۱۱ ساله، پرحرف و دلسوز؛ چرخ‌دنده‌ها را «حس می‌کند». **سناریوی تکمیلی:** پدربزرگش را «بابابزرگِ طلسم‌شده» می‌شناسد؛ هنگام دیدنش چشم‌هایش پر می‌شود.
- **ظاهر:** عینک جوشکاری روی کلاه، پیش‌بند مسی، آچار بزرگ، دستکش، پشتی فنری.
- **ژست‌ها:** آچار-ضربه، فنر-جهش، غلتیدن، تعمیر (کنار چرخ).
### H10 Umbral (سایه، فصل ۱۱) — P2
- **شخصیت:** «شاه‌سایه»، نگهبان شب، ۱۶ ظاهری؛ نجات‌یافتهٔ فصل ۱۱ و سپس همراه. **سناریوی تکمیلی:** او دو بار نقاب سایه را برمی‌دارد؛ زیر آن چهره‌ای خسته و مهربان است (چهرهٔ کلیدی!).
- **ظاهر:** شنل بنفش تیره با آستر نقره، نقاب سایه (جدا شونده)، شمشیر باریک «سایه» (بی‌خون؛ تیغه از دود فشرده)، چشم‌های نقره‌ای.
- **ژست‌ها:** تلپورت (محو و ظهور)، شمشیر-برش، با نقاب/بی‌نقاب.
### H11 Ember (آتش، فصل ۱۲) — P2
- **شخصیت:** آهنگر کارگاه، ۱۵ ساله، تنومند و آرام؛ «کلید درست» را می‌سازد. **سناریوی تکمیلی:** هر چکش خوردن ریتم موسیقی است؛ بازیکن در کارگاه با ریتم او ضربه می‌زند (مینی‌بازی).
- **ظاهر:** پیش‌بند چرمی با نقش شعله، چکش بزرگ، دستبند مسی، موی نارنجی-قرمز، لکهٔ دوده روی گونه.
- **ژست‌ها:** چکش سنگین، ضربهٔ زمین، آهن را آب‌دادن.
### H12 Stella (نور/ستاره، فصل ۱۳) — P2
- **شخصیت:** ناخدای ستاره‌ای، ۱۴ ساله، رؤیاپرداز و راه‌بلد. **سناریوی تکمیلی:** او ستاره‌ها را به اسم می‌شناسد و برایشان لالایی می‌خواند (جلوه: ستاره‌ها بیدار می‌شوند).
- **ظاهر:** شنل شب با ستاره‌های ریز، کلاه ناخدا، ستاره‌پران (ستاره‌های پرتابی چرخان)، چکمهٔ شناور.
- **ژست‌ها:** شناوری، پرتاب ستاره، نشانه‌روی با اسطرلاب.
### H13 Inverse (سایه/زمان، پایان) — P2
- **شخصیت:** «زروان» پس از آزادی (فصل ۱۵، فقط پایان کامل)؛ جوان‌ترین نسخه، ۱۵ ظاهری؛ **بازیکن‌پذیر در دو زمان هم‌زمان.** **سناریوی تکمیلی:** نیمی از لباسش گذشته و نیمی آینده است (چپ/راست متفاوت)؛ ساعتی در سینه که معکوس می‌چرخد.
- **ظاهر:** لباس دورنگ (چپ کاغذی-طلایی، راست شب-فیروزه‌ای)، یک چشم عنبری و یک چشم نقره‌ای، هالهٔ عقربه‌ای.
- **ژست‌ها:** وارونه ایستادن، تغییر جاذبه، دو نسخه (رویا و واقعیت).

### پرامپت قالب برای H03–H13 (جای `{…}` را از بخش بالا پر کنید)
- **H<nn>A:** `Character model sheet of {name}, {age}, {look keywords}. Row 1: 8 head expressions + 4 mouth shapes. Row 2: full body front, side, back. Row 3: 8 key poses {poses}.`
- **H<nn>P (اجزای برش؛ P2):** `Cut-out rig parts of {name} laid out separated: head front, hair in 2 separate pieces, torso, pelvis, upper arms, forearms, 3 hand grips (open, holding tool, fist), upper legs, lower legs, 2 feet, plus separate {cloak/scarf/ribbon/tail pieces} and {tool} in hand. Side-on, A-pose, left-right pieces mirrored identical.`
- **H<nn>F (Fuse):** `Fusion form "Auraform" of {name} merged with {home companion}: {element} aura, outfit recolored, weapon glowing, three poses (arrival, run, attack).`

---

## ۳. همراهان — فهرست نو (D1) — هر خانواده یک «کار» یکتا
> **چرا نو؟** همراهان قبلی (روباه، خرس، پرنده، سمندر…) آشنا و هم‌نقش بودند و «نقش» یکتا نداشتند. این شش **ساخته‌شدهٔ نیاز گیم‌پلی** و بر نقش‌های ایرانی (آینه‌کاری، تنور، قالی، صدف…) بنا شده‌اند. هر خانواده ۳ مرحلهٔ بدنی دارد + «شکل کهن» برای دورهٔ قدیم. **حرکت‌ها و ارتقا: فایل ۰۳ §۲.**

| # | خانواده | کار یکتا در مرحله | شکل کلی | مراحل ۱←۲←۳ | شکل کهن (قدیم) |
|---|---|---|---|---|---|
| C1 | **Tikkit** (زمان) | کند کردن، ایست، بازگشت، بالابر | روح تخم‌مانند شفاف، ساعت شنی در شکم، ۶ پر عقربه | Tikkit ← Chronix ← Chronarch | تخم / Eggling (خاکی-کرم، بدون عقربه) |
| C2 | **Glimmerk** (نور/آینه) | آشکار کردن، بازتاب پرتو و تیر، کور کردن | پروانه-فرشته از **کاشی‌های آینه‌کاری** با دو شاخک مهره‌ای | Glimmerk ← Mirrowing ← Solarch | Dimmerk (آینه‌های مات و ترک‌خورده) |
| C3 | **Burrowl** (زمین/حفر) | حفر دیوار نرم، سپر سنگی، لرزاندن | جغد-خلد گرد با **منقار مته‌ای**، بال‌های بیل‌مانند، چراغ پیشانی | Burrowl ← Quarrowl ← Titanowl | Mossowl (خزه‌پوش، چراغ شمعی) |
| C4 | **Loomling** (نخ/قالی) | تار کشیدن (گیره/تیرولی)، پل-قالی، پرواز با قالی | **قالی‌پیچِ زنده** با دم ریشه‌ای و دو چشم مهره‌ای؛ باز می‌شود و سکو می‌شود | Loomling ← Rugwyrm ← Tapestrix | Threadling (نخ ساده، بی‌نقش) |
| C5 | **Blubbit** (آب/حباب) | حباب شناور، موج، شفا، شنا | **نهنگ‌ابری کوچک** آبی با مروارید پیشانی، دم صدفی | Blubbit ← Tidewhelm ← Oceanarch | Puddlit (قطره‌ای ساده) |
| C6 | **Tanurik** (آتش/گرما) | روشنایی، ذوب، پرتاب فوری، حلقه آتش | **سوسک تنوری** سفالی با دودکش برنجی و شکم گداخته | Tanurik ← Kilnox ← Ashenforge | Ancient Tanurik (سفال ساده، آتش کم‌نور) |

**رنگ عنصر:** زمان طلایی-کرم · نور سفید-زرین · زمین قهوه‌ای-زرد خاکی · نخ قرمز-لاجوردی (قالی) · آب فیروزه‌ای · آتش نارنجی-قرمز. (هیچ‌کدام صورتی نیست.)

### سناریوی تکمیلی همراهان (مکان و لحظهٔ ملاقات)
| همراه | ملاقات | تفریخ/رونمایی | حس |
|---|---|---|---|
| Tikkit | جدید ۱: تخم در شاخه می‌شکند | کات‌سین ۲٫۳ث | «تیک!» |
| Tanurik (کهن) | **قدیم ۲** (دره): در یک تنور خراب پیدا می‌شود؛ پدربزرگ با فانوس آن را روشن می‌کند | روشن شدن شکم | شوخ و غرغرو |
| Burrowl | جدید ۲: از دیوار خاکی بیرون می‌افتد (آموزش حفر) | با بیرون‌پریدن | کنجکاو، خجالتی |
| Loomling | جدید ۳: در رشته‌های پل کنده گره خورده؛ آرسام نخ را باز می‌کند | با باز شدن قالی | بازیگوش |
| Blubbit | جدید ۳ (آبشار): از حوض پشت آبشار | با شکستن حباب | مهربان، پرحرف |
| Glimmerk | جدید ۴: در پرستشگاه آینه | با شکستن غبار آینه | موقر، خوددوست |

### برگه‌های هر خانواده
**C1 Tikkit** — A و B داریم.
- **C1E (P0) — تخم و تفریخ (کات‌سین):** ۵ مرحلهٔ تخم: سالم، ترک اول، ترک‌های درخشان، نیم‌شکسته با نور، **ظاهر شدن Tikkit** (شروع). + ۶ ذرهٔ پوسته. + نمای تخم در دود (ترک‌خورده/تیره) برای واریانت `none`.
```
Sequence sheet of a magical egg hatching, 5 stages left to right: intact pearly egg with faint golden clock marks; first thin crack; glowing cracks with golden light leaking; half-shattered shell with strong light; tiny egg-shaped time spirit with six clock-hand feathers emerging. Plus a row of 6 separate eggshell fragments and one alternate "smoke-damaged" dark cracked egg. No pink.
```
- **C1A (P1) — Eggling (شکل کهن):** خاکی-کرم، ۳ حالت (ایستاده، شاد، لرزان).

**C2 Glimmerk / C3 Burrowl / C4 Loomling / C5 Blubbit / C6 Tanurik** — برای هرکدام ۲ برگه (P1، به ترتیب شناسه‌های C2A,C2B … C6A,C6B):
- **<C>A — فرم‌ها:** ۴ ردیف: مرحلهٔ ۱، ۲، ۳، **شکل کهن**؛ هر ردیف ۳ نما (روبه‌رو، نیم‌رخ، حالت ویژه). اندازه نسبی: ۵۶ / ۹۰ / ۱۴۰ px.
- **<C>B — حالت‌ها:** ۸ خانه برای مرحلهٔ ۱ (ایستاده، حرکت، شادی، آسیب، خواب، **ظاهر شدن/Summon**، **اشاره به فرمان**، **Fuse-pose**) + ۴ خانه برای مرحلهٔ ۲ (ایستاده، حرکت، حمله، شادی).

پرامپت‌ها (بخش «توضیح موجود»):
- **C2A:** `Evolution sheet of Glimmerk: a small butterfly-sprite whose wings and body are faceted mirror tiles in Persian aynakari mosaic (white-gold, pale blue and silver shards), two antennae ending in glowing beads, huge round amber eyes. Row 1 stage 1 small cute; row 2 stage 2 "Mirrowing" larger, wings like stained-mirror domes, prism halo; row 3 stage 3 "Solarch" majestic, sun-disc crown of mirror tiles, four wings, sunburst; row 4 "Dimmerk" ancient form: dull cracked mirrors, dusty, softer. Each row front, side, special pose.`
- **C3A:** `Evolution sheet of Burrowl: a round owl-mole creature, clay-brown and sand with tile-pattern markings, drill-shaped spiral beak/snout, shovel-like wing-arms with claws, tiny miner's lamp bead on forehead, sleepy-curious eyes. Stage 2 "Quarrowl" bigger with rock armor plates and two lamp beads; stage 3 "Titanowl" huge, crystal-geode shoulders, dome-shell back with arabesque. Ancient "Mossowl": moss-covered, candle lamp.`
- **C4A:** `Evolution sheet of Loomling: a living rolled Persian carpet creature with a fringed tail, two bead eyes peeking from the roll, tiny stub feet, deep red and indigo geometric pattern. Stage 2 "Rugwyrm": longer serpentine carpet dragon unrolling in waves with gold thread. Stage 3 "Tapestrix": large flying tapestry-dragon with arabesque wings of woven gold. Ancient "Threadling": plain beige rolled cloth with loose threads. Show also each fully unrolled as a flat platform.`
- **C5A:** `Evolution sheet of Blubbit: a tiny cloud-whale pup made of translucent turquoise water with a glowing pearl on its forehead, shell-like tail fin, big shiny blue eyes, bubbles around. Stage 2 "Tidewhelm": larger whale with swirling water ribbon patterns and conch shell crest. Stage 3 "Oceanarch": majestic sea-whale dragon with coral-and-shell crown and flowing water wings. Ancient "Puddlit": a simple muddy water droplet with two eyes.`
- **C6A:** `Evolution sheet of Tanurik: a beetle-like creature shaped like a Persian clay tandoor oven, terracotta body with tile patterns, small brass chimney on top puffing sparks, glowing molten belly window, stubby legs, round friendly eyes. Stage 2 "Kilnox": larger forge-beetle with two chimneys and brass armor plates. Stage 3 "Ashenforge": big furnace-dragon beetle with crown of flames and arabesque brass plating. Ancient: plain unglazed clay, dim ember.`
- **<C>B (قالب):** `State sheet of {Name} stage 1 (and 4 poses of stage 2): idle, move (walk/fly), happy, hurt, sleeping, summon pop-in with sparkles, pointing/commanding pose, fuse pose merging into a hero. Show each pose in a separate cell.`

**C-GEAR (P1) — جلوهٔ سطح ارتقا (۱ تا ۵) برای هر همراه:** ۶ ردیف (هر خانواده) × ۵ ستون: هر ستون یک **جزء اضافهٔ کوچک** که با سطح به همراه اضافه می‌شود (یقه، تاج، نقش مهر، حلقهٔ هاله، ردپای افکت)؛ سطح ۵ باشکوه‌ترین. روی بدن مرحلهٔ ۱ نمایش داده شود.
```
Upgrade-level accessory sheet: 6 rows (time spirit with clock hands, mirror-tile moth, owl-mole, rolled-carpet creature, cloud-whale pup, tandoor beetle) by 5 columns showing the same creature with progressively richer small accessories: level 1 plain, level 2 small collar, level 3 crest and glowing seal, level 4 halo ring and trailing sparkles, level 5 full ornate crown with arabesque aura. Same pose each cell. No pink.
```

---

## ۴. ارتباط قهرمان × همراه (نیرو فرق می‌کند)
قاعدهٔ طراحی: **حرکت همراه ثابت** است؛ **عنصر و ابزار قهرمان آن را تغییر می‌دهد** (رنگ، اثر، ضربه). جدول کامل در فایل ۰۳ §۳؛ هنر لازم: `H<nn>F` + «جلوهٔ ترکیب» در برگه‌های حرکت.

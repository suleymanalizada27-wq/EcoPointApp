/// فارسی (Persian). Right-to-left.
const Map<String, String> stringsFa = {
  // Common
  'app_name': 'EcoPoint',
  'ok': 'باشه',
  'cancel': 'لغو',
  'close': 'بستن',
  'retry': 'تلاش دوباره',
  'save': 'ذخیره',
  'continue': 'ادامه',
  'next': 'بعدی',
  'skip': 'رد کردن',
  'done': 'انجام شد',
  'back': 'بازگشت',
  'loading': 'در حال بارگذاری…',
  'copy': 'کپی',
  'copied': 'کپی شد',
  'share': 'اشتراک‌گذاری',
  'search': 'جستجو',
  'confirm': 'تأیید',
  'delete': 'حذف',
  'edit': 'ویرایش',
  'see_all': 'مشاهده همه',
  'today': 'امروز',
  'yesterday': 'دیروز',
  'ep_unit': 'EP',
  'estimate_tag': 'تخمین',
  'error_generic': 'مشکلی پیش آمد. لطفاً دوباره تلاش کنید.',
  'error_network': 'اتصالی وجود ندارد. اینترنت خود را بررسی کنید و دوباره تلاش کنید.',
  'error_backend_unavailable':
      'دسترسی به سرور امن EcoPoint ممکن نیست. این عملیات به آن نیاز دارد.',
  'offline_banner': 'آفلاین هستید — داده‌های ذخیره‌شده نمایش داده می‌شود',
  'empty_title': 'هنوز چیزی اینجا نیست',

  // Navigation
  'nav_home': 'خانه',
  'nav_rewards': 'جوایز',
  'nav_scan': 'اسکن',
  'nav_bins': 'سطل‌ها',
  'nav_profile': 'پروفایل',

  // Setup
  'setup_required_title': 'راه‌اندازی Firebase لازم است',
  'setup_required_body':
      'این نسخه هنوز اطلاعات Firebase ندارد. برای پروژه ecopoint-b3d60 دستور `flutterfire configure` را اجرا کنید و دوباره بسازید. بخش README ← Firebase setup را ببینید.',

  // Onboarding
  'onb_1_title': 'بازیافت کن. اسکن کن. امتیاز بگیر.',
  'onb_1_body':
      'زباله را در سطل هوشمند EcoPoint بیندازید، کد QR آن را اسکن کنید و برای هر مشارکت امتیاز EP جمع کنید.',
  'onb_2_title': 'امتیازها را خرج جوایز واقعی کن',
  'onb_2_body':
      'EP را با جوایز شرکای تجاری، کوپن‌ها و محصولات سازگار با محیط زیست مبادله کنید — یا برای دوستانتان بفرستید.',
  'onb_3_title': 'تأثیر خود را ببین',
  'onb_3_body':
      'فعالیت بازیافت خود را دنبال کنید، رشته روزانه‌تان را حفظ کنید و نزدیک‌ترین سطل هوشمند را روی نقشه پیدا کنید.',
  'onb_get_started': 'شروع کنید',
  'onb_have_account': 'من قبلاً حساب دارم',

  // Auth
  'auth_welcome_back': 'خوش آمدید',
  'auth_welcome_back_sub': 'برای ادامه کسب EP وارد شوید.',
  'auth_create_account': 'حساب خود را بسازید',
  'auth_create_account_sub': 'به EcoPoint بپیوندید و با بازیافت جایزه بگیرید.',
  'auth_email': 'ایمیل',
  'auth_password': 'رمز عبور',
  'auth_confirm_password': 'تکرار رمز عبور',
  'auth_full_name': 'نام و نام خانوادگی',
  'auth_forgot_password': 'رمز عبور را فراموش کرده‌اید؟',
  'auth_forgot_title': 'بازنشانی رمز عبور',
  'auth_forgot_sub':
      'ایمیل خود را وارد کنید تا پیوند بازنشانی برایتان ارسال کنیم.',
  'auth_send_reset': 'ارسال پیوند بازنشانی',
  'auth_reset_sent': 'پیوند ارسال شد. صندوق ورودی خود را بررسی کنید.',
  'auth_sign_in': 'ورود',
  'auth_sign_up': 'ساخت حساب',
  'auth_google': 'ادامه با Google',
  'auth_or': 'یا',
  'auth_no_account': 'حساب ندارید؟',
  'auth_have_account': 'قبلاً حساب ساخته‌اید؟',
  'auth_err_email': 'یک ایمیل معتبر وارد کنید',
  'auth_err_password_short': 'حداقل ۸ نویسه استفاده کنید',
  'auth_err_password_match': 'رمزهای عبور یکسان نیستند',
  'auth_err_name': 'نام خود را وارد کنید',
  'auth_err_invalid_credential': 'ایمیل یا رمز عبور نادرست است',
  'auth_err_user_not_found': 'حسابی با این ایمیل پیدا نشد',
  'auth_err_email_in_use': 'این ایمیل قبلاً ثبت شده است',
  'auth_err_weak_password': 'این رمز عبور بسیار ضعیف است',
  'auth_err_too_many': 'تعداد تلاش‌ها بیش از حد است. بعداً دوباره امتحان کنید',
  'auth_err_network': 'خطای شبکه. اتصال خود را بررسی کنید',
  'auth_err_disabled': 'این حساب غیرفعال شده است',
  'auth_err_google_unavailable':
      'ورود با Google در این نسخه پیکربندی نشده است',
  'auth_err_recent_login': 'لطفاً دوباره وارد شوید و سپس تلاش کنید',
  'setup_title': 'پروفایل خود را تکمیل کنید',
  'setup_sub': 'بگویید چطور شما را صدا بزنیم. بعداً می‌توانید تغییرش دهید.',
  'setup_bio_hint': 'یک معرفی کوتاه (اختیاری)',

  // Home
  'greet_morning': 'صبح بخیر',
  'greet_afternoon': 'عصر بخیر',
  'greet_evening': 'شب بخیر',
  'home_balance': 'موجودی EcoPoint',
  'home_scan_cta': 'اسکن QR سطل',
  'home_send': 'ارسال EP',
  'home_week': '۷ روز گذشته',
  'home_earned': 'کسب‌شده',
  'home_spent': 'خرج‌شده',
  'home_sent': 'ارسال‌شده',
  'home_scans': 'اسکن‌ها',
  'home_impact': 'تأثیر شما',
  'home_impact_note': 'تخمین‌هایی بر اساس اسکن‌های ثبت‌شده شما — نه مقادیر اندازه‌گیری‌شده.',
  'home_challenges': 'مأموریت‌های روزانه',
  'home_streak': 'رشته',
  'home_streak_days': '{n} روز',
  'home_streak_checkin': 'امروز حضور بزنید',
  'home_streak_done': 'امروز حضور زدید',
  'home_leaderboard': 'جدول برترین‌ها',
  'home_featured': 'جوایز ویژه',
  'home_nearby': 'سطل‌های هوشمند',
  'home_no_bins': 'هنوز هیچ سطل هوشمندی ثبت نشده است.',
  'home_no_activity': 'در ۷ روز گذشته فعالیتی نبوده است.',
  'home_level_progress': '{cur} / {next} EP',
  'home_level_max': 'به بالاترین سطح رسیده‌اید',
  'impact_plastic': 'پلاستیک بازیافت‌شده',
  'impact_co2': 'CO₂ جلوگیری‌شده',
  'impact_water': 'آب صرفه‌جویی‌شده',
  'impact_energy': 'انرژی صرفه‌جویی‌شده',
  'unit_g': 'گرم',
  'unit_l': 'لیتر',
  'unit_wh': 'Wh',

  // Scanner
  'scan_title': 'اسکن QR',
  'scan_hint': 'دوربین را روی کد QR سطل هوشمند بگیرید',
  'scan_hint_friend': 'یا QR یک دوست در EcoPoint را برای ارسال EP اسکن کنید',
  'scan_perm_title': 'دسترسی به دوربین لازم است',
  'scan_perm_body':
      'EcoPoint فقط برای خواندن کدهای QR روی سطل‌های هوشمند و پروفایل دوستان از دوربین استفاده می‌کند. چیزی ضبط یا بارگذاری نمی‌شود.',
  'scan_perm_grant': 'اجازه دسترسی به دوربین',
  'scan_perm_settings': 'باز کردن تنظیمات',
  'scan_perm_denied':
      'مجوز دوربین خاموش است. برای اسکن، آن را در تنظیمات سیستم فعال کنید.',
  'scan_processing': 'در حال بررسی کد…',
  'scan_invalid': 'این یک کد QR از EcoPoint نیست.',
  'scan_expired': 'این کد QR منقضی شده است. کد فعلی سطل را اسکن کنید.',
  'scan_duplicate': 'این کد QR قبلاً استفاده شده است.',
  'scan_rate_limited': 'خیلی سریع اسکن می‌کنید. لطفاً کمی صبر کنید.',
  'scan_daily_limit': 'به سقف امتیاز EP امروز رسیده‌اید.',
  'scan_success_title': 'EP کسب شد!',
  'scan_success_body': 'به موجودی شما اضافه شد',
  'scan_pro_bonus': 'Pro ×{n}',
  'scan_friend_title': 'QR یک دوست شناسایی شد',
  'scan_friend_body': 'به این کاربر EP ارسال شود؟',
  'scan_torch': 'چراغ قوه',
  'scan_again': 'اسکن بعدی',
  'scan_unsupported_camera': 'دوربین روی این دستگاه روشن نشد.',

  // Rewards / marketplace
  'market_title': 'جوایز',
  'market_sub': 'EP خود را خرج جوایز واقعی کنید',
  'market_search': 'جستجوی جوایز',
  'cat_all': 'همه',
  'cat_food': 'خوراکی',
  'cat_tech': 'فناوری',
  'cat_eco': 'محیط زیست',
  'cat_service': 'خدمات',
  'market_empty': 'جایزه‌ای مطابق جستجوی شما پیدا نشد.',
  'market_catalog_local':
      'کاتالوگ داخلی نمایش داده می‌شود. کاتالوگ سرور پیدا نشد.',
  'reward_buy': 'دریافت جایزه',
  'reward_partner': 'شریک',
  'reward_available': 'موجود',
  'reward_out_of_stock': 'ناموجود',
  'reward_confirm_title': 'این جایزه دریافت شود؟',
  'reward_confirm_body': '{price} EP از موجودی شما کسر خواهد شد.',
  'reward_insufficient': 'EP کافی نیست',
  'reward_need_more': '{n} EP دیگر لازم دارید',
  'reward_success_title': 'جایزه دریافت شد',
  'reward_success_body': '{name} اکنون در تاریخچه خرید شما است.',
  'reward_history': 'تاریخچه خرید',
  'reward_history_empty': 'هنوز جایزه‌ای دریافت نکرده‌اید.',
  'reward_balance_after': 'موجودی پس از عملیات',
  'coupon_title': 'کوپن شریک',
  'coupon_sub': 'EP را به کوپن فروشگاه تبدیل کنید. کارمزد: {fee}٪.',
  'coupon_amount': 'EP برای تبدیل',
  'coupon_preview': '{ep} EP ← {azn} AZN (کارمزد {fee} EP)',
  'coupon_min': 'حداقل {n} EP',
  'coupon_create': 'ساخت کوپن',
  'coupon_ready': 'کوپن آماده است',
  'coupon_show': 'این کد را به صندوق‌دار نشان دهید',
  'transport_title': 'درخواست شارژ BakıKart',
  'transport_sub':
      'EP همین حالا رزرو می‌شود؛ شارژ توسط شریک حمل‌ونقل ما تکمیل می‌شود.',
  'transport_card': 'شماره کارت (۱۶ رقم)',
  'transport_amount': 'EP برای تبدیل',
  'transport_fee_note': 'کارمزد ثابت ۲٪ اعمال می‌شود.',
  'transport_submit': 'درخواست شارژ',
  'transport_pending': 'درخواست دریافت شد — وضعیت: در انتظار شریک',
  'transport_err_card': 'شماره کارت ۱۶ رقمی را وارد کنید',

  // Transfer & history
  'transfer_title': 'ارسال EP',
  'transfer_recipient': 'گیرنده',
  'transfer_search': 'با نام جستجو کنید یا شناسه کاربر را بچسبانید',
  'transfer_amount': 'مقدار',
  'transfer_available': 'موجود: {n} EP',
  'transfer_send': 'بررسی انتقال',
  'transfer_confirm_title': 'تأیید انتقال',
  'transfer_confirm_body': '{n} EP برای {name} ارسال شود؟ این کار قابل بازگشت نیست.',
  'transfer_success': '{n} EP برای {name} ارسال شد',
  'transfer_err_amount': 'مقدار معتبری وارد کنید',
  'transfer_err_balance': 'موجودی کافی نیست',
  'transfer_err_self': 'نمی‌توانید برای خودتان EP ارسال کنید',
  'transfer_err_max': 'حداکثر {n} EP در هر انتقال',
  'transfer_err_recipient': 'ابتدا یک گیرنده انتخاب کنید',
  'transfer_no_results': 'کاربری پیدا نشد',
  'transfer_scan_friend': 'اسکن QR',
  'qr_my_title': 'کد QR من',
  'qr_my_hint': 'از دوستتان بخواهید این کد را اسکن کند تا برایتان EP بفرستد.',
  'qr_my_copy_id': 'کپی شناسه کاربری من',
  'history_title': 'تراکنش‌ها',
  'history_empty': 'هنوز تراکنشی نیست.',
  'tx_earn': 'کسب‌شده',
  'tx_sent': 'ارسال‌شده',
  'tx_received': 'دریافت‌شده',
  'tx_purchase': 'خرید',
  'tx_weight': 'پاداش وزن',
  'tx_bonus': 'پاداش',
  'tx_other': 'تراکنش',
  'tx_filter_all': 'همه',
  'tx_status_completed': 'تکمیل‌شده',
  'tx_status_pending': 'در انتظار',
  'tx_status_failed': 'ناموفق',

  // Bins & map
  'bins_title': 'سطل‌های هوشمند',
  'bins_sub': 'وضعیت زنده سطل‌های EcoPoint',
  'bins_list': 'همه سطل‌ها',
  'bins_empty': 'هنوز هیچ سطل هوشمندی ثبت نشده است.',
  'bins_map_tab': 'نقشه',
  'bins_list_tab': 'فهرست',
  'bins_no_coords':
      '{n} سطل هنوز مختصات ندارند و فقط در فهرست دیده می‌شوند.',
  'bins_location_off': 'مکان‌یابی خاموش است. نقشه بدون فاصله نمایش داده می‌شود.',
  'bins_enable_location': 'فعال‌سازی مکان‌یابی',
  'bins_distance': '{d} فاصله',
  'bins_fill': 'میزان پُری',
  'bins_online': 'آنلاین',
  'bins_offline': 'آفلاین',
  'bins_last_seen': 'آخرین ارتباط {t}',
  'bins_never_seen': 'هنوز سیگنالی دریافت نشده',
  'bins_temp': 'دما',
  'bins_weight': 'عدد ترازو',
  'bins_full_warning': 'این سطل تقریباً پر است',
  'bins_redeem_weight': 'دریافت امتیاز عدد ترازو',
  'bins_redeem_hint':
      'زباله را روی ترازوی این سطل بگذارید و سپس دریافت کنید. امتیاز در سرور و بر اساس عدد دستگاه محاسبه می‌شود.',
  'bins_redeemed': '{n} EP دریافت شد',
  'bins_map_attribution': '© مشارکت‌کنندگان OpenStreetMap',
  'bins_map_error': 'بارگذاری نقشه ممکن نشد.',
  'ago_sec': '{n} ثانیه پیش',
  'ago_min': '{n} دقیقه پیش',
  'ago_hour': '{n} ساعت پیش',
  'ago_day': '{n} روز پیش',

  // Statistics
  'stats_title': 'آمار',
  'stats_week': 'هفته',
  'stats_month': 'ماه',
  'stats_lifetime': 'کل',
  'stats_activity': 'فعالیت EP',
  'stats_recent': 'فعالیت اخیر',
  'stats_earned_period': 'کسب‌شده',
  'stats_spent_period': 'خرج‌شده',
  'stats_total_scans': 'مجموع اسکن‌ها',
  'stats_limit_note': 'نمودارها از آخرین {n} تراکنش شما استفاده می‌کنند.',
  'stats_impact_title': 'تأثیر زیست‌محیطی تخمینی',
  'stats_impact_disclaimer':
      'این ارقام تخمینی هستند و از تعداد اسکن‌های شما با ضرایب میانگین ثابت به‌دست آمده‌اند. سطل‌ها آن‌ها را اندازه‌گیری نمی‌کنند.',
  'stats_level': 'سطح',

  // Challenges & achievements
  'ch_title': 'مأموریت‌ها',
  'ch_daily': 'مأموریت‌های روزانه',
  'ch_claim': 'دریافت',
  'ch_claimed': 'دریافت شد',
  'ch_claim_success': '+{n} EP دریافت شد',
  'ch_progress': '{a} / {b}',
  'ch_scan3_t': 'امروز ۳ سطل اسکن کن',
  'ch_scan3_s': 'مأموریت اسکن روزانه',
  'ch_scan5_t': '۵ اقدام سبز امروز',
  'ch_scan5_s': 'به بازیافت ادامه بده',
  'ch_streak2_t': 'رشته ۲ روزه',
  'ch_streak2_s': 'دو روز پشت سر هم حضور بزن',
  'ach_title': 'دستاوردها',
  'ach_unlocked': 'باز شده',
  'ach_locked': 'قفل',
  'ach_first_scan_t': 'اولین اسکن',
  'ach_first_scan_d': 'اولین اسکن خود را انجام دهید',
  'ach_scan10_t': '۱۰ اسکن',
  'ach_scan10_d': '۱۰ سطل را اسکن کنید',
  'ach_scan50_t': '۵۰ اسکن',
  'ach_scan50_d': '۵۰ سطل را اسکن کنید',
  'ach_earned500_t': 'کسب ۵۰۰ EP',
  'ach_earned500_d': 'در مجموع ۵۰۰ EP کسب کنید',
  'ach_earned5000_t': 'کسب ۵٬۰۰۰ EP',
  'ach_earned5000_d': 'در مجموع ۵٬۰۰۰ EP کسب کنید',
  'ach_sent1_t': 'اولین انتقال',
  'ach_sent1_d': 'برای یک دوست EP بفرستید',
  'ach_streak7_t': 'رشته ۷ روزه',
  'ach_streak7_d': '۷ روز پشت سر هم حضور بزنید',
  'lvl_0': 'مبتدی',
  'lvl_1': 'دوستدار محیط زیست',
  'lvl_2': 'جنگجوی سبز',
  'lvl_3': 'قهرمان محیط زیست',
  'lvl_4': 'نگهبان سیاره',
  'lvl_5': 'استاد EcoPoint',
  'streak_title': 'رشته روزانه',
  'streak_bonus_note': 'پاداش +{n} EP هر ۷ روز',
  'streak_checkin_success': 'رشته: {n} روز',
  'streak_bonus_success': 'پاداش رشته: +{n} EP',

  // Leaderboard
  'lb_title': 'جدول برترین‌ها',
  'lb_empty': 'هنوز کاربر رتبه‌بندی‌شده‌ای نیست.',
  'lb_you': 'شما',

  // Profile & settings
  'profile_title': 'پروفایل',
  'profile_edit': 'ویرایش پروفایل',
  'profile_name': 'نام نمایشی',
  'profile_bio': 'معرفی',
  'profile_bio_empty': 'یک معرفی کوتاه اضافه کنید',
  'profile_avatar': 'انتخاب آواتار',
  'profile_saved': 'پروفایل به‌روزرسانی شد',
  'profile_user_id': 'شناسه کاربری',
  'settings_title': 'تنظیمات',
  'settings_language': 'زبان',
  'lang_no_results': 'زبانی پیدا نشد',
  'settings_theme': 'ظاهر',
  'theme_system': 'سیستم',
  'theme_light': 'روشن',
  'theme_dark': 'تیره',
  'settings_notifications': 'اعلان‌ها',
  'settings_privacy': 'حریم خصوصی',
  'settings_about': 'درباره EcoPoint',
  'settings_version': 'نسخه {v}',
  'settings_referral': 'دعوت از دوستان',
  'settings_my_qr': 'کد QR من',
  'settings_history': 'تراکنش‌ها',
  'settings_purchases': 'تاریخچه خرید',
  'settings_achievements': 'دستاوردها',
  'settings_stats': 'آمار',
  'notif_title': 'اعلان‌ها',
  'notif_empty': 'همه‌چیز را دیده‌اید.',
  'notif_prefs_title': 'تنظیمات اعلان‌ها',
  'notif_pref_activity': 'فعالیت و جوایز',
  'notif_pref_news': 'اخبار EcoPoint',
  'notif_prefs_note':
      'تنظیمات در حساب شما ذخیره می‌شود. ارسال اعلان فوری به سرور اختیاری FCM نیاز دارد (README را ببینید).',
  'privacy_body':
      'EcoPoint نام، ایمیل، عکس پروفایل، موجودی EP و تاریخچه تراکنش‌های شما را در Firebase نگه می‌دارد. دوربین و مکان فقط روی دستگاه شما برای خواندن کدهای QR و مرتب‌سازی سطل‌ها بر اساس فاصله استفاده می‌شوند و هرگز بارگذاری نمی‌شوند. هر زمان که بخواهید می‌توانید حساب و داده‌های خود را حذف کنید.',
  'about_body':
      'EcoPoint از Green Line Group بازیافت روزمره را به جایزه تبدیل می‌کند. اسکن کنید، امتیاز بگیرید، جایزه دریافت کنید و تأثیر بگذارید.',
  'about_open_site': 'باز کردن وب‌سایت',
  'referral_title': 'دعوت از یک دوست',
  'referral_sub': 'کد خود را به اشتراک بگذارید. وقتی دوستتان بپیوندد، هر دو EP می‌گیرید.',
  'referral_your_code': 'کد شما',
  'referral_have_code': 'کد دوستتان را دارید؟',
  'referral_enter': 'وارد کردن کد',
  'referral_apply': 'اعمال کد',
  'referral_applied': 'کد اعمال شد: +{n} EP',
  'referral_share_text':
      'به من در EcoPoint بپیوندید و با بازیافت جایزه بگیرید! هنگام ثبت‌نام از کد من {code} استفاده کنید. {link}',
  'danger_zone': 'منطقه خطر',
  'sign_out': 'خروج',
  'sign_out_confirm': 'از EcoPoint خارج می‌شوید؟',
  'delete_account': 'حذف حساب',
  'delete_confirm_title': 'حساب شما حذف شود؟',
  'delete_confirm_body':
      'پروفایل، موجودی و تاریخچه شما برای همیشه حذف خواهد شد. این کار قابل بازگشت نیست.',
  'delete_done': 'حساب شما حذف شد.',
  'pro_title': 'EcoPoint Pro',
  'pro_active': 'Pro فعال است',
  'pro_active_until': 'فعال تا {d}',
  'pro_info':
      'اعضای Pro در اسکن‌ها ضریب امتیاز می‌گیرند. اشتراک هنوز در برنامه در دسترس نیست.',
  'settings_guide':
      'راهنمای سبز',
  'settings_admin':
      'پنل مدیریت',
  'guide_title':
      'راهنمای سبز',
  'guide_intro':
      'زباله‌ای که درست تفکیک شده باشد بسیار راحت‌تر بازیافت می‌شود. قوانین محلی ممکن است متفاوت باشد — برچسب‌های روی سطل را هم بخوانید.',
  'guide_plastic_t':
      'پلاستیک',
  'guide_plastic_b':
      'بطری‌ها را خالی کنید، له کنید و درشان را ببندید. ظرف‌های چرب یا بسیار کثیف بازیافت را سخت می‌کنند.',
  'guide_glass_t':
      'شیشه',
  'guide_glass_b':
      'شیشه‌ها و بطری‌ها را خالی و آبکشی کنید. آینه، شیشه پنجره و سرامیک را با ظروف شیشه‌ای معمولی مخلوط نکنید.',
  'guide_paper_t':
      'کاغذ و مقوا',
  'guide_paper_b':
      'آن را خشک نگه دارید. کاغذ خیس یا چرب و دستمال کاغذی مصرف‌شده برای بازیافت مناسب نیستند.',
  'guide_metal_t':
      'فلز',
  'guide_metal_b':
      'قوطی‌های حلبی و نوشیدنی را خالی کنید. آلومینیوم را می‌توان بارها و بارها بازیافت کرد.',
  'guide_battery_t':
      'باتری و لوازم الکترونیکی',
  'guide_battery_b':
      'هرگز آن‌ها را با زباله عمومی دور نریزید — حاوی مواد خطرناک هستند. به یک مرکز جمع‌آوری مخصوص تحویل دهید.',
  'guide_tips_t':
      'نکته‌های سریع',
  'guide_tip_1':
      'اول مصرف را کم کنید، بعد دوباره استفاده کنید، و در آخر بازیافت کنید.',
  'guide_tip_2':
      'یک کیف پارچه‌ای و بطری شخصی از صدها وسیله یک‌بارمصرف در سال جلوگیری می‌کند.',
  'guide_tip_3':
      'اگر مطمئن نیستید، راهنمای روی سطل را بخوانید — یک مورد اشتباه می‌تواند کل محموله را خراب کند.',
  'lb_weekly':
      'این هفته',
  'lb_all_time':
      'کل دوران',
  'lb_weekly_empty':
      'این هفته هنوز کسی EP کسب نکرده است. اولین نفر باشید!',
  'lb_weekly_note':
      'هفته هر دوشنبه (به وقت باکو) از نو شروع می‌شود.',
  'ch_monthly':
      'اهداف ماهانه',
  'ch_m30_t':
      '۳۰ اسکن در این ماه',
  'ch_m30_s':
      'هدف اسکن ماهانه',
  'ch_m60_t':
      '۶۰ اسکن در این ماه',
  'ch_m60_s':
      'هدف بزرگ ماهانه',
  'ch_weekly_prize':
      'هر دوشنبه سه نفر برتر هفته گذشته EP پاداش می‌گیرند (۲۰۰ / ۱۰۰ / ۵۰).',
  'home_invite_title':
      'دعوت از یک دوست',
  'home_invite_body':
      'کد و پیوند خود را به اشتراک بگذارید؛ هر دو EP پاداش می‌گیرید.',
  'notif_primer_title':
      'یادآورها فعال شوند؟',
  'notif_primer_body':
      'برای حفظ رشته روزانه‌تان به شما یادآوری می‌کنیم و از نتایج هفتگی و جوایز جدید باخبرتان می‌کنیم. هر زمان خواستید می‌توانید آن را در تنظیمات خاموش کنید.',
  'notif_primer_yes':
      'بله، فعال کن',
  'notif_primer_later':
      'حالا نه',
  'bins_nearest_title':
      'نزدیک‌ترین سطل دارای جا',
  'bins_directions':
      'مسیریابی',
  'bins_open_failed':
      'برنامه نقشه باز نشد',
  'share_card_title':
      'نتایج من در EcoPoint',
  'share_card_month':
      'اسکن در این ماه',
  'share_card_total':
      'مجموع اسکن‌ها',
  'share_card_earned':
      'EP کسب‌شده',
  'share_card_streak':
      'روز پیاپی',
  'share_card_code':
      'کد من هنگام ثبت‌نام',
  'share_card_tagline':
      'EcoPoint · بازیافت کن، EP بگیر',
  'share_card_text_plain':
      'من با EcoPoint بازیافت می‌کنم و EP می‌گیرم!',
  'notif_pref_offers':
      'نکته‌ها و یادآورهای شخصی',
  'notif_pref_offers_sub':
      'EP باقی‌مانده تا جایزه، یادآوری بازگشت',
};

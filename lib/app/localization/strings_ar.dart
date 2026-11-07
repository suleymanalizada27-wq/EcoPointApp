/// العربية (Arabic). Right-to-left.
const Map<String, String> stringsAr = {
  // Common
  'app_name': 'EcoPoint',
  'ok': 'حسنًا',
  'cancel': 'إلغاء',
  'close': 'إغلاق',
  'retry': 'حاول مرة أخرى',
  'save': 'حفظ',
  'continue': 'متابعة',
  'next': 'التالي',
  'skip': 'تخطي',
  'done': 'تم',
  'back': 'رجوع',
  'loading': 'جارٍ التحميل…',
  'copy': 'نسخ',
  'copied': 'تم النسخ',
  'share': 'مشاركة',
  'search': 'بحث',
  'confirm': 'تأكيد',
  'delete': 'حذف',
  'edit': 'تعديل',
  'see_all': 'عرض الكل',
  'today': 'اليوم',
  'yesterday': 'أمس',
  'ep_unit': 'EP',
  'estimate_tag': 'تقدير',
  'error_generic': 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
  'error_network': 'لا يوجد اتصال. تحقق من الإنترنت وحاول مرة أخرى.',
  'error_backend_unavailable':
      'تعذّر الوصول إلى خادم EcoPoint الآمن. هذا الإجراء يحتاج إليه.',
  'offline_banner': 'أنت غير متصل — يتم عرض البيانات المحفوظة',
  'empty_title': 'لا يوجد شيء هنا بعد',

  // Navigation
  'nav_home': 'الرئيسية',
  'nav_rewards': 'المكافآت',
  'nav_scan': 'مسح',
  'nav_bins': 'الحاويات',
  'nav_profile': 'الملف الشخصي',

  // Setup
  'setup_required_title': 'إعداد Firebase مطلوب',
  'setup_required_body':
      'لا تحتوي هذه النسخة على بيانات Firebase بعد. شغّل `flutterfire configure` للمشروع ecopoint-b3d60 ثم أعد البناء. راجع README ← Firebase setup.',

  // Onboarding
  'onb_1_title': 'أعد التدوير. امسح. اكسب.',
  'onb_1_body':
      'ضع النفايات في حاوية EcoPoint الذكية، وامسح رمز QR الخاص بها، واجمع نقاط EP مقابل كل مساهمة.',
  'onb_2_title': 'أنفق نقاطك على مكافآت حقيقية',
  'onb_2_body':
      'استبدل نقاط EP بمكافآت الشركاء والقسائم والمنتجات الصديقة للبيئة — أو أرسلها إلى أصدقائك.',
  'onb_3_title': 'اطّلع على أثرك',
  'onb_3_body':
      'تابع نشاطك في إعادة التدوير، حافظ على سلسلتك اليومية، واعثر على أقرب حاوية ذكية على الخريطة.',
  'onb_get_started': 'ابدأ الآن',
  'onb_have_account': 'لدي حساب بالفعل',

  // Auth
  'auth_welcome_back': 'مرحبًا بعودتك',
  'auth_welcome_back_sub': 'سجّل الدخول لمواصلة كسب EP.',
  'auth_create_account': 'أنشئ حسابك',
  'auth_create_account_sub': 'انضم إلى EcoPoint وابدأ إعادة التدوير مقابل المكافآت.',
  'auth_email': 'البريد الإلكتروني',
  'auth_password': 'كلمة المرور',
  'auth_confirm_password': 'تأكيد كلمة المرور',
  'auth_full_name': 'الاسم الكامل',
  'auth_forgot_password': 'نسيت كلمة المرور؟',
  'auth_forgot_title': 'إعادة تعيين كلمة المرور',
  'auth_forgot_sub':
      'أدخل بريدك الإلكتروني وسنرسل إليك رابطًا لإعادة التعيين.',
  'auth_send_reset': 'إرسال رابط إعادة التعيين',
  'auth_reset_sent': 'تم إرسال الرابط. تحقق من بريدك الوارد.',
  'auth_sign_in': 'تسجيل الدخول',
  'auth_sign_up': 'إنشاء حساب',
  'auth_google': 'المتابعة باستخدام Google',
  'auth_or': 'أو',
  'auth_no_account': 'ليس لديك حساب؟',
  'auth_have_account': 'لديك حساب بالفعل؟',
  'auth_err_email': 'أدخل عنوان بريد إلكتروني صالحًا',
  'auth_err_password_short': 'استخدم 8 أحرف على الأقل',
  'auth_err_password_match': 'كلمتا المرور غير متطابقتين',
  'auth_err_name': 'أدخل اسمك',
  'auth_err_invalid_credential': 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
  'auth_err_user_not_found': 'لا يوجد حساب لهذا البريد الإلكتروني',
  'auth_err_email_in_use': 'هذا البريد الإلكتروني مسجّل مسبقًا',
  'auth_err_weak_password': 'كلمة المرور هذه ضعيفة جدًا',
  'auth_err_too_many': 'محاولات كثيرة جدًا. حاول مرة أخرى لاحقًا',
  'auth_err_network': 'خطأ في الشبكة. تحقق من اتصالك',
  'auth_err_disabled': 'تم تعطيل هذا الحساب',
  'auth_err_google_unavailable':
      'تسجيل الدخول عبر Google غير مفعّل في هذه النسخة',
  'auth_err_recent_login': 'يرجى تسجيل الدخول مرة أخرى ثم المحاولة',
  'setup_title': 'أعدّ ملفك الشخصي',
  'setup_sub': 'أخبرنا كيف نناديك. يمكنك تغيير ذلك لاحقًا.',
  'setup_bio_hint': 'نبذة قصيرة (اختياري)',

  // Home
  'greet_morning': 'صباح الخير',
  'greet_afternoon': 'مساء الخير',
  'greet_evening': 'مساء الخير',
  'home_balance': 'رصيد EcoPoint',
  'home_scan_cta': 'امسح رمز QR للحاوية',
  'home_send': 'إرسال EP',
  'home_week': 'آخر 7 أيام',
  'home_earned': 'المكتسب',
  'home_spent': 'المصروف',
  'home_sent': 'المُرسَل',
  'home_scans': 'عمليات المسح',
  'home_impact': 'أثرك',
  'home_impact_note': 'تقديرات مبنية على عمليات المسح المسجّلة — وليست قيمًا مقاسة.',
  'home_challenges': 'المهام اليومية',
  'home_streak': 'السلسلة',
  'home_streak_days': '{n} أيام',
  'home_streak_checkin': 'سجّل حضورك اليوم',
  'home_streak_done': 'تم تسجيل الحضور اليوم',
  'home_leaderboard': 'لوحة المتصدرين',
  'home_featured': 'مكافآت مميزة',
  'home_nearby': 'الحاويات الذكية',
  'home_no_bins': 'لا توجد حاويات ذكية مسجّلة بعد.',
  'home_no_activity': 'لا يوجد نشاط خلال آخر 7 أيام.',
  'home_level_progress': '{cur} / {next} EP',
  'home_level_max': 'تم بلوغ أعلى مستوى',
  'impact_plastic': 'البلاستيك المحوَّل',
  'impact_co2': 'ثاني أكسيد الكربون المتجنَّب',
  'impact_water': 'المياه الموفَّرة',
  'impact_energy': 'الطاقة الموفَّرة',
  'unit_g': 'غ',
  'unit_l': 'ل',
  'unit_wh': 'Wh',

  // Scanner
  'scan_title': 'مسح QR',
  'scan_hint': 'وجّه الكاميرا نحو رمز QR الخاص بالحاوية الذكية',
  'scan_hint_friend': 'أو امسح رمز EcoPoint QR الخاص بصديق لإرسال EP',
  'scan_perm_title': 'مطلوب إذن الكاميرا',
  'scan_perm_body':
      'يستخدم EcoPoint الكاميرا فقط لقراءة رموز QR على الحاويات الذكية وملفات الأصدقاء. لا يتم تسجيل أي شيء أو رفعه.',
  'scan_perm_grant': 'السماح بالكاميرا',
  'scan_perm_settings': 'فتح الإعدادات',
  'scan_perm_denied':
      'إذن الكاميرا متوقف. فعّله من إعدادات النظام لتتمكن من المسح.',
  'scan_processing': 'جارٍ التحقق من الرمز…',
  'scan_invalid': 'هذا ليس رمز EcoPoint QR.',
  'scan_expired': 'انتهت صلاحية رمز QR هذا. امسح الرمز الحالي للحاوية.',
  'scan_duplicate': 'تم استخدام رمز QR هذا من قبل.',
  'scan_rate_limited': 'أنت تمسح بسرعة كبيرة. يرجى الانتظار قليلًا.',
  'scan_daily_limit': 'لقد بلغت حد EP لهذا اليوم.',
  'scan_success_title': 'تم كسب EP!',
  'scan_success_body': 'تمت الإضافة إلى رصيدك',
  'scan_pro_bonus': 'Pro ×{n}',
  'scan_friend_title': 'تم اكتشاف رمز QR لصديق',
  'scan_friend_body': 'هل تريد إرسال EP إلى هذا المستخدم؟',
  'scan_torch': 'المصباح',
  'scan_again': 'امسح رمزًا آخر',
  'scan_unsupported_camera': 'تعذّر تشغيل الكاميرا على هذا الجهاز.',

  // Rewards / marketplace
  'market_title': 'المكافآت',
  'market_sub': 'أنفق نقاط EP على مكافآت حقيقية',
  'market_search': 'ابحث في المكافآت',
  'cat_all': 'الكل',
  'cat_food': 'الطعام',
  'cat_tech': 'التقنية',
  'cat_eco': 'البيئة',
  'cat_service': 'الخدمات',
  'market_empty': 'لا توجد مكافآت تطابق بحثك.',
  'market_catalog_local':
      'يتم عرض الكتالوج المدمج. لم يتم العثور على كتالوج الخادم.',
  'reward_buy': 'استبدال',
  'reward_partner': 'الشريك',
  'reward_available': 'متوفر',
  'reward_out_of_stock': 'نفدت الكمية',
  'reward_confirm_title': 'هل تريد استبدال هذه المكافأة؟',
  'reward_confirm_body': 'سيتم خصم {price} EP من رصيدك.',
  'reward_insufficient': 'رصيد EP غير كافٍ',
  'reward_need_more': 'تحتاج إلى {n} EP إضافية',
  'reward_success_title': 'تم استبدال المكافأة',
  'reward_success_body': '{name} موجودة الآن في سجل مشترياتك.',
  'reward_history': 'سجل المشتريات',
  'reward_history_empty': 'لم تستبدل أي شيء بعد.',
  'reward_balance_after': 'الرصيد بعد العملية',
  'coupon_title': 'قسيمة الشريك',
  'coupon_sub': 'حوّل EP إلى قسيمة متجر. الرسوم: {fee}٪.',
  'coupon_amount': 'EP المراد تحويلها',
  'coupon_preview': '{ep} EP ← {azn} AZN (رسوم {fee} EP)',
  'coupon_min': 'الحد الأدنى {n} EP',
  'coupon_create': 'إنشاء القسيمة',
  'coupon_ready': 'القسيمة جاهزة',
  'coupon_show': 'اعرض هذا الرمز عند الصندوق',
  'transport_title': 'طلب شحن BakıKart',
  'transport_sub':
      'يتم حجز EP الآن؛ ويكمل شريك النقل لدينا عملية الشحن.',
  'transport_card': 'رقم البطاقة (16 رقمًا)',
  'transport_amount': 'EP المراد تحويلها',
  'transport_fee_note': 'تُطبَّق رسوم ثابتة قدرها 2٪.',
  'transport_submit': 'طلب الشحن',
  'transport_pending': 'تم استلام الطلب — الحالة: بانتظار الشريك',
  'transport_err_card': 'أدخل رقم البطاقة المكوّن من 16 رقمًا',

  // Transfer & history
  'transfer_title': 'إرسال EP',
  'transfer_recipient': 'المستلم',
  'transfer_search': 'ابحث بالاسم أو الصق معرّف المستخدم',
  'transfer_amount': 'المبلغ',
  'transfer_available': 'المتاح: {n} EP',
  'transfer_send': 'مراجعة التحويل',
  'transfer_confirm_title': 'تأكيد التحويل',
  'transfer_confirm_body': 'هل تريد إرسال {n} EP إلى {name}؟ لا يمكن التراجع عن ذلك.',
  'transfer_success': 'تم إرسال {n} EP إلى {name}',
  'transfer_err_amount': 'أدخل مبلغًا صالحًا',
  'transfer_err_balance': 'الرصيد غير كافٍ',
  'transfer_err_self': 'لا يمكنك إرسال EP إلى نفسك',
  'transfer_err_max': 'الحد الأقصى {n} EP لكل تحويل',
  'transfer_err_recipient': 'اختر المستلم أولًا',
  'transfer_no_results': 'لم يتم العثور على مستخدمين',
  'transfer_scan_friend': 'مسح QR',
  'qr_my_title': 'رمز QR الخاص بي',
  'qr_my_hint': 'دع صديقك يمسح هذا الرمز لإرسال EP إليك.',
  'qr_my_copy_id': 'نسخ معرّف المستخدم الخاص بي',
  'history_title': 'المعاملات',
  'history_empty': 'لا توجد معاملات بعد.',
  'tx_earn': 'مكتسب',
  'tx_sent': 'مُرسَل',
  'tx_received': 'مُستلَم',
  'tx_purchase': 'شراء',
  'tx_weight': 'مكافأة الوزن',
  'tx_bonus': 'مكافأة إضافية',
  'tx_other': 'معاملة',
  'tx_filter_all': 'الكل',
  'tx_status_completed': 'مكتملة',
  'tx_status_pending': 'قيد الانتظار',
  'tx_status_failed': 'فاشلة',

  // Bins & map
  'bins_title': 'الحاويات الذكية',
  'bins_sub': 'الحالة المباشرة لحاويات EcoPoint',
  'bins_list': 'جميع الحاويات',
  'bins_empty': 'لا توجد حاويات ذكية مسجّلة بعد.',
  'bins_map_tab': 'الخريطة',
  'bins_list_tab': 'القائمة',
  'bins_no_coords':
      '{n} حاويات بلا إحداثيات بعد وتظهر في القائمة فقط.',
  'bins_location_off': 'الموقع متوقف. يتم عرض الخريطة بدون المسافات.',
  'bins_enable_location': 'تفعيل الموقع',
  'bins_distance': 'على بُعد {d}',
  'bins_fill': 'مستوى الامتلاء',
  'bins_online': 'متصلة',
  'bins_offline': 'غير متصلة',
  'bins_last_seen': 'آخر ظهور {t}',
  'bins_never_seen': 'لا توجد إشارة بعد',
  'bins_temp': 'درجة الحرارة',
  'bins_weight': 'قراءة الميزان',
  'bins_full_warning': 'هذه الحاوية شبه ممتلئة',
  'bins_redeem_weight': 'استبدال قراءة الميزان',
  'bins_redeem_hint':
      'ضع النفايات على ميزان هذه الحاوية ثم اضغط استبدال. تُحسب النقاط على الخادم اعتمادًا على قراءة الجهاز.',
  'bins_redeemed': 'تم استبدال {n} EP',
  'bins_map_attribution': '© مساهمو OpenStreetMap',
  'bins_map_error': 'تعذّر تحميل الخريطة.',
  'ago_sec': 'منذ {n} ث',
  'ago_min': 'منذ {n} د',
  'ago_hour': 'منذ {n} س',
  'ago_day': 'منذ {n} ي',

  // Statistics
  'stats_title': 'الإحصاءات',
  'stats_week': 'أسبوع',
  'stats_month': 'شهر',
  'stats_lifetime': 'الإجمالي',
  'stats_activity': 'نشاط EP',
  'stats_recent': 'النشاط الأخير',
  'stats_earned_period': 'المكتسب',
  'stats_spent_period': 'المصروف',
  'stats_total_scans': 'إجمالي عمليات المسح',
  'stats_limit_note': 'تستخدم الرسوم البيانية آخر {n} معاملة لديك.',
  'stats_impact_title': 'الأثر البيئي التقديري',
  'stats_impact_disclaimer':
      'هذه الأرقام تقديرات مشتقة من عدد عمليات المسح لديك باستخدام معاملات متوسطة ثابتة. ولا تقيسها الحاويات.',
  'stats_level': 'المستوى',

  // Challenges & achievements
  'ch_title': 'المهام',
  'ch_daily': 'المهام اليومية',
  'ch_claim': 'استلام',
  'ch_claimed': 'تم الاستلام',
  'ch_claim_success': 'تم استلام +{n} EP',
  'ch_progress': '{a} / {b}',
  'ch_scan3_t': 'امسح 3 حاويات اليوم',
  'ch_scan3_s': 'مهمة المسح اليومية',
  'ch_scan5_t': '5 إجراءات بيئية اليوم',
  'ch_scan5_s': 'واصل إعادة التدوير',
  'ch_streak2_t': 'سلسلة يومين',
  'ch_streak2_s': 'سجّل حضورك يومين متتاليين',
  'ach_title': 'الإنجازات',
  'ach_unlocked': 'مفتوح',
  'ach_locked': 'مقفل',
  'ach_first_scan_t': 'أول مسح',
  'ach_first_scan_d': 'أكمل أول عملية مسح لك',
  'ach_scan10_t': '10 عمليات مسح',
  'ach_scan10_d': 'امسح 10 حاويات',
  'ach_scan50_t': '50 عملية مسح',
  'ach_scan50_d': 'امسح 50 حاوية',
  'ach_earned500_t': 'كسب 500 EP',
  'ach_earned500_d': 'اكسب 500 EP في المجموع',
  'ach_earned5000_t': 'كسب 5,000 EP',
  'ach_earned5000_d': 'اكسب 5,000 EP في المجموع',
  'ach_sent1_t': 'أول تحويل',
  'ach_sent1_d': 'أرسل EP إلى صديق',
  'ach_streak7_t': 'سلسلة 7 أيام',
  'ach_streak7_d': 'سجّل حضورك 7 أيام متتالية',
  'lvl_0': 'مبتدئ',
  'lvl_1': 'صديق البيئة',
  'lvl_2': 'المحارب الأخضر',
  'lvl_3': 'بطل البيئة',
  'lvl_4': 'حارس الكوكب',
  'lvl_5': 'سيد EcoPoint',
  'streak_title': 'السلسلة اليومية',
  'streak_bonus_note': 'مكافأة +{n} EP كل 7 أيام',
  'streak_checkin_success': 'السلسلة: {n} أيام',
  'streak_bonus_success': 'مكافأة السلسلة: +{n} EP',

  // Leaderboard
  'lb_title': 'لوحة المتصدرين',
  'lb_empty': 'لا يوجد مستخدمون مصنّفون بعد.',
  'lb_you': 'أنت',

  // Profile & settings
  'profile_title': 'الملف الشخصي',
  'profile_edit': 'تعديل الملف الشخصي',
  'profile_name': 'الاسم المعروض',
  'profile_bio': 'النبذة',
  'profile_bio_empty': 'أضف نبذة قصيرة',
  'profile_avatar': 'اختر صورة رمزية',
  'profile_saved': 'تم تحديث الملف الشخصي',
  'profile_user_id': 'معرّف المستخدم',
  'settings_title': 'الإعدادات',
  'settings_language': 'اللغة',
  'lang_no_results': 'لم يتم العثور على لغات',
  'settings_theme': 'المظهر',
  'theme_system': 'النظام',
  'theme_light': 'فاتح',
  'theme_dark': 'داكن',
  'settings_notifications': 'الإشعارات',
  'settings_privacy': 'الخصوصية',
  'settings_about': 'حول EcoPoint',
  'settings_version': 'الإصدار {v}',
  'settings_referral': 'ادعُ أصدقاءك',
  'settings_my_qr': 'رمز QR الخاص بي',
  'settings_history': 'المعاملات',
  'settings_purchases': 'سجل المشتريات',
  'settings_achievements': 'الإنجازات',
  'settings_stats': 'الإحصاءات',
  'notif_title': 'الإشعارات',
  'notif_empty': 'لا توجد إشعارات جديدة.',
  'notif_prefs_title': 'تفضيلات الإشعارات',
  'notif_pref_activity': 'النشاط والمكافآت',
  'notif_pref_news': 'أخبار EcoPoint',
  'notif_prefs_note':
      'تُحفظ التفضيلات في حسابك. يتطلب إرسال الإشعارات الفورية خادم FCM الاختياري (راجع README).',
  'privacy_body':
      'يخزّن EcoPoint اسمك وبريدك الإلكتروني وصورة ملفك الشخصي ورصيد EP وسجل معاملاتك في Firebase. تُستخدم الكاميرا والموقع على جهازك فقط لقراءة رموز QR وترتيب الحاويات حسب المسافة، ولا يتم رفعها أبدًا. يمكنك حذف حسابك وبياناتك في أي وقت.',
  'about_body':
      'تطبيق EcoPoint من Green Line Group يحوّل إعادة التدوير اليومية إلى مكافآت. امسح، واكسب، واستبدل، واصنع أثرًا.',
  'about_open_site': 'فتح الموقع',
  'referral_title': 'ادعُ صديقًا',
  'referral_sub': 'شارك رمزك. تكسبان معًا EP عند انضمام صديقك.',
  'referral_your_code': 'رمزك',
  'referral_have_code': 'لديك رمز من صديق؟',
  'referral_enter': 'أدخل الرمز',
  'referral_apply': 'تطبيق الرمز',
  'referral_applied': 'تم تطبيق الرمز: +{n} EP',
  'referral_share_text':
      'انضم إليّ في EcoPoint واكسب مكافآت مقابل إعادة التدوير! استخدم رمزي {code} عند التسجيل. {link}',
  'danger_zone': 'منطقة الخطر',
  'sign_out': 'تسجيل الخروج',
  'sign_out_confirm': 'هل تريد تسجيل الخروج من EcoPoint؟',
  'delete_account': 'حذف الحساب',
  'delete_confirm_title': 'هل تريد حذف حسابك؟',
  'delete_confirm_body':
      'سيتم حذف ملفك الشخصي ورصيدك وسجلك نهائيًا. لا يمكن التراجع عن ذلك.',
  'delete_done': 'تم حذف حسابك.',
  'pro_title': 'EcoPoint Pro',
  'pro_active': 'Pro مفعّل',
  'pro_active_until': 'مفعّل حتى {d}',
  'pro_info':
      'يحصل مشتركو Pro على مضاعِف في عمليات المسح. الاشتراكات غير متاحة في التطبيق بعد.',
  'settings_guide':
      'الدليل البيئي',
  'settings_admin':
      'لوحة الإدارة',
  'guide_title':
      'الدليل البيئي',
  'guide_intro':
      'النفايات المفروزة جيدًا أسهل بكثير في إعادة التدوير. قد تختلف القواعد المحلية — تحقق أيضًا من الملصقات على الحاوية.',
  'guide_plastic_t':
      'البلاستيك',
  'guide_plastic_b':
      'أفرغ الزجاجات واضغطها وأغلق الغطاء. الأوعية الدهنية أو شديدة الاتساخ تصعّب إعادة التدوير.',
  'guide_glass_t':
      'الزجاج',
  'guide_glass_b':
      'أفرغ البرطمانات والزجاجات واشطفها. لا تخلط المرايا وزجاج النوافذ والسيراميك مع عبوات الزجاج العادية.',
  'guide_paper_t':
      'الورق والكرتون',
  'guide_paper_b':
      'حافظ عليه جافًا. الورق المبلل أو الدهني والمناديل المستعملة غير صالحة لإعادة التدوير.',
  'guide_metal_t':
      'المعادن',
  'guide_metal_b':
      'أفرغ علب الصفيح وعلب المشروبات. يمكن إعادة تدوير الألمنيوم مرارًا وتكرارًا.',
  'guide_battery_t':
      'البطاريات والإلكترونيات',
  'guide_battery_b':
      'لا ترمِها أبدًا مع النفايات العامة — فهي تحتوي على مواد خطرة. سلّمها إلى نقطة جمع مخصصة.',
  'guide_tips_t':
      'نصائح سريعة',
  'guide_tip_1':
      'قلّل أولًا، ثم أعد الاستخدام، ثم أعد التدوير.',
  'guide_tip_2':
      'حقيبة قماشية وزجاجتك الخاصة تجنّبانك مئات المنتجات ذات الاستخدام الواحد في السنة.',
  'guide_tip_3':
      'عند الشك، اقرأ تعليمات الحاوية — فقطعة واحدة خاطئة قد تفسد دفعة كاملة.',
  'lb_weekly':
      'هذا الأسبوع',
  'lb_all_time':
      'كل الأوقات',
  'lb_weekly_empty':
      'لم يكسب أحد EP هذا الأسبوع بعد. كن الأول!',
  'lb_weekly_note':
      'يُعاد ضبط الأسبوع كل يوم اثنين (بتوقيت باكو).',
  'ch_monthly':
      'الأهداف الشهرية',
  'ch_m30_t':
      '30 عملية مسح هذا الشهر',
  'ch_m30_s':
      'هدف المسح الشهري',
  'ch_m60_t':
      '60 عملية مسح هذا الشهر',
  'ch_m60_s':
      'هدف شهري كبير',
  'ch_weekly_prize':
      'كل يوم اثنين يحصل أفضل 3 من الأسبوع الماضي على EP إضافية (200 / 100 / 50).',
  'home_invite_title':
      'ادعُ صديقًا',
  'home_invite_body':
      'شارك رمزك ورابطك، وتكسبان معًا EP إضافية.',
  'notif_primer_title':
      'هل تريد تفعيل التذكيرات؟',
  'notif_primer_body':
      'سنذكّرك بالحفاظ على سلسلتك اليومية ونخبرك بنتائج الأسبوع والمكافآت الجديدة. يمكنك إيقاف ذلك في أي وقت من الإعدادات.',
  'notif_primer_yes':
      'نعم، فعّل',
  'notif_primer_later':
      'ليس الآن',
  'bins_nearest_title':
      'أقرب حاوية بها مساحة',
  'bins_directions':
      'الاتجاهات',
  'bins_open_failed':
      'تعذّر فتح تطبيق الخرائط',
  'share_card_title':
      'نتائجي في EcoPoint',
  'share_card_month':
      'عملية مسح هذا الشهر',
  'share_card_total':
      'إجمالي عمليات المسح',
  'share_card_earned':
      'EP مكتسبة',
  'share_card_streak':
      'أيام متتالية',
  'share_card_code':
      'رمزي عند التسجيل',
  'share_card_tagline':
      'EcoPoint · أعد التدوير واكسب EP',
  'share_card_text_plain':
      'أعيد التدوير وأكسب EP مع EcoPoint!',
  'notif_pref_offers':
      'نصائح وتذكيرات شخصية',
  'notif_pref_offers_sub':
      'EP المتبقية للمكافأة، وتذكيرات العودة',
};

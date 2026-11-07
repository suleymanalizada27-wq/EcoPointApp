/// हिन्दी (Hindi).
const Map<String, String> stringsHi = {
  // Common
  'app_name': 'EcoPoint',
  'ok': 'ठीक है',
  'cancel': 'रद्द करें',
  'close': 'बंद करें',
  'retry': 'फिर से कोशिश करें',
  'save': 'सहेजें',
  'continue': 'जारी रखें',
  'next': 'आगे',
  'skip': 'छोड़ें',
  'done': 'हो गया',
  'back': 'वापस',
  'loading': 'लोड हो रहा है…',
  'copy': 'कॉपी करें',
  'copied': 'कॉपी हो गया',
  'share': 'शेयर करें',
  'search': 'खोजें',
  'confirm': 'पुष्टि करें',
  'delete': 'हटाएँ',
  'edit': 'संपादित करें',
  'see_all': 'सभी देखें',
  'today': 'आज',
  'yesterday': 'कल',
  'ep_unit': 'EP',
  'estimate_tag': 'अनुमान',
  'error_generic': 'कुछ गड़बड़ हो गई। कृपया फिर से कोशिश करें।',
  'error_network': 'कनेक्शन नहीं है। अपना इंटरनेट जाँचें और फिर से कोशिश करें।',
  'error_backend_unavailable':
      'EcoPoint का सुरक्षित सर्वर उपलब्ध नहीं है। इस कार्य के लिए उसकी ज़रूरत है।',
  'offline_banner': 'आप ऑफ़लाइन हैं — सहेजा हुआ डेटा दिखाया जा रहा है',
  'empty_title': 'यहाँ अभी कुछ नहीं है',

  // Navigation
  'nav_home': 'होम',
  'nav_rewards': 'इनाम',
  'nav_scan': 'स्कैन',
  'nav_bins': 'डिब्बे',
  'nav_profile': 'प्रोफ़ाइल',

  // Setup
  'setup_required_title': 'Firebase सेटअप ज़रूरी है',
  'setup_required_body':
      'इस बिल्ड में अभी Firebase की जानकारी नहीं है। प्रोजेक्ट ecopoint-b3d60 के लिए `flutterfire configure` चलाएँ और दोबारा बिल्ड करें। README → Firebase setup देखें।',

  // Onboarding
  'onb_1_title': 'रीसायकल करें। स्कैन करें। कमाएँ।',
  'onb_1_body':
      'कचरा EcoPoint स्मार्ट डिब्बे में डालें, उसका QR कोड स्कैन करें और हर योगदान पर EP पॉइंट जमा करें।',
  'onb_2_title': 'असली इनामों पर खर्च करें',
  'onb_2_body':
      'EP के बदले पार्टनर इनाम, कूपन और इको उत्पाद पाएँ — या दोस्तों को पॉइंट भेजें।',
  'onb_3_title': 'अपना असर देखें',
  'onb_3_body':
      'अपनी रीसायकलिंग गतिविधि ट्रैक करें, अपनी स्ट्रीक बनाए रखें और नक्शे पर सबसे नज़दीकी स्मार्ट डिब्बा खोजें।',
  'onb_get_started': 'शुरू करें',
  'onb_have_account': 'मेरा पहले से खाता है',

  // Auth
  'auth_welcome_back': 'वापसी पर स्वागत है',
  'auth_welcome_back_sub': 'EP कमाना जारी रखने के लिए साइन इन करें।',
  'auth_create_account': 'अपना खाता बनाएँ',
  'auth_create_account_sub': 'EcoPoint से जुड़ें और रीसायकल करके इनाम पाएँ।',
  'auth_email': 'ईमेल',
  'auth_password': 'पासवर्ड',
  'auth_confirm_password': 'पासवर्ड की पुष्टि करें',
  'auth_full_name': 'पूरा नाम',
  'auth_forgot_password': 'पासवर्ड भूल गए?',
  'auth_forgot_title': 'पासवर्ड रीसेट करें',
  'auth_forgot_sub':
      'अपना ईमेल दर्ज करें, हम आपको रीसेट लिंक भेजेंगे।',
  'auth_send_reset': 'रीसेट लिंक भेजें',
  'auth_reset_sent': 'रीसेट लिंक भेज दिया गया है। अपना इनबॉक्स देखें।',
  'auth_sign_in': 'साइन इन करें',
  'auth_sign_up': 'खाता बनाएँ',
  'auth_google': 'Google से जारी रखें',
  'auth_or': 'या',
  'auth_no_account': 'खाता नहीं है?',
  'auth_have_account': 'पहले से खाता है?',
  'auth_err_email': 'सही ईमेल पता दर्ज करें',
  'auth_err_password_short': 'कम से कम 8 अक्षर रखें',
  'auth_err_password_match': 'पासवर्ड मेल नहीं खाते',
  'auth_err_name': 'अपना नाम दर्ज करें',
  'auth_err_invalid_credential': 'ईमेल या पासवर्ड गलत है',
  'auth_err_user_not_found': 'इस ईमेल से कोई खाता नहीं मिला',
  'auth_err_email_in_use': 'यह ईमेल पहले से पंजीकृत है',
  'auth_err_weak_password': 'यह पासवर्ड बहुत कमज़ोर है',
  'auth_err_too_many': 'बहुत ज़्यादा कोशिशें हो गईं। बाद में फिर कोशिश करें',
  'auth_err_network': 'नेटवर्क त्रुटि। अपना कनेक्शन जाँचें',
  'auth_err_disabled': 'यह खाता निष्क्रिय कर दिया गया है',
  'auth_err_google_unavailable':
      'इस बिल्ड में Google साइन-इन कॉन्फ़िगर नहीं है',
  'auth_err_recent_login': 'कृपया दोबारा साइन इन करें, फिर कोशिश करें',
  'setup_title': 'अपनी प्रोफ़ाइल सेट करें',
  'setup_sub': 'बताइए हम आपको कैसे बुलाएँ। आप इसे बाद में बदल सकते हैं।',
  'setup_bio_hint': 'छोटा परिचय (वैकल्पिक)',

  // Home
  'greet_morning': 'सुप्रभात',
  'greet_afternoon': 'नमस्कार',
  'greet_evening': 'शुभ संध्या',
  'home_balance': 'EcoPoint बैलेंस',
  'home_scan_cta': 'डिब्बे का QR स्कैन करें',
  'home_send': 'EP भेजें',
  'home_week': 'पिछले 7 दिन',
  'home_earned': 'कमाए',
  'home_spent': 'खर्च किए',
  'home_sent': 'भेजे',
  'home_scans': 'स्कैन',
  'home_impact': 'आपका असर',
  'home_impact_note': 'आपके दर्ज किए गए स्कैन पर आधारित अनुमान — मापे हुए मान नहीं।',
  'home_challenges': 'दैनिक मिशन',
  'home_streak': 'स्ट्रीक',
  'home_streak_days': '{n} दिन',
  'home_streak_checkin': 'आज चेक-इन करें',
  'home_streak_done': 'आज चेक-इन हो गया',
  'home_leaderboard': 'लीडरबोर्ड',
  'home_featured': 'खास इनाम',
  'home_nearby': 'स्मार्ट डिब्बे',
  'home_no_bins': 'अभी कोई स्मार्ट डिब्बा पंजीकृत नहीं है।',
  'home_no_activity': 'पिछले 7 दिनों में कोई गतिविधि नहीं।',
  'home_level_progress': '{cur} / {next} EP',
  'home_level_max': 'सर्वोच्च स्तर पर पहुँच गए',
  'impact_plastic': 'प्लास्टिक का निपटान',
  'impact_co2': 'CO₂ की बचत',
  'impact_water': 'पानी की बचत',
  'impact_energy': 'ऊर्जा की बचत',
  'unit_g': 'ग्रा',
  'unit_l': 'ली',
  'unit_wh': 'Wh',

  // Scanner
  'scan_title': 'QR स्कैन करें',
  'scan_hint': 'कैमरा स्मार्ट डिब्बे के QR कोड की ओर करें',
  'scan_hint_friend': 'या EP भेजने के लिए दोस्त का EcoPoint QR स्कैन करें',
  'scan_perm_title': 'कैमरे की अनुमति चाहिए',
  'scan_perm_body':
      'EcoPoint कैमरे का उपयोग केवल स्मार्ट डिब्बों और दोस्तों की प्रोफ़ाइल के QR कोड पढ़ने के लिए करता है। कुछ भी रिकॉर्ड या अपलोड नहीं होता।',
  'scan_perm_grant': 'कैमरे की अनुमति दें',
  'scan_perm_settings': 'सेटिंग खोलें',
  'scan_perm_denied':
      'कैमरे की अनुमति बंद है। स्कैन करने के लिए इसे सिस्टम सेटिंग में चालू करें।',
  'scan_processing': 'कोड की जाँच हो रही है…',
  'scan_invalid': 'यह EcoPoint का QR कोड नहीं है।',
  'scan_expired': 'यह QR कोड समाप्त हो चुका है। डिब्बे का मौजूदा कोड स्कैन करें।',
  'scan_duplicate': 'यह QR कोड पहले ही इस्तेमाल हो चुका है।',
  'scan_rate_limited': 'आप बहुत तेज़ स्कैन कर रहे हैं। कृपया थोड़ा रुकें।',
  'scan_daily_limit': 'आप आज की EP सीमा तक पहुँच गए हैं।',
  'scan_success_title': 'EP मिल गए!',
  'scan_success_body': 'आपके बैलेंस में जुड़ गए',
  'scan_pro_bonus': 'Pro ×{n}',
  'scan_friend_title': 'दोस्त का QR मिला',
  'scan_friend_body': 'इस उपयोगकर्ता को EP भेजें?',
  'scan_torch': 'टॉर्च',
  'scan_again': 'एक और स्कैन करें',
  'scan_unsupported_camera': 'इस डिवाइस पर कैमरा शुरू नहीं हो सका।',

  // Rewards / marketplace
  'market_title': 'इनाम',
  'market_sub': 'अपने EP को असली इनामों पर खर्च करें',
  'market_search': 'इनाम खोजें',
  'cat_all': 'सभी',
  'cat_food': 'खाना',
  'cat_tech': 'टेक',
  'cat_eco': 'इको',
  'cat_service': 'सेवाएँ',
  'market_empty': 'आपकी खोज से कोई इनाम मेल नहीं खाता।',
  'market_catalog_local':
      'अंतर्निहित कैटलॉग दिखाया जा रहा है। सर्वर कैटलॉग नहीं मिला।',
  'reward_buy': 'रिडीम करें',
  'reward_partner': 'पार्टनर',
  'reward_available': 'उपलब्ध',
  'reward_out_of_stock': 'स्टॉक में नहीं',
  'reward_confirm_title': 'यह इनाम रिडीम करें?',
  'reward_confirm_body': 'आपके बैलेंस से {price} EP काटे जाएँगे।',
  'reward_insufficient': 'EP पर्याप्त नहीं हैं',
  'reward_need_more': 'आपको {n} EP और चाहिए',
  'reward_success_title': 'इनाम रिडीम हो गया',
  'reward_success_body': '{name} अब आपकी खरीद के इतिहास में है।',
  'reward_history': 'खरीद का इतिहास',
  'reward_history_empty': 'आपने अभी तक कुछ रिडीम नहीं किया है।',
  'reward_balance_after': 'इसके बाद बैलेंस',
  'coupon_title': 'पार्टनर कूपन',
  'coupon_sub': 'EP को स्टोर कूपन में बदलें। शुल्क: {fee}%।',
  'coupon_amount': 'बदलने के लिए EP',
  'coupon_preview': '{ep} EP → {azn} AZN (शुल्क {fee} EP)',
  'coupon_min': 'न्यूनतम {n} EP',
  'coupon_create': 'कूपन बनाएँ',
  'coupon_ready': 'कूपन तैयार है',
  'coupon_show': 'यह कोड कैशियर को दिखाएँ',
  'transport_title': 'BakıKart टॉप-अप अनुरोध',
  'transport_sub':
      'EP अभी रिज़र्व हो जाते हैं; टॉप-अप हमारे ट्रांसपोर्ट पार्टनर द्वारा पूरा किया जाता है।',
  'transport_card': 'कार्ड नंबर (16 अंक)',
  'transport_amount': 'बदलने के लिए EP',
  'transport_fee_note': '2% का निश्चित शुल्क लागू होता है।',
  'transport_submit': 'टॉप-अप का अनुरोध करें',
  'transport_pending': 'अनुरोध मिल गया — स्थिति: पार्टनर की प्रतीक्षा में',
  'transport_err_card': '16 अंकों का कार्ड नंबर दर्ज करें',

  // Transfer & history
  'transfer_title': 'EP भेजें',
  'transfer_recipient': 'प्राप्तकर्ता',
  'transfer_search': 'नाम से खोजें या उपयोगकर्ता ID पेस्ट करें',
  'transfer_amount': 'राशि',
  'transfer_available': 'उपलब्ध: {n} EP',
  'transfer_send': 'ट्रांसफ़र की समीक्षा करें',
  'transfer_confirm_title': 'ट्रांसफ़र की पुष्टि करें',
  'transfer_confirm_body': '{name} को {n} EP भेजें? इसे वापस नहीं किया जा सकता।',
  'transfer_success': '{name} को {n} EP भेज दिए गए',
  'transfer_err_amount': 'सही राशि दर्ज करें',
  'transfer_err_balance': 'बैलेंस पर्याप्त नहीं है',
  'transfer_err_self': 'आप खुद को EP नहीं भेज सकते',
  'transfer_err_max': 'प्रति ट्रांसफ़र अधिकतम {n} EP',
  'transfer_err_recipient': 'पहले प्राप्तकर्ता चुनें',
  'transfer_no_results': 'कोई उपयोगकर्ता नहीं मिला',
  'transfer_scan_friend': 'QR स्कैन करें',
  'qr_my_title': 'मेरा QR कोड',
  'qr_my_hint': 'दोस्त से इसे स्कैन करवाएँ ताकि वह आपको EP भेज सके।',
  'qr_my_copy_id': 'मेरी उपयोगकर्ता ID कॉपी करें',
  'history_title': 'लेन-देन',
  'history_empty': 'अभी कोई लेन-देन नहीं।',
  'tx_earn': 'कमाए',
  'tx_sent': 'भेजे',
  'tx_received': 'प्राप्त',
  'tx_purchase': 'खरीद',
  'tx_weight': 'वज़न का इनाम',
  'tx_bonus': 'बोनस',
  'tx_other': 'लेन-देन',
  'tx_filter_all': 'सभी',
  'tx_status_completed': 'पूरा हुआ',
  'tx_status_pending': 'लंबित',
  'tx_status_failed': 'विफल',

  // Bins & map
  'bins_title': 'स्मार्ट डिब्बे',
  'bins_sub': 'EcoPoint डिब्बों की लाइव स्थिति',
  'bins_list': 'सभी डिब्बे',
  'bins_empty': 'अभी कोई स्मार्ट डिब्बा पंजीकृत नहीं है।',
  'bins_map_tab': 'नक्शा',
  'bins_list_tab': 'सूची',
  'bins_no_coords':
      '{n} डिब्बों के निर्देशांक अभी नहीं हैं और वे केवल सूची में दिखते हैं।',
  'bins_location_off': 'लोकेशन बंद है। नक्शा दूरी के बिना दिखाया जा रहा है।',
  'bins_enable_location': 'लोकेशन चालू करें',
  'bins_distance': '{d} दूर',
  'bins_fill': 'भराव स्तर',
  'bins_online': 'ऑनलाइन',
  'bins_offline': 'ऑफ़लाइन',
  'bins_last_seen': 'आखिरी बार {t}',
  'bins_never_seen': 'अभी तक कोई सिग्नल नहीं',
  'bins_temp': 'तापमान',
  'bins_weight': 'तराज़ू की रीडिंग',
  'bins_full_warning': 'यह डिब्बा लगभग भर चुका है',
  'bins_redeem_weight': 'तराज़ू की रीडिंग रिडीम करें',
  'bins_redeem_hint':
      'कचरा इस डिब्बे के तराज़ू पर रखें, फिर रिडीम करें। पॉइंट सर्वर पर डिवाइस की रीडिंग से गिने जाते हैं।',
  'bins_redeemed': '{n} EP रिडीम हुए',
  'bins_map_attribution': '© OpenStreetMap योगदानकर्ता',
  'bins_map_error': 'नक्शा लोड नहीं हो सका।',
  'ago_sec': '{n} सेकंड पहले',
  'ago_min': '{n} मिनट पहले',
  'ago_hour': '{n} घंटे पहले',
  'ago_day': '{n} दिन पहले',

  // Statistics
  'stats_title': 'आँकड़े',
  'stats_week': 'सप्ताह',
  'stats_month': 'महीना',
  'stats_lifetime': 'कुल',
  'stats_activity': 'EP गतिविधि',
  'stats_recent': 'हाल की गतिविधि',
  'stats_earned_period': 'कमाए',
  'stats_spent_period': 'खर्च किए',
  'stats_total_scans': 'कुल स्कैन',
  'stats_limit_note': 'चार्ट आपके नवीनतम {n} लेन-देन का उपयोग करते हैं।',
  'stats_impact_title': 'अनुमानित पर्यावरणीय असर',
  'stats_impact_disclaimer':
      'ये आँकड़े अनुमान हैं, जो आपके स्कैन की संख्या और तय औसत गुणकों से निकाले गए हैं। इन्हें डिब्बे नहीं मापते।',
  'stats_level': 'स्तर',

  // Challenges & achievements
  'ch_title': 'मिशन',
  'ch_daily': 'दैनिक मिशन',
  'ch_claim': 'प्राप्त करें',
  'ch_claimed': 'प्राप्त हो गया',
  'ch_claim_success': '+{n} EP प्राप्त हुए',
  'ch_progress': '{a} / {b}',
  'ch_scan3_t': 'आज 3 डिब्बे स्कैन करें',
  'ch_scan3_s': 'दैनिक स्कैन मिशन',
  'ch_scan5_t': 'आज 5 इको कार्य',
  'ch_scan5_s': 'रीसायकल करते रहें',
  'ch_streak2_t': '2 दिन की स्ट्रीक',
  'ch_streak2_s': 'लगातार दो दिन चेक-इन करें',
  'ach_title': 'उपलब्धियाँ',
  'ach_unlocked': 'अनलॉक',
  'ach_locked': 'लॉक',
  'ach_first_scan_t': 'पहला स्कैन',
  'ach_first_scan_d': 'अपना पहला स्कैन पूरा करें',
  'ach_scan10_t': '10 स्कैन',
  'ach_scan10_d': '10 डिब्बे स्कैन करें',
  'ach_scan50_t': '50 स्कैन',
  'ach_scan50_d': '50 डिब्बे स्कैन करें',
  'ach_earned500_t': '500 EP कमाए',
  'ach_earned500_d': 'कुल 500 EP कमाएँ',
  'ach_earned5000_t': '5,000 EP कमाए',
  'ach_earned5000_d': 'कुल 5,000 EP कमाएँ',
  'ach_sent1_t': 'पहला ट्रांसफ़र',
  'ach_sent1_d': 'किसी दोस्त को EP भेजें',
  'ach_streak7_t': '7 दिन की स्ट्रीक',
  'ach_streak7_d': 'लगातार 7 दिन चेक-इन करें',
  'lvl_0': 'शुरुआती',
  'lvl_1': 'इको',
  'lvl_2': 'ग्रीन वॉरियर',
  'lvl_3': 'इको हीरो',
  'lvl_4': 'पृथ्वी रक्षक',
  'lvl_5': 'EcoPoint मास्टर',
  'streak_title': 'दैनिक स्ट्रीक',
  'streak_bonus_note': 'हर 7 दिन पर +{n} EP बोनस',
  'streak_checkin_success': 'स्ट्रीक: {n} दिन',
  'streak_bonus_success': 'स्ट्रीक बोनस: +{n} EP',

  // Leaderboard
  'lb_title': 'लीडरबोर्ड',
  'lb_empty': 'अभी कोई रैंक वाला उपयोगकर्ता नहीं।',
  'lb_you': 'आप',

  // Profile & settings
  'profile_title': 'प्रोफ़ाइल',
  'profile_edit': 'प्रोफ़ाइल संपादित करें',
  'profile_name': 'प्रदर्शित नाम',
  'profile_bio': 'परिचय',
  'profile_bio_empty': 'छोटा परिचय जोड़ें',
  'profile_avatar': 'अवतार चुनें',
  'profile_saved': 'प्रोफ़ाइल अपडेट हो गई',
  'profile_user_id': 'उपयोगकर्ता ID',
  'settings_title': 'सेटिंग',
  'settings_language': 'भाषा',
  'lang_no_results': 'कोई भाषा नहीं मिली',
  'settings_theme': 'रूप-रंग',
  'theme_system': 'सिस्टम',
  'theme_light': 'लाइट',
  'theme_dark': 'डार्क',
  'settings_notifications': 'सूचनाएँ',
  'settings_privacy': 'गोपनीयता',
  'settings_about': 'EcoPoint के बारे में',
  'settings_version': 'संस्करण {v}',
  'settings_referral': 'दोस्तों को आमंत्रित करें',
  'settings_my_qr': 'मेरा QR कोड',
  'settings_history': 'लेन-देन',
  'settings_purchases': 'खरीद का इतिहास',
  'settings_achievements': 'उपलब्धियाँ',
  'settings_stats': 'आँकड़े',
  'notif_title': 'सूचनाएँ',
  'notif_empty': 'आप सब देख चुके हैं।',
  'notif_prefs_title': 'सूचना प्राथमिकताएँ',
  'notif_pref_activity': 'गतिविधि और इनाम',
  'notif_pref_news': 'EcoPoint की खबरें',
  'notif_prefs_note':
      'प्राथमिकताएँ आपके खाते में सहेजी जाती हैं। पुश सूचनाओं के लिए वैकल्पिक FCM बैकएंड चाहिए (README देखें)।',
  'privacy_body':
      'EcoPoint आपका नाम, ईमेल, प्रोफ़ाइल फ़ोटो, EP बैलेंस और लेन-देन का इतिहास Firebase में रखता है। कैमरा और लोकेशन का उपयोग केवल आपके डिवाइस पर QR कोड पढ़ने और डिब्बों को दूरी के अनुसार क्रमबद्ध करने के लिए होता है; इन्हें कभी अपलोड नहीं किया जाता। आप किसी भी समय अपना खाता और डेटा हटा सकते हैं।',
  'about_body':
      'Green Line Group का EcoPoint रोज़ की रीसायकलिंग को इनाम में बदलता है। स्कैन करें, कमाएँ, रिडीम करें और असर छोड़ें।',
  'about_open_site': 'वेबसाइट खोलें',
  'referral_title': 'दोस्त को आमंत्रित करें',
  'referral_sub': 'अपना कोड शेयर करें। दोस्त के जुड़ने पर आप दोनों EP कमाते हैं।',
  'referral_your_code': 'आपका कोड',
  'referral_have_code': 'दोस्त का कोड है?',
  'referral_enter': 'कोड दर्ज करें',
  'referral_apply': 'कोड लागू करें',
  'referral_applied': 'कोड लागू हुआ: +{n} EP',
  'referral_share_text':
      'EcoPoint पर मेरे साथ जुड़ें और रीसायकल करके इनाम कमाएँ! साइन अप करते समय मेरा कोड {code} इस्तेमाल करें। {link}',
  'danger_zone': 'खतरे का क्षेत्र',
  'sign_out': 'साइन आउट',
  'sign_out_confirm': 'EcoPoint से साइन आउट करें?',
  'delete_account': 'खाता हटाएँ',
  'delete_confirm_title': 'अपना खाता हटाएँ?',
  'delete_confirm_body':
      'आपकी प्रोफ़ाइल, बैलेंस और इतिहास हमेशा के लिए हटा दिए जाएँगे। इसे वापस नहीं किया जा सकता।',
  'delete_done': 'आपका खाता हटा दिया गया।',
  'pro_title': 'EcoPoint Pro',
  'pro_active': 'Pro चालू है',
  'pro_active_until': '{d} तक चालू',
  'pro_info':
      'Pro सदस्यों को स्कैन पर गुणक मिलता है। सब्सक्रिप्शन अभी ऐप में उपलब्ध नहीं हैं।',
  'settings_guide':
      'इको गाइड',
  'settings_admin':
      'एडमिन पैनल',
  'guide_title':
      'इको गाइड',
  'guide_intro':
      'सही ढंग से छाँटा गया कचरा रीसायकल करना बहुत आसान होता है। स्थानीय नियम अलग हो सकते हैं — डिब्बे पर लगे लेबल भी देखें।',
  'guide_plastic_t':
      'प्लास्टिक',
  'guide_plastic_b':
      'बोतलें खाली करें, दबा दें और ढक्कन बंद करें। चिकने या बहुत गंदे डिब्बे रीसायकलिंग को मुश्किल बनाते हैं।',
  'guide_glass_t':
      'काँच',
  'guide_glass_b':
      'जार और बोतलें खाली करके धो लें। शीशे, खिड़की के काँच और चीनी मिट्टी को सामान्य काँच के बर्तनों में न मिलाएँ।',
  'guide_paper_t':
      'कागज़ और गत्ता',
  'guide_paper_b':
      'इसे सूखा रखें। गीला या चिकना कागज़ और इस्तेमाल किए हुए टिशू रीसायकलिंग के लिए उपयुक्त नहीं हैं।',
  'guide_metal_t':
      'धातु',
  'guide_metal_b':
      'टिन और पेय के कैन खाली करें। एल्युमिनियम को बार-बार रीसायकल किया जा सकता है।',
  'guide_battery_t':
      'बैटरी और इलेक्ट्रॉनिक सामान',
  'guide_battery_b':
      'इन्हें कभी सामान्य कचरे में न डालें — इनमें खतरनाक पदार्थ होते हैं। इन्हें किसी निर्धारित संग्रह केंद्र पर दें।',
  'guide_tips_t':
      'छोटे सुझाव',
  'guide_tip_1':
      'पहले कम करें, फिर दोबारा इस्तेमाल करें, और अंत में रीसायकल करें।',
  'guide_tip_2':
      'कपड़े का थैला और अपनी बोतल साल भर में सैकड़ों एक बार इस्तेमाल होने वाली चीज़ों से बचाते हैं।',
  'guide_tip_3':
      'शक होने पर डिब्बे के निर्देश पढ़ें — एक गलत चीज़ पूरी खेप खराब कर सकती है।',
  'lb_weekly':
      'इस सप्ताह',
  'lb_all_time':
      'अब तक',
  'lb_weekly_empty':
      'इस सप्ताह अभी किसी ने EP नहीं कमाए। पहले बनें!',
  'lb_weekly_note':
      'सप्ताह हर सोमवार (बाकू समय) को रीसेट होता है।',
  'ch_monthly':
      'मासिक लक्ष्य',
  'ch_m30_t':
      'इस महीने 30 स्कैन',
  'ch_m30_s':
      'मासिक स्कैन लक्ष्य',
  'ch_m60_t':
      'इस महीने 60 स्कैन',
  'ch_m60_s':
      'बड़ा मासिक लक्ष्य',
  'ch_weekly_prize':
      'हर सोमवार पिछले सप्ताह के शीर्ष 3 को बोनस EP मिलते हैं (200 / 100 / 50)।',
  'home_invite_title':
      'दोस्त को आमंत्रित करें',
  'home_invite_body':
      'अपना कोड और लिंक शेयर करें, आप दोनों को बोनस EP मिलेंगे।',
  'notif_primer_title':
      'रिमाइंडर चालू करें?',
  'notif_primer_body':
      'हम आपको दैनिक स्ट्रीक बनाए रखने की याद दिलाएँगे और साप्ताहिक नतीजों व नए इनामों की जानकारी देंगे। आप इसे कभी भी सेटिंग में बंद कर सकते हैं।',
  'notif_primer_yes':
      'हाँ, चालू करें',
  'notif_primer_later':
      'अभी नहीं',
  'bins_nearest_title':
      'जगह वाला सबसे नज़दीकी डिब्बा',
  'bins_directions':
      'रास्ता',
  'bins_open_failed':
      'मैप्स ऐप नहीं खुल सका',
  'share_card_title':
      'EcoPoint पर मेरे नतीजे',
  'share_card_month':
      'इस महीने के स्कैन',
  'share_card_total':
      'कुल स्कैन',
  'share_card_earned':
      'कमाए गए EP',
  'share_card_streak':
      'दिन की स्ट्रीक',
  'share_card_code':
      'साइन अप करते समय मेरा कोड',
  'share_card_tagline':
      'EcoPoint · रीसायकल करें, EP कमाएँ',
  'share_card_text_plain':
      'मैं EcoPoint के साथ रीसायकल करता हूँ और EP कमाता हूँ!',
  'notif_pref_offers':
      'व्यक्तिगत सुझाव और रिमाइंडर',
  'notif_pref_offers_sub':
      'इनाम के लिए बचे EP, वापसी के रिमाइंडर',
};

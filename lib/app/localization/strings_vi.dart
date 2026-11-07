/// Tiếng Việt (Vietnamese).
const Map<String, String> stringsVi = {
  // Common
  'app_name': 'EcoPoint',
  'ok': 'OK',
  'cancel': 'Hủy',
  'close': 'Đóng',
  'retry': 'Thử lại',
  'save': 'Lưu',
  'continue': 'Tiếp tục',
  'next': 'Tiếp',
  'skip': 'Bỏ qua',
  'done': 'Xong',
  'back': 'Quay lại',
  'loading': 'Đang tải…',
  'copy': 'Sao chép',
  'copied': 'Đã sao chép',
  'share': 'Chia sẻ',
  'search': 'Tìm kiếm',
  'confirm': 'Xác nhận',
  'delete': 'Xóa',
  'edit': 'Chỉnh sửa',
  'see_all': 'Xem tất cả',
  'today': 'Hôm nay',
  'yesterday': 'Hôm qua',
  'ep_unit': 'EP',
  'estimate_tag': 'Ước tính',
  'error_generic': 'Đã xảy ra lỗi. Vui lòng thử lại.',
  'error_network': 'Không có kết nối. Hãy kiểm tra internet và thử lại.',
  'error_backend_unavailable':
      'Không thể kết nối tới máy chủ bảo mật của EcoPoint. Thao tác này cần máy chủ.',
  'offline_banner': 'Bạn đang ngoại tuyến — hiển thị dữ liệu đã lưu',
  'empty_title': 'Chưa có gì ở đây',

  // Navigation
  'nav_home': 'Trang chủ',
  'nav_rewards': 'Quà tặng',
  'nav_scan': 'Quét',
  'nav_bins': 'Thùng rác',
  'nav_profile': 'Hồ sơ',

  // Setup
  'setup_required_title': 'Cần thiết lập Firebase',
  'setup_required_body':
      'Bản dựng này chưa có thông tin Firebase. Hãy chạy `flutterfire configure` cho dự án ecopoint-b3d60 rồi dựng lại. Xem README → Firebase setup.',

  // Onboarding
  'onb_1_title': 'Tái chế. Quét mã. Nhận thưởng.',
  'onb_1_body':
      'Bỏ rác vào thùng rác thông minh EcoPoint, quét mã QR và nhận điểm EP cho mỗi đóng góp.',
  'onb_2_title': 'Đổi lấy quà thật',
  'onb_2_body':
      'Dùng EP để đổi quà từ đối tác, phiếu giảm giá và sản phẩm thân thiện môi trường — hoặc gửi điểm cho bạn bè.',
  'onb_3_title': 'Xem tác động của bạn',
  'onb_3_body':
      'Theo dõi hoạt động tái chế, giữ chuỗi ngày liên tiếp và tìm thùng rác thông minh gần nhất trên bản đồ.',
  'onb_get_started': 'Bắt đầu',
  'onb_have_account': 'Tôi đã có tài khoản',

  // Auth
  'auth_welcome_back': 'Chào mừng trở lại',
  'auth_welcome_back_sub': 'Đăng nhập để tiếp tục kiếm EP.',
  'auth_create_account': 'Tạo tài khoản của bạn',
  'auth_create_account_sub': 'Tham gia EcoPoint và nhận thưởng khi tái chế.',
  'auth_email': 'Email',
  'auth_password': 'Mật khẩu',
  'auth_confirm_password': 'Xác nhận mật khẩu',
  'auth_full_name': 'Họ và tên',
  'auth_forgot_password': 'Quên mật khẩu?',
  'auth_forgot_title': 'Đặt lại mật khẩu',
  'auth_forgot_sub':
      'Nhập email của bạn, chúng tôi sẽ gửi liên kết đặt lại mật khẩu.',
  'auth_send_reset': 'Gửi liên kết đặt lại',
  'auth_reset_sent': 'Đã gửi liên kết. Hãy kiểm tra hộp thư đến.',
  'auth_sign_in': 'Đăng nhập',
  'auth_sign_up': 'Tạo tài khoản',
  'auth_google': 'Tiếp tục với Google',
  'auth_or': 'hoặc',
  'auth_no_account': 'Chưa có tài khoản?',
  'auth_have_account': 'Đã có tài khoản?',
  'auth_err_email': 'Nhập địa chỉ email hợp lệ',
  'auth_err_password_short': 'Dùng ít nhất 8 ký tự',
  'auth_err_password_match': 'Mật khẩu không khớp',
  'auth_err_name': 'Nhập tên của bạn',
  'auth_err_invalid_credential': 'Email hoặc mật khẩu không đúng',
  'auth_err_user_not_found': 'Không tìm thấy tài khoản với email này',
  'auth_err_email_in_use': 'Email này đã được đăng ký',
  'auth_err_weak_password': 'Mật khẩu này quá yếu',
  'auth_err_too_many': 'Quá nhiều lần thử. Vui lòng thử lại sau',
  'auth_err_network': 'Lỗi mạng. Hãy kiểm tra kết nối của bạn',
  'auth_err_disabled': 'Tài khoản này đã bị vô hiệu hóa',
  'auth_err_google_unavailable':
      'Đăng nhập bằng Google chưa được cấu hình cho bản dựng này',
  'auth_err_recent_login': 'Vui lòng đăng nhập lại rồi thử lại',
  'setup_title': 'Thiết lập hồ sơ của bạn',
  'setup_sub': 'Cho chúng tôi biết nên gọi bạn thế nào. Bạn có thể đổi sau.',
  'setup_bio_hint': 'Giới thiệu ngắn (không bắt buộc)',

  // Home
  'greet_morning': 'Chào buổi sáng',
  'greet_afternoon': 'Chào buổi chiều',
  'greet_evening': 'Chào buổi tối',
  'home_balance': 'Số dư EcoPoint',
  'home_scan_cta': 'Quét QR thùng rác',
  'home_send': 'Gửi EP',
  'home_week': '7 ngày qua',
  'home_earned': 'Đã kiếm',
  'home_spent': 'Đã tiêu',
  'home_sent': 'Đã gửi',
  'home_scans': 'Lượt quét',
  'home_impact': 'Tác động của bạn',
  'home_impact_note':
      'Ước tính dựa trên các lượt quét đã ghi nhận của bạn — không phải giá trị đo thực tế.',
  'home_challenges': 'Nhiệm vụ hằng ngày',
  'home_streak': 'Chuỗi ngày',
  'home_streak_days': '{n} ngày',
  'home_streak_checkin': 'Điểm danh hôm nay',
  'home_streak_done': 'Đã điểm danh hôm nay',
  'home_leaderboard': 'Bảng xếp hạng',
  'home_featured': 'Quà nổi bật',
  'home_nearby': 'Thùng rác thông minh',
  'home_no_bins': 'Chưa có thùng rác thông minh nào được đăng ký.',
  'home_no_activity': 'Không có hoạt động trong 7 ngày qua.',
  'home_level_progress': '{cur} / {next} EP',
  'home_level_max': 'Đã đạt cấp tối đa',
  'impact_plastic': 'Nhựa được tái chế',
  'impact_co2': 'CO₂ giảm thải',
  'impact_water': 'Nước tiết kiệm',
  'impact_energy': 'Năng lượng tiết kiệm',
  'unit_g': 'g',
  'unit_l': 'L',
  'unit_wh': 'Wh',

  // Scanner
  'scan_title': 'Quét QR',
  'scan_hint': 'Hướng camera vào mã QR của thùng rác thông minh',
  'scan_hint_friend': 'hoặc quét mã QR EcoPoint của bạn bè để gửi EP',
  'scan_perm_title': 'Cần quyền truy cập camera',
  'scan_perm_body':
      'EcoPoint chỉ dùng camera để đọc mã QR trên thùng rác thông minh và hồ sơ của bạn bè. Không có gì được ghi lại hay tải lên.',
  'scan_perm_grant': 'Cho phép camera',
  'scan_perm_settings': 'Mở cài đặt',
  'scan_perm_denied':
      'Quyền camera đang tắt. Hãy bật trong cài đặt hệ thống để quét.',
  'scan_processing': 'Đang xác minh mã…',
  'scan_invalid': 'Đây không phải mã QR của EcoPoint.',
  'scan_expired': 'Mã QR này đã hết hạn. Hãy quét mã hiện tại của thùng rác.',
  'scan_duplicate': 'Mã QR này đã được sử dụng.',
  'scan_rate_limited': 'Bạn quét quá nhanh. Vui lòng đợi một chút.',
  'scan_daily_limit': 'Bạn đã đạt giới hạn EP của hôm nay.',
  'scan_success_title': 'Đã nhận EP!',
  'scan_success_body': 'Đã cộng vào số dư của bạn',
  'scan_pro_bonus': 'Pro ×{n}',
  'scan_friend_title': 'Phát hiện QR của bạn bè',
  'scan_friend_body': 'Gửi EP cho người dùng này?',
  'scan_torch': 'Đèn pin',
  'scan_again': 'Quét mã khác',
  'scan_unsupported_camera': 'Không thể khởi động camera trên thiết bị này.',

  // Rewards / marketplace
  'market_title': 'Quà tặng',
  'market_sub': 'Dùng EP để đổi quà thật',
  'market_search': 'Tìm quà tặng',
  'cat_all': 'Tất cả',
  'cat_food': 'Đồ ăn',
  'cat_tech': 'Công nghệ',
  'cat_eco': 'Sinh thái',
  'cat_service': 'Dịch vụ',
  'market_empty': 'Không có quà nào khớp với tìm kiếm của bạn.',
  'market_catalog_local':
      'Đang hiển thị danh mục tích hợp. Không tìm thấy danh mục trên máy chủ.',
  'reward_buy': 'Đổi quà',
  'reward_partner': 'Đối tác',
  'reward_available': 'Còn hàng',
  'reward_out_of_stock': 'Hết hàng',
  'reward_confirm_title': 'Đổi món quà này?',
  'reward_confirm_body': 'Sẽ trừ {price} EP khỏi số dư của bạn.',
  'reward_insufficient': 'Không đủ EP',
  'reward_need_more': 'Bạn cần thêm {n} EP',
  'reward_success_title': 'Đã đổi quà',
  'reward_success_body': '{name} hiện đã có trong lịch sử mua của bạn.',
  'reward_history': 'Lịch sử mua',
  'reward_history_empty': 'Bạn chưa đổi món quà nào.',
  'reward_balance_after': 'Số dư sau giao dịch',
  'coupon_title': 'Phiếu giảm giá đối tác',
  'coupon_sub': 'Quy đổi EP thành phiếu giảm giá cửa hàng. Phí: {fee}%.',
  'coupon_amount': 'EP cần quy đổi',
  'coupon_preview': '{ep} EP → {azn} AZN (phí {fee} EP)',
  'coupon_min': 'Tối thiểu {n} EP',
  'coupon_create': 'Tạo phiếu',
  'coupon_ready': 'Phiếu đã sẵn sàng',
  'coupon_show': 'Hãy đưa mã này cho thu ngân',
  'transport_title': 'Yêu cầu nạp thẻ BakıKart',
  'transport_sub':
      'EP được giữ lại ngay bây giờ; việc nạp thẻ sẽ do đối tác vận tải của chúng tôi hoàn tất.',
  'transport_card': 'Số thẻ (16 chữ số)',
  'transport_amount': 'EP cần quy đổi',
  'transport_fee_note': 'Áp dụng phí cố định 2%.',
  'transport_submit': 'Yêu cầu nạp thẻ',
  'transport_pending': 'Đã nhận yêu cầu — trạng thái: chờ đối tác',
  'transport_err_card': 'Nhập số thẻ gồm 16 chữ số',

  // Transfer & history
  'transfer_title': 'Gửi EP',
  'transfer_recipient': 'Người nhận',
  'transfer_search': 'Tìm theo tên hoặc dán ID người dùng',
  'transfer_amount': 'Số lượng',
  'transfer_available': 'Khả dụng: {n} EP',
  'transfer_send': 'Xem lại giao dịch',
  'transfer_confirm_title': 'Xác nhận chuyển',
  'transfer_confirm_body': 'Gửi {n} EP cho {name}? Không thể hoàn tác.',
  'transfer_success': 'Đã gửi {n} EP cho {name}',
  'transfer_err_amount': 'Nhập số lượng hợp lệ',
  'transfer_err_balance': 'Số dư không đủ',
  'transfer_err_self': 'Bạn không thể gửi EP cho chính mình',
  'transfer_err_max': 'Tối đa {n} EP mỗi lần chuyển',
  'transfer_err_recipient': 'Hãy chọn người nhận trước',
  'transfer_no_results': 'Không tìm thấy người dùng',
  'transfer_scan_friend': 'Quét QR',
  'qr_my_title': 'Mã QR của tôi',
  'qr_my_hint': 'Nhờ bạn bè quét mã này để gửi EP cho bạn.',
  'qr_my_copy_id': 'Sao chép ID người dùng của tôi',
  'history_title': 'Giao dịch',
  'history_empty': 'Chưa có giao dịch nào.',
  'tx_earn': 'Đã kiếm',
  'tx_sent': 'Đã gửi',
  'tx_received': 'Đã nhận',
  'tx_purchase': 'Mua hàng',
  'tx_weight': 'Thưởng theo cân nặng',
  'tx_bonus': 'Thưởng thêm',
  'tx_other': 'Giao dịch',
  'tx_filter_all': 'Tất cả',
  'tx_status_completed': 'Hoàn tất',
  'tx_status_pending': 'Đang chờ',
  'tx_status_failed': 'Thất bại',

  // Bins & map
  'bins_title': 'Thùng rác thông minh',
  'bins_sub': 'Trạng thái trực tiếp của thùng rác EcoPoint',
  'bins_list': 'Tất cả thùng rác',
  'bins_empty': 'Chưa có thùng rác thông minh nào được đăng ký.',
  'bins_map_tab': 'Bản đồ',
  'bins_list_tab': 'Danh sách',
  'bins_no_coords':
      '{n} thùng rác chưa có tọa độ và chỉ hiển thị trong danh sách.',
  'bins_location_off': 'Vị trí đang tắt. Bản đồ hiển thị không có khoảng cách.',
  'bins_enable_location': 'Bật vị trí',
  'bins_distance': 'cách {d}',
  'bins_fill': 'Mức đầy',
  'bins_online': 'Trực tuyến',
  'bins_offline': 'Ngoại tuyến',
  'bins_last_seen': 'Lần cuối {t}',
  'bins_never_seen': 'Chưa có tín hiệu',
  'bins_temp': 'Nhiệt độ',
  'bins_weight': 'Số đo cân',
  'bins_full_warning': 'Thùng rác này gần đầy',
  'bins_redeem_weight': 'Nhận điểm theo số đo cân',
  'bins_redeem_hint':
      'Đặt rác lên cân của thùng này rồi nhận điểm. Điểm được máy chủ tính từ số đo của thiết bị.',
  'bins_redeemed': 'Đã nhận {n} EP',
  'bins_map_attribution': '© những người đóng góp OpenStreetMap',
  'bins_map_error': 'Không thể tải bản đồ.',
  'ago_sec': '{n} giây trước',
  'ago_min': '{n} phút trước',
  'ago_hour': '{n} giờ trước',
  'ago_day': '{n} ngày trước',

  // Statistics
  'stats_title': 'Thống kê',
  'stats_week': 'Tuần',
  'stats_month': 'Tháng',
  'stats_lifetime': 'Tổng cộng',
  'stats_activity': 'Hoạt động EP',
  'stats_recent': 'Hoạt động gần đây',
  'stats_earned_period': 'Đã kiếm',
  'stats_spent_period': 'Đã tiêu',
  'stats_total_scans': 'Tổng lượt quét',
  'stats_limit_note': 'Biểu đồ dùng {n} giao dịch gần nhất của bạn.',
  'stats_impact_title': 'Tác động môi trường ước tính',
  'stats_impact_disclaimer':
      'Các số liệu này là ước tính, suy ra từ số lượt quét của bạn với hệ số trung bình cố định. Thùng rác không đo các giá trị này.',
  'stats_level': 'Cấp',

  // Challenges & achievements
  'ch_title': 'Nhiệm vụ',
  'ch_daily': 'Nhiệm vụ hằng ngày',
  'ch_claim': 'Nhận',
  'ch_claimed': 'Đã nhận',
  'ch_claim_success': 'Đã nhận +{n} EP',
  'ch_progress': '{a} / {b}',
  'ch_scan3_t': 'Quét 3 thùng rác hôm nay',
  'ch_scan3_s': 'Nhiệm vụ quét hằng ngày',
  'ch_scan5_t': '5 hành động xanh hôm nay',
  'ch_scan5_s': 'Tiếp tục tái chế',
  'ch_streak2_t': 'Chuỗi 2 ngày',
  'ch_streak2_s': 'Điểm danh hai ngày liên tiếp',
  'ach_title': 'Thành tích',
  'ach_unlocked': 'Đã mở khóa',
  'ach_locked': 'Chưa mở khóa',
  'ach_first_scan_t': 'Lần quét đầu tiên',
  'ach_first_scan_d': 'Hoàn thành lần quét đầu tiên',
  'ach_scan10_t': '10 lượt quét',
  'ach_scan10_d': 'Quét 10 thùng rác',
  'ach_scan50_t': '50 lượt quét',
  'ach_scan50_d': 'Quét 50 thùng rác',
  'ach_earned500_t': 'Kiếm 500 EP',
  'ach_earned500_d': 'Kiếm tổng cộng 500 EP',
  'ach_earned5000_t': 'Kiếm 5.000 EP',
  'ach_earned5000_d': 'Kiếm tổng cộng 5.000 EP',
  'ach_sent1_t': 'Lần chuyển đầu tiên',
  'ach_sent1_d': 'Gửi EP cho một người bạn',
  'ach_streak7_t': 'Chuỗi 7 ngày',
  'ach_streak7_d': 'Điểm danh 7 ngày liên tiếp',
  'lvl_0': 'Người mới',
  'lvl_1': 'Eco',
  'lvl_2': 'Chiến binh xanh',
  'lvl_3': 'Anh hùng Eco',
  'lvl_4': 'Người bảo vệ hành tinh',
  'lvl_5': 'Bậc thầy EcoPoint',
  'streak_title': 'Chuỗi ngày hằng ngày',
  'streak_bonus_note': 'Thưởng +{n} EP mỗi 7 ngày',
  'streak_checkin_success': 'Chuỗi: {n} ngày',
  'streak_bonus_success': 'Thưởng chuỗi ngày: +{n} EP',

  // Leaderboard
  'lb_title': 'Bảng xếp hạng',
  'lb_empty': 'Chưa có người dùng nào được xếp hạng.',
  'lb_you': 'Bạn',

  // Profile & settings
  'profile_title': 'Hồ sơ',
  'profile_edit': 'Chỉnh sửa hồ sơ',
  'profile_name': 'Tên hiển thị',
  'profile_bio': 'Giới thiệu',
  'profile_bio_empty': 'Thêm giới thiệu ngắn',
  'profile_avatar': 'Chọn ảnh đại diện',
  'profile_saved': 'Đã cập nhật hồ sơ',
  'profile_user_id': 'ID người dùng',
  'settings_title': 'Cài đặt',
  'settings_language': 'Ngôn ngữ',
  'lang_no_results': 'Không tìm thấy ngôn ngữ',
  'settings_theme': 'Giao diện',
  'theme_system': 'Hệ thống',
  'theme_light': 'Sáng',
  'theme_dark': 'Tối',
  'settings_notifications': 'Thông báo',
  'settings_privacy': 'Quyền riêng tư',
  'settings_about': 'Giới thiệu EcoPoint',
  'settings_version': 'Phiên bản {v}',
  'settings_referral': 'Mời bạn bè',
  'settings_my_qr': 'Mã QR của tôi',
  'settings_history': 'Giao dịch',
  'settings_purchases': 'Lịch sử mua',
  'settings_achievements': 'Thành tích',
  'settings_stats': 'Thống kê',
  'notif_title': 'Thông báo',
  'notif_empty': 'Bạn đã xem hết rồi.',
  'notif_prefs_title': 'Tùy chọn thông báo',
  'notif_pref_activity': 'Hoạt động và quà tặng',
  'notif_pref_news': 'Tin tức từ EcoPoint',
  'notif_prefs_note':
      'Các tùy chọn được lưu trong tài khoản của bạn. Gửi thông báo đẩy cần máy chủ FCM tùy chọn (xem README).',
  'privacy_body':
      'EcoPoint lưu tên, email, ảnh hồ sơ, số dư EP và lịch sử giao dịch của bạn trên Firebase. Camera và vị trí chỉ được dùng trên thiết bị của bạn để đọc mã QR và sắp xếp thùng rác theo khoảng cách; chúng không bao giờ được tải lên. Bạn có thể xóa tài khoản và dữ liệu bất cứ lúc nào.',
  'about_body':
      'EcoPoint của Green Line Group biến việc tái chế hằng ngày thành phần thưởng. Quét mã, nhận điểm, đổi quà và tạo ra tác động.',
  'about_open_site': 'Mở trang web',
  'referral_title': 'Mời một người bạn',
  'referral_sub': 'Chia sẻ mã của bạn. Cả hai cùng nhận EP khi bạn bè tham gia.',
  'referral_your_code': 'Mã của bạn',
  'referral_have_code': 'Có mã của bạn bè?',
  'referral_enter': 'Nhập mã',
  'referral_apply': 'Áp dụng mã',
  'referral_applied': 'Đã áp dụng mã: +{n} EP',
  'referral_share_text':
      'Tham gia EcoPoint cùng mình và nhận thưởng khi tái chế! Hãy dùng mã {code} của mình khi đăng ký. {link}',
  'danger_zone': 'Khu vực nguy hiểm',
  'sign_out': 'Đăng xuất',
  'sign_out_confirm': 'Đăng xuất khỏi EcoPoint?',
  'delete_account': 'Xóa tài khoản',
  'delete_confirm_title': 'Xóa tài khoản của bạn?',
  'delete_confirm_body':
      'Hồ sơ, số dư và lịch sử của bạn sẽ bị xóa vĩnh viễn. Không thể hoàn tác.',
  'delete_done': 'Tài khoản của bạn đã được xóa.',
  'pro_title': 'EcoPoint Pro',
  'pro_active': 'Pro đang hoạt động',
  'pro_active_until': 'Có hiệu lực đến {d}',
  'pro_info':
      'Thành viên Pro nhận hệ số nhân khi quét. Gói đăng ký hiện chưa có trong ứng dụng.',
  'settings_guide':
      'Hướng dẫn sinh thái',
  'settings_admin':
      'Bảng quản trị',
  'guide_title':
      'Hướng dẫn sinh thái',
  'guide_intro':
      'Rác được phân loại đúng cách sẽ dễ tái chế hơn nhiều. Quy định địa phương có thể khác nhau — hãy xem thêm nhãn trên thùng rác.',
  'guide_plastic_t':
      'Nhựa',
  'guide_plastic_b':
      'Làm rỗng chai, bóp dẹt và đóng nắp. Hộp đựng dính dầu mỡ hoặc quá bẩn sẽ gây khó khăn cho việc tái chế.',
  'guide_glass_t':
      'Thủy tinh',
  'guide_glass_b':
      'Làm rỗng và tráng sạch lọ, chai. Không trộn gương, kính cửa sổ và đồ gốm với bao bì thủy tinh thông thường.',
  'guide_paper_t':
      'Giấy và bìa cứng',
  'guide_paper_b':
      'Giữ khô ráo. Giấy ướt hoặc dính dầu mỡ và khăn giấy đã dùng không thể tái chế.',
  'guide_metal_t':
      'Kim loại',
  'guide_metal_b':
      'Làm rỗng lon thiếc và lon đồ uống. Nhôm có thể được tái chế nhiều lần.',
  'guide_battery_t':
      'Pin và đồ điện tử',
  'guide_battery_b':
      'Tuyệt đối không bỏ vào rác thải chung — chúng chứa chất nguy hại. Hãy mang đến điểm thu gom chuyên dụng.',
  'guide_tips_t':
      'Mẹo nhanh',
  'guide_tip_1':
      'Trước hết hãy giảm thiểu, sau đó tái sử dụng, cuối cùng mới tái chế.',
  'guide_tip_2':
      'Một chiếc túi vải và chai nước riêng giúp tránh hàng trăm đồ dùng một lần mỗi năm.',
  'guide_tip_3':
      'Khi không chắc, hãy đọc hướng dẫn trên thùng rác — chỉ một món sai cũng có thể làm hỏng cả mẻ.',
  'lb_weekly':
      'Tuần này',
  'lb_all_time':
      'Mọi thời điểm',
  'lb_weekly_empty':
      'Tuần này chưa ai kiếm được EP. Hãy là người đầu tiên!',
  'lb_weekly_note':
      'Tuần được đặt lại vào mỗi thứ Hai (giờ Baku).',
  'ch_monthly':
      'Mục tiêu hằng tháng',
  'ch_m30_t':
      '30 lượt quét trong tháng này',
  'ch_m30_s':
      'Mục tiêu quét hằng tháng',
  'ch_m60_t':
      '60 lượt quét trong tháng này',
  'ch_m60_s':
      'Mục tiêu lớn hằng tháng',
  'ch_weekly_prize':
      'Mỗi thứ Hai, top 3 của tuần trước nhận thêm EP thưởng (200 / 100 / 50).',
  'home_invite_title':
      'Mời một người bạn',
  'home_invite_body':
      'Chia sẻ mã và liên kết của bạn, cả hai cùng nhận EP thưởng.',
  'notif_primer_title':
      'Bật nhắc nhở?',
  'notif_primer_body':
      'Chúng tôi sẽ nhắc bạn giữ chuỗi ngày hằng ngày và thông báo kết quả hằng tuần cùng quà tặng mới. Bạn có thể tắt bất cứ lúc nào trong cài đặt.',
  'notif_primer_yes':
      'Có, bật lên',
  'notif_primer_later':
      'Để sau',
  'bins_nearest_title':
      'Thùng rác gần nhất còn chỗ',
  'bins_directions':
      'Chỉ đường',
  'bins_open_failed':
      'Không thể mở ứng dụng bản đồ',
  'share_card_title':
      'Kết quả EcoPoint của tôi',
  'share_card_month':
      'lượt quét tháng này',
  'share_card_total':
      'tổng lượt quét',
  'share_card_earned':
      'EP đã kiếm',
  'share_card_streak':
      'ngày liên tiếp',
  'share_card_code':
      'Mã của tôi khi đăng ký',
  'share_card_tagline':
      'EcoPoint · tái chế, nhận EP',
  'share_card_text_plain':
      'Tôi tái chế và nhận EP cùng EcoPoint!',
  'notif_pref_offers':
      'Mẹo và nhắc nhở cá nhân',
  'notif_pref_offers_sub':
      'EP còn thiếu để đổi quà, nhắc nhở quay lại',
};

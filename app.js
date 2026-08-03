/* ═══════════════════════════════════════════════════════
   ECOPOINT PRO v6.0 — CORE LOGIC
   Full Multilingual · Gamification · Map · Themes
   ═══════════════════════════════════════════════════════ */

// ── FIREBASE ──
const fbCfg = {
  apiKey: "AIzaSyDQ3TJctQIpUpFmjnzOgq3R2_Gx9YvtI4Q",
  authDomain: "ecopoint-b3d60.firebaseapp.com",
  databaseURL: "https://ecopoint-b3d60-default-rtdb.firebaseio.com",
  projectId: "ecopoint-b3d60",
  storageBucket: "ecopoint-b3d60.firebasestorage.app",
  messagingSenderId: "193692283784",
  appId: "1:193692283784:web:b0d47feddd0184380b003d",
  measurementId: "G-GDP88F77JX"
};
firebase.initializeApp(fbCfg);
const auth = firebase.auth();
const db   = firebase.database();
try { firebase.analytics(); } catch(e) {}
const gProv = new firebase.auth.GoogleAuthProvider();
gProv.setCustomParameters({ prompt: 'select_account' });

// ── STATE ──
let UID = null, myBal = 0;
let stats = { earned:0, sent:0, scans:0 };
let txArr = [];
let selItem = null;
let qrScanner = null;
let deferredPrompt = null;
let sendMode = 'uid';
let selectedSearchUser = null;

/* ═══════════════════════════════════════════════════════
   I18N — FULL TRANSLATION SYSTEM
   ═══════════════════════════════════════════════════════ */

const TRANSLATIONS = {
  az: {
    // Nav
    home:'Ana Səhifə', market:'Market', stats:'Statistika', account:'Hesab',
    map:'Xəritə',
    // Header
    liveBalance:'Canlı Balans', earned:'Qazanılan', sent:'Göndərilən', scans:'Skan sayı',
    // Home
    installTitle:'Tətbiqi yüklə', installSub:'Ana ekrana əlavə et — offline işləyir',
    loginCard:'Hesabınıza daxil olun', loginCardSub:'Xallarınızı izləyin • Mükafat qazanın',
    quickActions:'Sürətli Keçid',
    scanBtn:'Skan', challenges:'🏆 Gündəlik Tapşırıqlar', today:'Bu gün',
    ecoImpact:'🌍 Ekoloji Təsirim', ecoTitle:'🌱 Sən Planetə Kömək Etdin',
    ecoPlastic:'qram plastik xilas', ecoCo2:'qram CO₂ azaltdı',
    ecoWater:'litr su saxlandı', ecoEnergy:'wh enerji qənaəti',
    features:'Xüsusiyyətlər', partner:'Tərəfdaş', leaderboard:'🏆 Liderlik', live:'Canlı',
    // Feature cards
    featScanT:'Zibil Skan', featScanS:'QR skan et, EP qazanasan',
    featMktT:'Mükafatlar', featMktS:'EP ilə real mükafat al',
    featMapT:'Ağıllı Zibillər', featMapS:'Yaxın bin-ləri tap',
    featAchT:'Nailiyyətlər', featAchS:'Badgelər qazanıb aç',
    // Streak
    streakLabel:'Gündəlik Seriya', streakDay:'gün',
    // Referral
    refTitle:'Dostunu dəvət et', refSub:'Hər dəvət üçün +200 EP',
    // Market
    marketTitle:'Market', marketSub:'EP ilə real mükafatlar qazanın',
    chipAll:'✨ Hamısı', chipFood:'🍽 Yemək', chipTech:'💻 Texnologiya',
    chipEco:'🌿 Eko', chipService:'🎫 Xidmət',
    buyBtn:'Al',
    // Stats
    statsTitle:'Statistika', lockedT:'Statistika',
    lockedS:'Statistikanı görmək üçün hesabınıza daxil olun', lockedBtn:'Daxil ol',
    weekly:'📅 Son 7 günün fəaliyyəti', recentTx:'Son Əməliyyatlar',
    // Map
    mapTitle:'Ağıllı Zibillər', mapSub:'Yaxınlıqdakı smart bin-ləri tap',
    nearbyBins:'📍 Yaxın Bin-lər', mapLoading:'Xəritə yüklənir...',
    mapLoadingSub:'Ağıllı zibil qutularını tapır',
    // Account
    accTagline:'Ekoloji gələcək üçün hər addım sayılır',
    perkEpT:'EP Qazanın', perkEpS:'Hər ekoloji hərəkətə görə xal',
    perkLbT:'Liderlik Cədvəli', perkLbS:'Öz reytinqinizi izləyin',
    perkRwT:'Mükafatlar', perkRwS:'EP ilə real məhsullar alın',
    perkSecT:'Etibarlı Giriş', perkSecS:'Google hesabı ilə 1 klikdə',
    loginBtn:'Google ilə daxil ol', guestBtn:'Qonaq kimi davam et',
    guestMode:'Qonaq kimi istifadə edirsiniz',
    langLabel:'Tətbiq dili seçin', themeLbl:'Tema',
    settings:'Parametrlər', aboutUs:'Biz Kimik?', aboutApp:'Tətbiq haqqında',
    shareApp:'Tətbiqi paylaş', sendEP:'EP Göndər', logout:'Çıxış',
    myQR:'QR Kodum', copyUID:'UID kopyalandı',
    bioPlaceholder:'Bio əlavə et...',
    version:'EcoPoint Pro • 🌿 Ekoloji gələcək üçün',
    partnerLabel:'Rəsmi Tərəfdaş',
    // Send
    sendTitle:'💸 Xal Göndər', sendUidTab:'🔑 UID ilə', sendSearchTab:'🔍 Ad ilə axtar',
    sendBalLabel:'Mövcud balans:', sendBtn2:'📤 GÖNDƏR', close:'BAĞLA',
    uidPlaceholder:'Dostun UID kodu', amtPlaceholder:'Miqdar (EP)',
    searchPlaceholder:'İstifadəçi adını axtar...',
    // Buy
    buyBtn2:'🛒 SATIN AL',
    // Notifications
    notifTitle:'Bildirişlər', notifWelcomeT:'EcoPoint Pro-ya xoş gəldiniz!',
    notifWelcomeS:'Zibil atın, EP qazanın, mükafatlar əldə edin.',
    // Achievements
    achTitle:'🎴 Nailiyyətlər', achUnlock:'🏆 YENİ NAİLİYYƏT!',
    epEarned:'EP QAZANILDI! 🎉',
    // Scanner
    scanHint:'QR kodu çərçivəyə yönəlt', scanHint2:'Dostunun kodunu skan edib EP göndər',
    scanLightHint:'🔦 İşıq azdırsa yaxınlaşdırın', scanClose:'✕ BAĞLA',
    qrShareHint:'Bu QR kodu dostunuza göstərin ki, EP göndərə bilsin',
    // Admin
    admTitle:'Admin Paneli', admSubtitle:'EcoPoint İdarəetmə',
    admUsersLbl:'İstifadəçi', admScansLbl:'Ümumi Skan', admEpLbl:'Cəmi EP',
    admTabGive:'⚡ EP Ver', admTabDeduct:'➖ Çıxar', admTabUsers:'👥 Üzvlər',
    admTabBroadcast:'📢 Yayım', admTabActivity:'📊 Log', admTabIot:'📡 Cihazlar',
    admGiveBtn:'⚡ EP VER', admDeductBtn:'➖ EP ÇIXAR', admResetBtn:'🔄 Balansı Sıfırla',
    admBroadcastBtn:'📢 YAY', admBroadcastInfo:'📢 Bildiriş siyahısına əlavə et',
    admActInfo:'Son əməliyyatlar', admIotInfo:'📡 Qoşulmuş IoT Cihazları',
    // Coupon
    couponTitle:'🎟️ Kupon Al', couponSubmit:'🎟️ KUPON YARAT',
    couponResultTitle:'Kupon Hazırdır!', couponHint:'Bu kodu mağazada kassaya göstərin',
    transportTitle:'🚌 BakıKart Doldur', transportFee:'💡 %2 sabit haqqı tutulur.',
    transportSubmit:'🚌 KÖÇÜR',
    // About
    aboutTitle:'Biz Kimik?', aboutOpenBtn:'🌐 Saytı Aç',
    // Lang
    langQuickTitle:'🌐 Dil Seçin',
    // DSB
    dsbMain:'Əsas', dsbAccSec:'Hesab', dsbOther:'Digər',
    dsbSendLbl:'EP Göndər', dsbShareLbl:'Paylaş', dsbAboutus:'Biz Kimik?',
    // Toast & Errors
    loginRequired:'Əvvəlcə hesabınıza daxil olun',
    noBalance:'Balansınız kifayət etmir!',
    uidNotFound:'İstifadəçi tapılmadı!',
    selfSend:'Özünüzə göndərə bilməzsiniz',
    maxSend:'Maksimum 10,000 EP göndərə bilərsiniz',
    sendSuccess:'✅ EP göndərildi!',
    welcome:'✅ Xoş gəldiniz!',
    logoutConfirm:'Çıxmaq istədiyinizdən əminsiniz?',
    resetConfirm:'Bu istifadəçinin balansını 0-a sıfırlamaq istədiyinizdən əminsiniz?',
    uidCopied:'✅ UID kopyalandı!',
    linkCopied:'🔗 Keçid kopyalandı!',
    refCopied:'🎯 Referral linki kopyalandı! +200 EP gözlənilir',
    refBonus:'🎉 +200 EP Referral bonusu!',
    appInstalled:'✅ Tətbiq uğurla quraşdırıldı!',
    scanDuplicate:'Bu QR artıq skan edilib!',
    scanEarned:'🎉 EP qazandınız!',
    sendUIDEnter:'UID daxil edin', sendAmtEnter:'Düzgün miqdar daxil edin',
    noUIDProvided:'Hədəf UID seçin',
    days:['B','İ','Ç','C','C','Ş','B'],
  },
  en: {
    home:'Home', market:'Market', stats:'Statistics', account:'Account', map:'Map',
    liveBalance:'Live Balance', earned:'Earned', sent:'Sent', scans:'Scans',
    installTitle:'Install App', installSub:'Add to home screen — works offline',
    loginCard:'Sign in to your account', loginCardSub:'Track your points • Earn rewards',
    quickActions:'Quick Actions',
    scanBtn:'Scan', challenges:'🏆 Daily Missions', today:'Today',
    ecoImpact:'🌍 My Eco Impact', ecoTitle:'🌱 You Helped the Planet',
    ecoPlastic:'grams plastic saved', ecoCo2:'grams CO₂ reduced',
    ecoWater:'liters water saved', ecoEnergy:'wh energy saved',
    features:'Features', partner:'Partner', leaderboard:'🏆 Leaderboard', live:'Live',
    featScanT:'Scan Waste', featScanS:'Scan QR, earn EP',
    featMktT:'Rewards', featMktS:'Redeem EP for real rewards',
    featMapT:'Smart Bins', featMapS:'Find nearby bins',
    featAchT:'Achievements', featAchS:'Unlock badges',
    streakLabel:'Daily Streak', streakDay:'days',
    refTitle:'Invite a friend', refSub:'+200 EP for each invite',
    marketTitle:'Market', marketSub:'Earn real rewards with EP',
    chipAll:'✨ All', chipFood:'🍽 Food', chipTech:'💻 Tech',
    chipEco:'🌿 Eco', chipService:'🎫 Service',
    buyBtn:'Buy',
    statsTitle:'Statistics', lockedT:'Statistics',
    lockedS:'Sign in to see your statistics', lockedBtn:'Sign in',
    weekly:'📅 Last 7 days', recentTx:'Recent Transactions',
    mapTitle:'Smart Bins', mapSub:'Find nearby smart bins',
    nearbyBins:'📍 Nearby Bins', mapLoading:'Loading map...',
    mapLoadingSub:'Locating smart bins',
    accTagline:'Every step counts for an eco future',
    perkEpT:'Earn EP', perkEpS:'Points for every eco action',
    perkLbT:'Leaderboard', perkLbS:'Track your ranking',
    perkRwT:'Rewards', perkRwS:'Buy real items with EP',
    perkSecT:'Secure Login', perkSecS:'One click with Google',
    loginBtn:'Sign in with Google', guestBtn:'Continue as guest',
    guestMode:'You are browsing as a guest',
    langLabel:'Select app language', themeLbl:'Theme',
    settings:'Settings', aboutUs:'About Us', aboutApp:'About App',
    shareApp:'Share app', sendEP:'Send EP', logout:'Logout',
    myQR:'My QR Code', copyUID:'UID copied!',
    bioPlaceholder:'Add a bio...', version:'EcoPoint Pro • 🌿 For an eco future',
    partnerLabel:'Official Partner',
    sendTitle:'💸 Send Points', sendUidTab:'🔑 By UID', sendSearchTab:'🔍 Search by name',
    sendBalLabel:'Available balance:', sendBtn2:'📤 SEND', close:'CLOSE',
    uidPlaceholder:"Friend's UID", amtPlaceholder:'Amount (EP)',
    searchPlaceholder:'Search user...',
    buyBtn2:'🛒 PURCHASE',
    notifTitle:'Notifications', notifWelcomeT:'Welcome to EcoPoint Pro!',
    notifWelcomeS:'Drop waste, earn EP, get rewards.',
    achTitle:'🎴 Achievements', achUnlock:'🏆 NEW ACHIEVEMENT!',
    epEarned:'EP EARNED! 🎉',
    scanHint:'Point at a QR code', scanHint2:"Scan a friend's code to send EP",
    scanLightHint:'🔦 Move closer if light is low', scanClose:'✕ CLOSE',
    qrShareHint:'Show this QR code to a friend to receive EP',
    admTitle:'Admin Panel', admSubtitle:'EcoPoint Management',
    admUsersLbl:'Users', admScansLbl:'Total Scans', admEpLbl:'Total EP',
    admTabGive:'⚡ Give EP', admTabDeduct:'➖ Deduct', admTabUsers:'👥 Members',
    admTabBroadcast:'📢 Broadcast', admTabActivity:'📊 Log', admTabIot:'📡 Devices',
    admGiveBtn:'⚡ GIVE EP', admDeductBtn:'➖ DEDUCT EP', admResetBtn:'🔄 Reset Balance',
    admBroadcastBtn:'📢 BROADCAST', admBroadcastInfo:'📢 Add to notification feed (all users will see)',
    admActInfo:'Recent activity', admIotInfo:'📡 Connected IoT Devices',
    couponTitle:'🎟️ Get Coupon', couponSubmit:'🎟️ CREATE COUPON',
    couponResultTitle:'Coupon Ready!', couponHint:'Show this code at the cashier',
    transportTitle:'🚌 Top Up BakiCard', transportFee:'💡 2% flat fee applies.',
    transportSubmit:'🚌 TRANSFER',
    aboutTitle:'About Us', aboutOpenBtn:'🌐 Open Website',
    langQuickTitle:'🌐 Select Language',
    dsbMain:'Main', dsbAccSec:'Account', dsbOther:'Other',
    dsbSendLbl:'Send EP', dsbShareLbl:'Share', dsbAboutus:'About Us',
    loginRequired:'Please sign in first',
    noBalance:'Insufficient balance!',
    uidNotFound:'User not found!',
    selfSend:'You cannot send to yourself',
    maxSend:'Maximum 10,000 EP per transfer',
    sendSuccess:'✅ EP sent!',
    welcome:'✅ Welcome!',
    logoutConfirm:'Are you sure you want to logout?',
    resetConfirm:'Reset this user balance to 0?',
    uidCopied:'✅ UID copied!', linkCopied:'🔗 Link copied!',
    refCopied:'🎯 Referral link copied! +200 EP pending',
    refBonus:'🎉 +200 EP Referral bonus!',
    appInstalled:'✅ App installed successfully!',
    scanDuplicate:'This QR has already been scanned!',
    scanEarned:'🎉 EP earned!',
    sendUIDEnter:'Enter UID', sendAmtEnter:'Enter valid amount',
    noUIDProvided:'Select a target user',
    days:['Su','Mo','Tu','We','Th','Fr','Sa'],
  },
  ru: {
    home:'Главная', market:'Маркет', stats:'Статистика', account:'Аккаунт', map:'Карта',
    liveBalance:'Живой Баланс', earned:'Заработано', sent:'Отправлено', scans:'Сканы',
    installTitle:'Установить приложение', installSub:'Добавить на экран — работает офлайн',
    loginCard:'Войдите в аккаунт', loginCardSub:'Отслеживайте баллы • Получайте награды',
    quickActions:'Быстрые действия',
    scanBtn:'Сканировать', challenges:'🏆 Дневные задания', today:'Сегодня',
    ecoImpact:'🌍 Мой экоследкомый', ecoTitle:'🌱 Ты помог планете',
    ecoPlastic:'г пластика спасено', ecoCo2:'г CO₂ сокращено',
    ecoWater:'л воды сохранено', ecoEnergy:'вт·ч энергии',
    features:'Функции', partner:'Партнёр', leaderboard:'🏆 Рейтинг', live:'Прямо сейчас',
    featScanT:'Скан мусора', featScanS:'Скань QR, зарабатывай EP',
    featMktT:'Награды', featMktS:'EP за реальные награды',
    featMapT:'Умные баки', featMapS:'Найди ближайшие баки',
    featAchT:'Достижения', featAchS:'Открывай значки',
    streakLabel:'Ежедневная серия', streakDay:'дней',
    refTitle:'Пригласи друга', refSub:'+200 EP за каждое приглашение',
    marketTitle:'Маркет', marketSub:'Заработай реальные награды за EP',
    chipAll:'✨ Все', chipFood:'🍽 Еда', chipTech:'💻 Технологии',
    chipEco:'🌿 Эко', chipService:'🎫 Услуги',
    buyBtn:'Купить',
    statsTitle:'Статистика', lockedT:'Статистика',
    lockedS:'Войдите чтобы увидеть статистику', lockedBtn:'Войти',
    weekly:'📅 Последние 7 дней', recentTx:'Последние операции',
    mapTitle:'Умные баки', mapSub:'Найди умные баки рядом с тобой',
    nearbyBins:'📍 Ближайшие баки', mapLoading:'Загрузка карты...',
    mapLoadingSub:'Поиск умных баков',
    accTagline:'Каждый шаг имеет значение для экобудущего',
    perkEpT:'Зарабатывай EP', perkEpS:'Баллы за каждое экодействие',
    perkLbT:'Рейтинг', perkLbS:'Следи за своим местом',
    perkRwT:'Награды', perkRwS:'Обменивай EP на товары',
    perkSecT:'Безопасный вход', perkSecS:'Один клик через Google',
    loginBtn:'Войти через Google', guestBtn:'Продолжить как гость',
    guestMode:'Вы просматриваете как гость',
    langLabel:'Выберите язык', themeLbl:'Тема',
    settings:'Настройки', aboutUs:'О нас', aboutApp:'О приложении',
    shareApp:'Поделиться', sendEP:'Отправить EP', logout:'Выход',
    myQR:'Мой QR-код', copyUID:'UID скопирован!',
    bioPlaceholder:'Добавить описание...', version:'EcoPoint Pro • 🌿 Для экобудущего',
    partnerLabel:'Официальный партнёр',
    sendTitle:'💸 Отправить баллы', sendUidTab:'🔑 По UID', sendSearchTab:'🔍 Поиск по имени',
    sendBalLabel:'Доступный баланс:', sendBtn2:'📤 ОТПРАВИТЬ', close:'ЗАКРЫТЬ',
    uidPlaceholder:'UID друга', amtPlaceholder:'Количество (EP)',
    searchPlaceholder:'Поиск пользователя...',
    buyBtn2:'🛒 КУПИТЬ',
    notifTitle:'Уведомления', notifWelcomeT:'Добро пожаловать в EcoPoint Pro!',
    notifWelcomeS:'Выбрасывай мусор, зарабатывай EP.',
    achTitle:'🎴 Достижения', achUnlock:'🏆 НОВОЕ ДОСТИЖЕНИЕ!',
    epEarned:'EP ПОЛУЧЕНО! 🎉',
    scanHint:'Наведи на QR-код', scanHint2:'Скань код друга для отправки EP',
    scanLightHint:'🔦 Приближайся если мало света', scanClose:'✕ ЗАКРЫТЬ',
    qrShareHint:'Покажи этот QR-код другу для получения EP',
    admTitle:'Панель администратора', admSubtitle:'Управление EcoPoint',
    admUsersLbl:'Пользователи', admScansLbl:'Всего сканов', admEpLbl:'Всего EP',
    admTabGive:'⚡ Дать EP', admTabDeduct:'➖ Снять', admTabUsers:'👥 Участники',
    admTabBroadcast:'📢 Рассылка', admTabActivity:'📊 Лог', admTabIot:'📡 Устройства',
    admGiveBtn:'⚡ ДАТЬ EP', admDeductBtn:'➖ СНЯТЬ EP', admResetBtn:'🔄 Сбросить баланс',
    admBroadcastBtn:'📢 ОТПРАВИТЬ', admBroadcastInfo:'📢 Добавить в список уведомлений',
    admActInfo:'Последние операции', admIotInfo:'📡 Подключённые IoT устройства',
    couponTitle:'🎟️ Получить купон', couponSubmit:'🎟️ СОЗДАТЬ КУПОН',
    couponResultTitle:'Купон готов!', couponHint:'Покажите этот код кассиру',
    transportTitle:'🚌 Пополнить BakiCard', transportFee:'💡 Комиссия 2%.',
    transportSubmit:'🚌 ПЕРЕВЕСТИ',
    aboutTitle:'О нас', aboutOpenBtn:'🌐 Открыть сайт',
    langQuickTitle:'🌐 Выбрать язык',
    dsbMain:'Главное', dsbAccSec:'Аккаунт', dsbOther:'Другое',
    dsbSendLbl:'Отправить EP', dsbShareLbl:'Поделиться', dsbAboutus:'О нас',
    loginRequired:'Сначала войдите в аккаунт',
    noBalance:'Недостаточно баланса!',
    uidNotFound:'Пользователь не найден!',
    selfSend:'Нельзя отправить самому себе',
    maxSend:'Максимум 10,000 EP за раз',
    sendSuccess:'✅ EP отправлено!',
    welcome:'✅ Добро пожаловать!',
    logoutConfirm:'Вы уверены что хотите выйти?',
    resetConfirm:'Сбросить баланс этого пользователя до 0?',
    uidCopied:'✅ UID скопирован!', linkCopied:'🔗 Ссылка скопирована!',
    refCopied:'🎯 Ссылка скопирована! +200 EP ожидается',
    refBonus:'🎉 +200 EP бонус за реферала!',
    appInstalled:'✅ Приложение установлено!',
    scanDuplicate:'Этот QR уже отсканирован!',
    scanEarned:'🎉 EP получено!',
    sendUIDEnter:'Введите UID', sendAmtEnter:'Введите корректную сумму',
    noUIDProvided:'Выберите получателя',
    days:['Вс','Пн','Вт','Ср','Чт','Пт','Сб'],
  },
  tr: {
    home:'Ana Sayfa', market:'Market', stats:'İstatistik', account:'Hesap', map:'Harita',
    liveBalance:'Canlı Bakiye', earned:'Kazanılan', sent:'Gönderilen', scans:'Tarama',
    installTitle:'Uygulamayı yükle', installSub:'Ana ekrana ekle — çevrimdışı çalışır',
    loginCard:'Hesabınıza giriş yapın', loginCardSub:'Puanlarınızı takip edin • Ödül kazanın',
    quickActions:'Hızlı Erişim',
    scanBtn:'Tara', challenges:'🏆 Günlük Görevler', today:'Bugün',
    ecoImpact:'🌍 Çevre Etkilerim', ecoTitle:'🌱 Gezegene Yardım Ettin',
    ecoPlastic:'gram plastik kurtarıldı', ecoCo2:'gram CO₂ azaltıldı',
    ecoWater:'litre su korundu', ecoEnergy:'wh enerji tasarrufu',
    features:'Özellikler', partner:'Ortak', leaderboard:'🏆 Sıralama', live:'Canlı',
    featScanT:'Çöp Tara', featScanS:'QR tara, EP kazan',
    featMktT:'Ödüller', featMktS:'EP ile gerçek ödüller al',
    featMapT:'Akıllı Çöpler', featMapS:'Yakın kutuları bul',
    featAchT:'Başarımlar', featAchS:'Rozetleri aç',
    streakLabel:'Günlük Seri', streakDay:'gün',
    refTitle:'Arkadaş davet et', refSub:'Her davet için +200 EP',
    marketTitle:'Market', marketSub:'EP ile gerçek ödüller kazanın',
    chipAll:'✨ Tümü', chipFood:'🍽 Yemek', chipTech:'💻 Teknoloji',
    chipEco:'🌿 Eko', chipService:'🎫 Hizmet',
    buyBtn:'Al',
    statsTitle:'İstatistik', lockedT:'İstatistik',
    lockedS:'İstatistikleri görmek için giriş yapın', lockedBtn:'Giriş yap',
    weekly:'📅 Son 7 gün', recentTx:'Son İşlemler',
    mapTitle:'Akıllı Çöp Kutuları', mapSub:'Yakınındaki akıllı kutuları bul',
    nearbyBins:'📍 Yakın Kutular', mapLoading:'Harita yükleniyor...',
    mapLoadingSub:'Akıllı kutular aranıyor',
    accTagline:'Eko bir gelecek için her adım önemli',
    perkEpT:'EP Kazan', perkEpS:'Her eko eylem için puan',
    perkLbT:'Sıralama', perkLbS:'Sıralamanızı takip edin',
    perkRwT:'Ödüller', perkRwS:'EP ile ürün satın alın',
    perkSecT:'Güvenli Giriş', perkSecS:'Google ile tek tıkla',
    loginBtn:'Google ile giriş yap', guestBtn:'Misafir olarak devam et',
    guestMode:'Misafir olarak göz atıyorsunuz',
    langLabel:'Uygulama dilini seçin', themeLbl:'Tema',
    settings:'Ayarlar', aboutUs:'Biz Kimiz?', aboutApp:'Uygulama Hakkında',
    shareApp:'Uygulamayı paylaş', sendEP:'EP Gönder', logout:'Çıkış',
    myQR:'QR Kodum', copyUID:'UID kopyalandı!',
    bioPlaceholder:'Bio ekle...', version:'EcoPoint Pro • 🌿 Eko bir gelecek için',
    partnerLabel:'Resmi Ortak',
    sendTitle:'💸 Puan Gönder', sendUidTab:'🔑 UID ile', sendSearchTab:'🔍 İsimle ara',
    sendBalLabel:'Mevcut bakiye:', sendBtn2:'📤 GÖNDER', close:'KAPAT',
    uidPlaceholder:"Arkadaşın UID'si", amtPlaceholder:'Miktar (EP)',
    searchPlaceholder:'Kullanıcı ara...',
    buyBtn2:'🛒 SATIN AL',
    notifTitle:'Bildirimler', notifWelcomeT:"EcoPoint Pro'ya hoş geldiniz!",
    notifWelcomeS:'Çöp at, EP kazan, ödül al.',
    achTitle:'🎴 Başarımlar', achUnlock:'🏆 YENİ BAŞARIM!',
    epEarned:'EP KAZANILDI! 🎉',
    scanHint:'QR kodu çerçeveye yönelt', scanHint2:"Arkadaşın kodunu tara",
    scanLightHint:'🔦 Işık azsa yaklaşın', scanClose:'✕ KAPAT',
    qrShareHint:'Bu QR kodu arkadaşına göster',
    admTitle:'Admin Paneli', admSubtitle:'EcoPoint Yönetimi',
    admUsersLbl:'Kullanıcı', admScansLbl:'Toplam Tarama', admEpLbl:'Toplam EP',
    admTabGive:'⚡ EP Ver', admTabDeduct:'➖ Düş', admTabUsers:'👥 Üyeler',
    admTabBroadcast:'📢 Yayın', admTabActivity:'📊 Log', admTabIot:'📡 Cihazlar',
    admGiveBtn:'⚡ EP VER', admDeductBtn:'➖ EP DÜŞÜR', admResetBtn:'🔄 Bakiyeyi Sıfırla',
    admBroadcastBtn:'📢 YAYINLA', admBroadcastInfo:'📢 Bildirim listesine ekle',
    admActInfo:'Son işlemler', admIotInfo:'📡 Bağlı IoT Cihazları',
    couponTitle:'🎟️ Kupon Al', couponSubmit:'🎟️ KUPON OLUŞTUR',
    couponResultTitle:'Kupon Hazır!', couponHint:'Bu kodu kasiyere gösterin',
    transportTitle:'🚌 BakiCard Yükle', transportFee:'💡 %2 sabit komisyon.',
    transportSubmit:'🚌 AKTAR',
    aboutTitle:'Biz Kimiz?', aboutOpenBtn:'🌐 Web Sitesini Aç',
    langQuickTitle:'🌐 Dil Seçin',
    dsbMain:'Ana', dsbAccSec:'Hesap', dsbOther:'Diğer',
    dsbSendLbl:'EP Gönder', dsbShareLbl:'Paylaş', dsbAboutus:'Biz Kimiz?',
    loginRequired:'Önce giriş yapın',
    noBalance:'Yetersiz bakiye!',
    uidNotFound:'Kullanıcı bulunamadı!',
    selfSend:'Kendinize gönderemezsiniz',
    maxSend:'Maksimum 10.000 EP gönderilebilir',
    sendSuccess:'✅ EP gönderildi!',
    welcome:'✅ Hoş geldiniz!',
    logoutConfirm:'Çıkış yapmak istediğinize emin misiniz?',
    resetConfirm:'Bu kullanıcının bakiyesini 0\'a sıfırlamak istiyor musunuz?',
    uidCopied:'✅ UID kopyalandı!', linkCopied:'🔗 Bağlantı kopyalandı!',
    refCopied:'🎯 Davet linki kopyalandı! +200 EP bekleniyor',
    refBonus:'🎉 +200 EP Referans bonusu!',
    appInstalled:'✅ Uygulama başarıyla yüklendi!',
    scanDuplicate:'Bu QR zaten tarandı!',
    scanEarned:'🎉 EP kazanıldı!',
    sendUIDEnter:'UID girin', sendAmtEnter:'Geçerli miktar girin',
    noUIDProvided:'Hedef kullanıcı seçin',
    days:['Pz','Pt','Sa','Ça','Pe','Cu','Ct'],
  }
};

let currentLang = localStorage.getItem('ep-lang') || 'az';

// ── T() — quick translate ──
function T(key) {
  return (TRANSLATIONS[currentLang] || TRANSLATIONS.az)[key] || (TRANSLATIONS.az)[key] || key;
}

// ── applyTranslations() — update all i18n elements in DOM ──
function applyTranslations() {
  const L = TRANSLATIONS[currentLang] || TRANSLATIONS.az;
  const set = (id, txt) => { const el = document.getElementById(id); if(el) el.textContent = txt; };
  const setPlaceholder = (id, txt) => { const el = document.getElementById(id); if(el) el.placeholder = txt; };

  // Nav
  set('nb-home-lbl',    L.home);
  set('nb-mkt-lbl',     L.market);
  set('nb-map-lbl',     L.map);
  set('nb-acc-lbl',     L.account);
  // Sidebar
  set('dsb-lbl-home',   L.home);
  set('dsb-lbl-market', L.market);
  set('dsb-lbl-map',    L.map);
  set('dsb-lbl-stats',  L.stats);
  set('dsb-lbl-account',L.account);
  set('dsb-lbl-main',   L.dsbMain);
  set('dsb-lbl-acc-sec',L.dsbAccSec);
  set('dsb-lbl-other',  L.dsbOther);
  set('dsb-send-lbl',   L.dsbSendLbl);
  set('dsb-share-lbl',  L.dsbShareLbl);
  set('dsb-aboutus-lbl',L.dsbAboutus);
  // Topbar
  set('dtb-page-title', L.home);
  // Install
  set('inst-t',         L.installTitle);
  set('inst-s',         L.installSub);
  // Guest card
  set('gc-title',       L.loginCard);
  set('gc-sub',         L.loginCardSub);
  // Balance
  set('live-bal-lbl',   L.liveBalance);
  set('bp-earned-lbl',  L.earned);
  set('bp-sent-lbl',    L.sent);
  set('bp-scans-lbl',   L.scans);
  // Streak
  set('streak-lbl',     L.streakLabel);
  set('streak-day-lbl', L.streakDay);
  // Referral
  set('ref-title',      L.refTitle);
  set('ref-sub',        L.refSub);
  // Quick Actions
  set('home-actions-lbl', L.quickActions);
  set('act-scan-lbl',   L.scanBtn);
  set('act-market-lbl', L.market);
  set('act-stats-lbl',  L.stats);
  set('act-share-lbl',  L.shareApp);
  // Challenges
  set('challenges-lbl', L.challenges);
  set('today-lbl',      L.today);
  // Eco
  set('eco-lbl',        L.ecoImpact);
  set('eco-title',      L.ecoTitle);
  set('eco-plastic-lbl',L.ecoPlastic);
  set('eco-co2-lbl',    L.ecoCo2);
  set('eco-water-lbl',  L.ecoWater);
  set('eco-energy-lbl', L.ecoEnergy);
  // Features
  set('feat-lbl',       L.features);
  set('feat-scan-t',    L.featScanT);
  set('feat-scan-s',    L.featScanS);
  set('feat-mkt-t',     L.featMktT);
  set('feat-mkt-s',     L.featMktS);
  set('feat-map-t',     L.featMapT);
  set('feat-map-s',     L.featMapS);
  set('feat-ach-t',     L.featAchT);
  set('feat-ach-s',     L.featAchS);
  // Partner
  set('partner-lbl',    L.partner);
  set('partner-label',  L.partnerLabel);
  set('lb-lbl',         L.leaderboard);
  set('lb-live-lbl',    L.live);
  set('lb-panel-lbl',   L.leaderboard);
  set('lb-live-panel-lbl', L.live);
  set('about-us-lbl',   L.aboutUs);
  set('panel-about-t',  L.aboutApp);
  // Market
  set('mkt-title',      L.marketTitle);
  set('mkt-sub',        L.marketSub);
  set('chip-all',       L.chipAll);
  set('chip-food',      L.chipFood);
  set('chip-tech',      L.chipTech);
  set('chip-eco',       L.chipEco);
  set('chip-service',   L.chipService);
  // Map
  set('map-title',      L.mapTitle);
  set('map-sub',        L.mapSub);
  set('nearby-bins-lbl',L.nearbyBins);
  set('map-loading-t',  L.mapLoading);
  set('map-loading-s',  L.mapLoadingSub);
  // Stats
  set('stats-title',    L.statsTitle);
  set('stats-locked-t', L.lockedT);
  set('stats-locked-s', L.lockedS);
  set('stats-locked-btn',L.lockedBtn);
  // Account guest
  set('acc-tagline',    L.accTagline);
  set('perk-ep-t',      L.perkEpT);
  set('perk-ep-s',      L.perkEpS);
  set('perk-lb-t',      L.perkLbT);
  set('perk-lb-s',      L.perkLbS);
  set('perk-rw-t',      L.perkRwT);
  set('perk-rw-s',      L.perkRwS);
  set('perk-sec-t',     L.perkSecT);
  set('perk-sec-s',     L.perkSecS);
  set('login-btn-lbl',  L.loginBtn);
  set('guest-skip-btn', L.guestBtn);
  // Settings labels
  set('lang-sec-lbl',   '🌐 ' + L.langLabel);
  set('lang-sel-lbl',   L.langLabel);
  set('theme-lbl-sec',  '🎨 ' + L.themeLbl);
  set('settings-sec-lbl','⚙️ ' + L.settings);
  set('si-aboutus',     L.aboutUs);
  set('si-about',       L.aboutApp);
  set('si-share',       L.shareApp);
  set('si-send',        L.sendEP);
  set('si-logout',      L.logout);
  set('acc-ver-txt',    L.version);
  set('my-qr-lbl',      L.myQR);
  // Admin
  set('adm-title',      L.admTitle);
  set('adm-subtitle',   L.admSubtitle);
  set('adm-users-lbl',  L.admUsersLbl);
  set('adm-scans-lbl',  L.admScansLbl);
  set('adm-ep-lbl',     L.admEpLbl);
  set('adm-tab-give',   L.admTabGive);
  set('adm-tab-deduct', L.admTabDeduct);
  set('adm-tab-users',  L.admTabUsers);
  set('adm-tab-broadcast', L.admTabBroadcast);
  set('adm-tab-activity', L.admTabActivity);
  set('adm-tab-iot',    L.admTabIot);
  set('adm-give-btn',   L.admGiveBtn);
  set('adm-deduct-btn', L.admDeductBtn);
  set('adm-reset-btn',  L.admResetBtn);
  set('adm-broadcast-btn', L.admBroadcastBtn);
  set('adm-broadcast-info', L.admBroadcastInfo);
  set('adm-act-info',   L.admActInfo);
  set('adm-iot-info',   L.admIotInfo);
  // Send overlay
  set('send-title',     L.sendTitle);
  set('send-bal-lbl',   L.sendBalLabel + ' ');
  set('send-btn-lbl',   L.sendBtn2);
  set('send-close-lbl', L.close);
  setPlaceholder('s-uid', L.uidPlaceholder);
  setPlaceholder('s-amt', L.amtPlaceholder);
  setPlaceholder('s-search', L.searchPlaceholder);
  // Buy overlay
  set('buy-btn-lbl',    L.buyBtn2);
  set('buy-close-lbl',  L.close);
  // Notif
  set('notif-title-lbl',L.notifTitle);
  set('notif-welcome-t',L.notifWelcomeT);
  set('notif-welcome-s',L.notifWelcomeS);
  // Achievements
  set('ach-title-lbl',  L.achTitle);
  set('ach-unlock-ttl-lbl', L.achUnlock);
  set('ep-earned-popup-lbl', L.epEarned);
  // Scanner
  set('scan-hint-txt',  L.scanHint);
  set('scan-hint2',     L.scanHint2);
  set('scan-light-hint',L.scanLightHint);
  set('scan-close-btn', L.scanClose);
  set('qr-share-hint',  L.qrShareHint);
  // Coupon
  set('coupon-title-lbl',   L.couponTitle);
  set('coupon-submit-lbl',  L.couponSubmit);
  set('coupon-result-title',L.couponResultTitle);
  set('cr-hint',        L.couponHint);
  set('cr-close-lbl',   L.close);
  set('coupon-close-lbl', L.close);
  set('transport-title',L.transportTitle);
  set('transport-fee-note', L.transportFee);
  set('transport-submit-lbl', L.transportSubmit);
  set('transport-close-lbl', L.close);
  // About
  set('aboutus-title',  L.aboutTitle);
  set('aboutus-open-btn', L.aboutOpenBtn);
  set('aboutus-close-btn', L.close);
  // Lang quick
  set('lang-quick-title', L.langQuickTitle);
  // Stats (profile)
  set('prf-earned-lbl', L.earned);
  set('prf-scans-lbl',  L.scans);
  set('prf-sent-lbl',   L.sent);

  // Sidebar scan btn
  const dsbScanBtn = document.getElementById('dsb-scan-btn-lbl');
  if(dsbScanBtn) dsbScanBtn.innerHTML = '<i class="fa-solid fa-qrcode"></i> ' + (L.scanBtn || 'Skan');

  // Lang flag
  const FLAGS = { az:'🇦🇿', en:'🇬🇧', ru:'🇷🇺', tr:'🇹🇷' };
  const flag = FLAGS[currentLang] || '🌐';
  const hdrFlag = document.getElementById('hdr-lang-flag');
  const dtbFlag = document.getElementById('dtb-lang-flag');
  if(hdrFlag) hdrFlag.textContent = flag;
  if(dtbFlag) dtbFlag.textContent = flag;

  // Re-render market items with translated Buy button
  renderMkt(currentFilter || 'all');
  // Re-render challenges
  renderChallenges();

  // Lang btn active state
  document.querySelectorAll('.lang-btn').forEach(b => b.classList.remove('active'));
  const lb = document.getElementById('lang-' + currentLang);
  if(lb) lb.classList.add('active');
  // Lang quick active state
  document.querySelectorAll('.lang-quick-btn').forEach(b => b.classList.remove('active'));
  const lq = document.getElementById('lq-' + currentLang);
  if(lq) lq.classList.add('active');
}

// ── setLang ──
function setLang(code, el) {
  currentLang = code;
  localStorage.setItem('ep-lang', code);
  applyTranslations();
}
function openLangQuick() {
  document.getElementById('lang-quick-overlay').classList.add('open');
}
function closeLangQuick() {
  document.getElementById('lang-quick-overlay').classList.remove('open');
}
function setLangQuick(code, el) {
  setLang(code, null);
  setTimeout(closeLangQuick, 350);
}

/* ═══════════════════════════════════════════════════════
   MARKET
   ═══════════════════════════════════════════════════════ */
const ITEMS = [
  {id:'p1',  nm:'Şəkərsiz Çay',       nm_en:'Sugar-free Tea',     nm_ru:'Чай без сахара',  nm_tr:'Şekersiz Çay',   brand:'EcoCafe',        ep:150,  ico:'🍵', cat:'food'},
  {id:'p2',  nm:'Üzvi Meyvə Paketi',  nm_en:'Organic Fruit Pack', nm_ru:'Органические фрукты', nm_tr:'Organik Meyve', brand:'GreenMarket', ep:300, ico:'🍎', cat:'food'},
  {id:'p3',  nm:'Enerji İçki',        nm_en:'Energy Drink',       nm_ru:'Энергетик',       nm_tr:'Enerji İçeceği', brand:'GreenBoost',     ep:100,  ico:'⚡', cat:'food'},
  {id:'p4',  nm:'Plov Porsiyası',     nm_en:'Pilaf Portion',      nm_ru:'Плов',            nm_tr:'Pilav Porsiyonu',brand:'Novruz Çayxana', ep:400,  ico:'🍚', cat:'food'},
  {id:'p5',  nm:'USB Günəş Şarjı',    nm_en:'Solar USB Charger',  nm_ru:'Солнечное зарядное', nm_tr:'Güneş USB Şarj', brand:'SolarTech', ep:1200, ico:'☀️', cat:'tech'},
  {id:'p6',  nm:'Eko Qulaqlıq',       nm_en:'Eco Headphones',     nm_ru:'Эко наушники',    nm_tr:'Eko Kulaklık',   brand:'EcoSound',       ep:900,  ico:'🎧', cat:'tech'},
  {id:'p7',  nm:'Smart Tracker',      nm_en:'Smart Tracker',      nm_ru:'Смарт трекер',    nm_tr:'Akıllı Takip',   brand:'GreenTech',      ep:1800, ico:'📡', cat:'tech'},
  {id:'p8',  nm:'Wireless Şarj',      nm_en:'Wireless Charger',   nm_ru:'Беспроводная зарядка', nm_tr:'Kablosuz Şarj', brand:'SolarTech', ep:1500, ico:'🔋', cat:'tech'},
  {id:'p9',  nm:'Bambu Dişfırçası',   nm_en:'Bamboo Toothbrush',  nm_ru:'Бамбуковая щётка',nm_tr:'Bambu Diş Fırçası', brand:'EcoLife', ep:200, ico:'🪥', cat:'eco'},
  {id:'p10', nm:'Bərpaolunan Torba',  nm_en:'Reusable Bag',       nm_ru:'Многоразовая сумка', nm_tr:'Yeniden Kullanımlı Çanta', brand:'GreenBag', ep:250, ico:'👜', cat:'eco'},
  {id:'p11', nm:'Eko Termos',         nm_en:'Eco Thermos',        nm_ru:'Эко термос',      nm_tr:'Eko Termos',     brand:'EcoLife',        ep:600,  ico:'🧊', cat:'eco'},
  {id:'p12', nm:'Eko Sabun Dəsti',    nm_en:'Eco Soap Set',       nm_ru:'Эко набор мыла',  nm_tr:'Eko Sabun Seti', brand:'NaturePure',     ep:180,  ico:'🧼', cat:'eco'},
  {id:'p13', nm:'Avtobus Kartı',      nm_en:'Bus Card',           nm_ru:'Карта автобуса',  nm_tr:'Otobüs Kartı',   brand:'BakuBus',        ep:500,  ico:'🚌', cat:'service'},
  {id:'p14', nm:'Kino Bileti',        nm_en:'Cinema Ticket',      nm_ru:'Билет в кино',    nm_tr:'Sinema Bileti',  brand:'CinePlex',       ep:800,  ico:'🎬', cat:'service'},
  {id:'p15', nm:'Kitabxana Aylığı',   nm_en:'Library Monthly',    nm_ru:'Абонемент библиотеки', nm_tr:'Kütüphane Aboneliği', brand:'BakuLib', ep:350, ico:'📚', cat:'service'},
  {id:'p16', nm:'Kombucha İçki',      nm_en:'Kombucha Drink',     nm_ru:'Чайный гриб',     nm_tr:'Kombucha İçeceği', brand:'FermentBaku', ep:220, ico:'🍶', cat:'food'},
  {id:'c1',  nm:'Bravo Kuponu',       nm_en:'Bravo Coupon',       nm_ru:'Купон Bravo',     nm_tr:'Bravo Kuponu',   brand:'Bravo',          ep:500,  ico:'🛒', cat:'service', isCoupon:true, couponPartnerId:'bravo'},
  {id:'c2',  nm:'Bolmart Kuponu',     nm_en:'Bolmart Coupon',     nm_ru:'Купон Bolmart',   nm_tr:'Bolmart Kuponu', brand:'Bolmart',        ep:300,  ico:'🏪', cat:'service', isCoupon:true, couponPartnerId:'bolmart'},
  {id:'t1',  nm:'BakıKart Doldur',   nm_en:'Top Up BakiCard',    nm_ru:'Пополнить BakiCard', nm_tr:'BakiCard Yükle', brand:'BakuBus',   ep:100,  ico:'🚌', cat:'service', isTransport:true},
];

let currentFilter = 'all';

function getItemName(item) {
  if(currentLang === 'en') return item.nm_en || item.nm;
  if(currentLang === 'ru') return item.nm_ru || item.nm;
  if(currentLang === 'tr') return item.nm_tr || item.nm;
  return item.nm;
}

function renderMkt(filter='all') {
  currentFilter = filter;
  const grid = document.getElementById('mkt-grid');
  if(!grid) return;
  const items = filter==='all' ? ITEMS : ITEMS.filter(i=>i.cat===filter);
  grid.innerHTML = items.map(i => `
    <div class="mkt-item" onclick="openBuy('${i.id}')">
      <div class="mi-thumb">${i.ico}</div>
      <div class="mi-body">
        <div class="mi-name">${escHtml(getItemName(i))}</div>
        <div class="mi-brand">${escHtml(i.brand)}</div>
        <div class="mi-foot">
          <div class="mi-price">${i.ep.toLocaleString()} EP</div>
          <button class="mi-buy" onclick="event.stopPropagation();openBuy('${i.id}')">${T('buyBtn')}</button>
        </div>
      </div>
    </div>
  `).join('');
}
renderMkt();

function filterMkt(cat, el) {
  document.querySelectorAll('.chip').forEach(c=>c.classList.remove('on'));
  el.classList.add('on');
  renderMkt(cat);
}

function openBuy(id) {
  if(!UID) { showToast(T('loginRequired'),'err'); return; }
  selItem = ITEMS.find(i=>i.id===id);
  if(!selItem) return;
  if(selItem.isCoupon) { MarketplaceModule.openCouponModal(selItem.couponPartnerId); return; }
  if(selItem.isTransport) { document.getElementById('ov-transport').classList.add('open'); return; }
  document.getElementById('buy-ico').textContent = selItem.ico;
  document.getElementById('buy-nm').textContent  = getItemName(selItem);
  document.getElementById('buy-br').textContent  = selItem.brand;
  document.getElementById('buy-pr').textContent  = selItem.ep.toLocaleString()+' EP';
  document.getElementById('ov-buy').classList.add('open');
}

function doBuy() {
  if(!selItem||!UID) return;
  if(myBal < selItem.ep) { showToast(T('noBalance')+' '+T('lockedBtn')+': '+selItem.ep.toLocaleString()+' EP','err'); return; }
  const item = selItem;
  db.ref('users/'+UID+'/balance').transaction(cur => {
    if((cur||0) < item.ep) return undefined;
    return (cur||0) - item.ep;
  }, (err, committed) => {
    if(err) { showToast('Xəta baş verdi!','err'); return; }
    if(!committed) { showToast(T('noBalance'),'err'); return; }
    addTx('buy', '-'+item.ep, '🛒 '+T('lockedBtn')+': '+getItemName(item));
    db.ref('users/'+UID+'/purchases').push({ name:getItemName(item), price:item.ep, emoji:item.ico, ts:Date.now() });
    showToast('🎉 '+item.ico+' '+getItemName(item)+' alındı! -'+item.ep.toLocaleString()+' EP','ok');
    launchConfetti && launchConfetti();
    closeOv('ov-buy'); selItem = null;
  });
}

/* ═══════════════════════════════════════════════════════
   AUTH
   ═══════════════════════════════════════════════════════ */
auth.onAuthStateChanged(user => {
  if(user) { UID = user.uid; onLogin(user); }
  else     { UID = null; onLogout(); }
});

function onLogin(user) {
  document.getElementById('hdr-user-btn').classList.add('active');
  document.getElementById('guest-crd').style.display = 'none';
  document.getElementById('bal-hero').style.display  = 'block';
  document.getElementById('state-guest').style.display  = 'none';
  document.getElementById('state-logged').style.display = 'block';
  document.getElementById('ref-card').style.display     = 'block';
  document.getElementById('streak-card').style.display  = 'flex';

  const img = document.getElementById('acc-av');
  img.src = user.photoURL || '';
  img.onerror = () => { img.src=''; };
  document.getElementById('acc-nm').textContent  = user.displayName || 'İstifadəçi';
  document.getElementById('acc-em').textContent  = user.email || '';
  document.getElementById('acc-uid').textContent = user.uid;
  if(document.getElementById('qr-user-name'))
    document.getElementById('qr-user-name').textContent = user.displayName || 'EcoPoint';

  // Desktop sidebar
  const dsbUM = document.getElementById('dsb-user-mini');
  if(dsbUM) dsbUM.style.display = 'flex';
  const dsbUname = document.getElementById('dsb-uname');
  if(dsbUname) dsbUname.textContent = user.displayName || 'İstifadəçi';
  const dsbAv = document.getElementById('dsb-av');
  if(dsbAv) {
    if(user.photoURL) dsbAv.innerHTML = `<img src="${user.photoURL}" style="width:100%;height:100%;border-radius:50%;object-fit:cover;" onerror="this.style.display='none'">`;
    else dsbAv.textContent = (user.displayName||'?')[0].toUpperCase();
  }
  const dtbBW = document.getElementById('dtb-bal-wrap');
  if(dtbBW) dtbBW.style.display = 'flex';

  const ADMIN_EMAILS = ['greenlinegroup2026@gmail.com'];
  if(ADMIN_EMAILS.includes(user.email)) {
    document.getElementById('adm-panel').style.display = 'block';
    loadAdmStats();
    if(typeof IoTModule !== 'undefined') IoTModule.startDeviceMonitoring();
  }

  // IoT weight section
  if(typeof IoTModule !== 'undefined' && typeof WEIGHT_SECTION_HTML !== 'undefined') {
    const ph = document.getElementById('weight-section-placeholder');
    if(ph) { ph.innerHTML = WEIGHT_SECTION_HTML; IoTModule.startLiveWeightDisplay('device001'); }
  }

  setTimeout(applyIncomingTransfers, 1500);
  initReferral();
  if(typeof ProModule !== 'undefined') ProModule.init(user.uid);
  setTimeout(checkNotifDot, 2000);
  updateStreak();

  db.ref('users/'+UID+'/bio').once('value', s => {
    const bio = s.val() || '';
    const bioEl = document.getElementById('acc-bio-txt');
    if(bioEl) {
      bioEl.textContent = bio || T('bioPlaceholder');
      bioEl.classList.toggle('filled', !!bio);
    }
  });

  db.ref('users/'+UID).update({ name:user.displayName, email:user.email, photoURL:user.photoURL||'', lastSeen:Date.now() });

  db.ref('users/'+UID+'/balance').on('value', s => {
    myBal = s.val() || 0;
    countUp('bal-num', myBal);
    const sbal = document.getElementById('s-bal'); if(sbal) sbal.textContent = myBal;
    const sbal2= document.getElementById('s-bal2'); if(sbal2) sbal2.textContent = myBal;
    const dtbNum = document.getElementById('dtb-bal-num'); if(dtbNum) dtbNum.textContent = myBal.toLocaleString();
    const dsbUep = document.getElementById('dsb-uep');    if(dsbUep) dsbUep.textContent = myBal.toLocaleString()+' EP';
  });

  db.ref('users/'+UID+'/stats').on('value', s => {
    const d = s.val() || {};
    stats = { earned:d.earned||0, sent:d.sent||0, scans:d.scans||0 };
    const e = document.getElementById('bp-earned'); if(e) e.textContent = stats.earned.toLocaleString();
    const st= document.getElementById('bp-sent');   if(st) st.textContent = stats.sent.toLocaleString();
    const sc= document.getElementById('bp-scans');  if(sc) sc.textContent = stats.scans.toLocaleString();
    const pe= document.getElementById('prf-earned'); if(pe) pe.textContent = stats.earned.toLocaleString();
    const ps= document.getElementById('prf-scans');  if(ps) ps.textContent = stats.scans.toLocaleString();
    const pt= document.getElementById('prf-sent');   if(pt) pt.textContent = stats.sent.toLocaleString();
    updateProfileLevel(stats.earned);
    refreshStats();
    updateEcoImpact(stats.scans);
    checkAchievements({ scans:stats.scans, earned:stats.earned, sent:stats.sent });
  });

  db.ref('users/'+UID+'/transactions').limitToLast(20).on('value', s => {
    txArr = [];
    s.forEach(c => txArr.unshift({...c.val(), key:c.key}));
    renderTx(); renderWeekly();
  });

  loadLB();
  loadBinList();
  showToast(T('welcome')+' '+(user.displayName||'')+'!','ok');
}

function onLogout() {
  if(typeof ProModule !== 'undefined') ProModule.reset(null);
  document.getElementById('hdr-user-btn').classList.remove('active');
  document.getElementById('guest-crd').style.display = 'flex';
  document.getElementById('bal-hero').style.display  = 'none';
  document.getElementById('state-guest').style.display  = 'block';
  document.getElementById('state-logged').style.display = 'none';
  document.getElementById('ref-card').style.display     = 'none';
  document.getElementById('streak-card').style.display  = 'none';
  const dsbUM = document.getElementById('dsb-user-mini'); if(dsbUM) dsbUM.style.display='none';
  const dtbBW = document.getElementById('dtb-bal-wrap');  if(dtbBW) dtbBW.style.display='none';
  document.getElementById('adm-panel').style.display = 'none';
  document.getElementById('stats-body').innerHTML = `
    <div class="locked-wrap">
      <div class="locked-ico">📊</div>
      <div class="locked-t">${T('lockedT')}</div>
      <div class="locked-s">${T('lockedS')}</div>
      <button class="locked-btn" onclick="switchTab('account',document.getElementById('nb-acc'))">${T('lockedBtn')}</button>
    </div>`;
  loadLB();
}

function doLogin() {
  const btn = document.getElementById('login-btn');
  btn.disabled = true;
  btn.innerHTML = '<div class="spin"></div>';
  auth.signInWithPopup(gProv).catch(e => {
    btn.disabled = false;
    btn.innerHTML = `<img src="https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg" width="20" alt="Google"><span>${T('loginBtn')}</span>`;
    if(e.code==='auth/popup-closed-by-user') return;
    showToast('Xəta: '+(e.message||e.code),'err');
  });
}

function doLogout() {
  if(!confirm(T('logoutConfirm'))) return;
  auth.signOut().then(() => {
    switchTab('home', document.getElementById('nb-home'));
    myBal=0; txArr=[]; stats={earned:0,sent:0,scans:0};
  });
}

function requireLogin(fn) {
  if(UID) fn();
  else {
    showToast(T('loginRequired'),'err');
    setTimeout(() => switchTab('account', document.getElementById('nb-acc')), 600);
  }
}

/* ═══════════════════════════════════════════════════════
   NAVIGATION
   ═══════════════════════════════════════════════════════ */
function switchTab(id, el, source) {
  // Bütün page-ləri gizlət
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));

  // Hədəf page-i göstər
  const pg = document.getElementById('pg-' + id);
  if (pg) pg.classList.add('active');

  // Mobile nav — hamısını söndür, seçilmişi yandır
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('on'));
  const mobileMap = { home:'nb-home', market:'nb-mkt', stats:'nb-stats', account:'nb-acc', map:'nb-map' };
  const mEl = document.getElementById(mobileMap[id]);
  if (mEl) mEl.classList.add('on');

  // Desktop sidebar
  document.querySelectorAll('.dsb-nav-item').forEach(n => n.classList.remove('on'));
  const dEl = document.getElementById('dsb-' + id);
  if (dEl) dEl.classList.add('on');

  // Topbar başlığı
  const titleEl = document.getElementById('dtb-page-title');
  const TITLES = { home:'home', market:'marketTitle', stats:'statsTitle', account:'account', map:'mapTitle' };
  if (titleEl) titleEl.textContent = T(TITLES[id] || 'home');

  // Scroll sıfırla
  const content = document.getElementById('main-content');
  if (content) content.scrollTop = 0;
}

/* ═══════════════════════════════════════════════════════
   MAP & BINS
   ═══════════════════════════════════════════════════════ */
function loadBinList() {
  const list = document.getElementById('bin-list');
  if(!list) return;

  // Listen to Firebase devices
  db.ref('devices').on('value', snap => {
    const devices = snap.val() || {};
    const entries = Object.entries(devices);

    const ph = document.getElementById('map-placeholder');
    if(ph) ph.style.display = 'none';

    if(!entries.length) {
      list.innerHTML = `
        <div style="padding:24px;text-align:center;color:var(--t2);font-size:13px;">
          <div style="font-size:36px;margin-bottom:8px;">📡</div>
          ${T('admIotInfo')}: —
        </div>`;
      return;
    }

    list.innerHTML = entries.map(([id, dev]) => {
      const fill = Math.min(100, Math.max(0, dev.fillPercent || 0));
      const isOnline = dev.lastSeen && (Date.now() - dev.lastSeen < 60000);
      const fillColor = fill > 80 ? '#ff4757' : fill > 50 ? '#ffa502' : '#00ff7a';
      const ts = dev.lastSeen ? timeAgo(dev.lastSeen) : '—';

      return `
      <div class="bin-card ${isOnline ? 'online' : 'offline'}">
        <div class="bin-ico">🗑️</div>
        <div class="bin-info">
          <div class="bin-name">${escHtml(dev.name || id)}</div>
          <div class="bin-loc">📍 ${escHtml(dev.location || '—')}</div>
          <div class="bin-fill">
            <div class="bin-fill-bar" style="width:${fill}%;background:${fillColor};"></div>
          </div>
        </div>
        <div class="bin-right">
          <div class="bin-pct" style="color:${fillColor}">${fill}%</div>
          <div class="bin-status">
            <span class="bin-dot ${isOnline ? 'on' : 'off'}"></span>${ts}
          </div>
        </div>
      </div>`;
    }).join('');
  });
}

function timeAgo(ts) {
  const diff = Math.floor((Date.now() - ts) / 1000);
  if(diff < 60)   return diff + ' san';
  if(diff < 3600) return Math.floor(diff/60) + ' dəq';
  return Math.floor(diff/3600) + ' saat';
}

/* ═══════════════════════════════════════════════════════
   LEADERBOARD
   ═══════════════════════════════════════════════════════ */
function loadLB() {
  db.ref('users').orderByChild('balance').limitToLast(10).on('value', snap => {
    const list = [];
    snap.forEach(c => { if((c.val().balance||0) > 0 || c.key===UID) list.unshift({id:c.key,...c.val()}); });
    const el = document.getElementById('lb-body');
    const elP= document.getElementById('lb-body-panel');
    const html = !list.length
      ? `<div class="empty-state"><i class="fa-solid fa-users"></i><p>${T('leaderboard')}</p></div>`
      : list.slice(0,8).map((u,i) => {
        const r = i+1;
        const rc = r===1?'r1':r===2?'r2':r===3?'r3':'';
        const med = r===1?'🥇':r===2?'🥈':r===3?'🥉':r;
        const me = u.id === UID;
        return `<div class="lb-row${me?' me':''}">
          <div class="lb-rank ${rc}">${med}</div>
          <div class="lb-av${me?' me':''}">
            ${u.photoURL
              ? `<img src="${escHtml(u.photoURL)}" style="width:100%;height:100%;border-radius:50%;object-fit:cover;" onerror="this.style.display='none'">`
              : (u.name||'?')[0].toUpperCase()}
          </div>
          <div class="lb-inf">
            <div class="lb-nm">${escHtml(u.name||'İstifadəçi')}${me?'&thinsp;<span style="font-size:9px;color:var(--g1);">(★)</span>':''}</div>
            <div class="lb-ep-sub">${(u.balance||0).toLocaleString()} EcoPoint</div>
          </div>
          <div class="lb-badge">${(u.balance||0).toLocaleString()}</div>
        </div>`;
      }).join('');
    if(el) el.innerHTML = html;
    if(elP) elP.innerHTML = html;
  });
}

/* ═══════════════════════════════════════════════════════
   STATS
   ═══════════════════════════════════════════════════════ */
function refreshStats() {
  const el = document.getElementById('stats-body');
  if(!el || !UID) return;
  el.innerHTML = `
    <div class="stats-trio">
      <div class="sbox"><div class="sbox-val">${stats.earned.toLocaleString()}</div><div class="sbox-lbl">${T('earned')}</div></div>
      <div class="sbox"><div class="sbox-val">${stats.scans.toLocaleString()}</div><div class="sbox-lbl">${T('scans')}</div></div>
      <div class="sbox"><div class="sbox-val">${stats.sent.toLocaleString()}</div><div class="sbox-lbl">${T('sent')}</div></div>
    </div>
    <div class="chart-card">
      <div class="chart-t">${T('weekly')}</div>
      <div class="bar-group" id="weekly-chart"></div>
    </div>
    <div class="tx-card">
      <div class="tx-head"><div class="tx-head-t">${T('recentTx')}</div></div>
      <div class="tx-body" id="tx-list-stats">
        <div class="loading-center"><div class="spin spin-g"></div></div>
      </div>
    </div>`;
  renderTx();
  renderWeekly();
}

function renderTx() {
  const els = ['tx-list-stats'];
  els.forEach(id => {
    const el = document.getElementById(id);
    if(!el) return;
    if(!txArr.length) { el.innerHTML=`<div class="empty-state"><i class="fa-solid fa-receipt"></i><p>—</p></div>`; return; }
    el.innerHTML = txArr.slice(0,15).map(tx => {
      const cls = tx.type==='earn'||tx.type==='received' ? 'plus' : 'minus';
      const ico = tx.type==='earn'?'earn':tx.type==='snd'?'snd':tx.type==='buy'?'buy':'received';
      const emo = tx.type==='earn'?'♻️':tx.type==='snd'?'📤':tx.type==='buy'?'🛒':'📥';
      return `<div class="tx-row">
        <div class="tx-ico ${ico}">${emo}</div>
        <div class="tx-inf">
          <div class="tx-desc">${escHtml(tx.desc||'—')}</div>
          <div class="tx-date">${tx.date||''}</div>
        </div>
        <div class="tx-amt ${cls}">${tx.amount||''}</div>
      </div>`;
    }).join('');
  });
}

function renderWeekly() {
  const el = document.getElementById('weekly-chart');
  if(!el) return;
  const now = Date.now();
  const days = T('days');
  const dayData = Array(7).fill(0);
  txArr.forEach(tx => {
    if(!tx.ts||!tx.rawAmount) return;
    const diff = Math.floor((now - tx.ts) / 86400000);
    if(diff < 7 && diff >= 0 && tx.type==='earn') dayData[6-diff] += tx.rawAmount;
  });
  const max = Math.max(...dayData, 1);
  const today = new Date().getDay();
  const labels = Array(7).fill(0).map((_,i) => days[(today-6+i+7)%7]);
  el.innerHTML = dayData.map((v,i) => `
    <div class="bar-row">
      <div class="bar-d">${labels[i]}</div>
      <div class="bar-track"><div class="bar-fill${v>0?' has-data':''}" style="width:${(v/max*100).toFixed(1)}%"></div></div>
      <div class="bar-v">${v>0?v:''}</div>
    </div>`).join('');
}

/* ═══════════════════════════════════════════════════════
   TRANSACTIONS
   ═══════════════════════════════════════════════════════ */
function addTx(type, amount, desc) {
  if(!UID) return;
  db.ref('users/'+UID+'/transactions').push({
    type, amount, desc,
    date: new Date().toLocaleDateString('az-AZ',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}),
    ts: Date.now(),
    rawAmount: Math.abs(parseInt(amount)) || 0
  });
}
function updStat(key, amount) {
  if(!UID) return;
  db.ref('users/'+UID+'/stats/'+key).transaction(c => (c||0)+amount);
}

/* ═══════════════════════════════════════════════════════
   SCANNER
   ═══════════════════════════════════════════════════════ */
function openScanner() {
  const sc = document.getElementById('scan-screen');
  sc.classList.add('open');
  if(typeof Html5Qrcode === 'undefined') { showToast('Skaner yüklənir...','warn'); sc.classList.remove('open'); return; }
  try {
    qrScanner = new Html5Qrcode('reader');
    qrScanner.start({ facingMode:'environment' }, { fps:10, qrbox:{width:220,height:220} },
      decoded => {
        qrScanner.stop().catch(()=>{});
        document.getElementById('scan-screen').classList.remove('open');
        handleQR(decoded);
      }, () => {}
    ).catch(err => {
      document.getElementById('scan-screen').classList.remove('open');
      showToast(err.toString().includes('permission') ? 'Kamera icazəsi lazımdır' : 'Kamera açılmadı','err');
    });
  } catch(e) {
    document.getElementById('scan-screen').classList.remove('open');
    showToast('Skaner xətası','err');
  }
}

function closeScanner() {
  if(qrScanner) { qrScanner.stop().catch(()=>{}); qrScanner=null; }
  document.getElementById('scan-screen').classList.remove('open');
}

function handleQR(text) {
  triggerScanRipple();
  const BASE = 50;
  const EP = (typeof ProModule !== 'undefined' && ProModule.isPro()) ? BASE*2 : BASE;
  const isPro = EP > BASE;
  const scanKey = 'scan_'+text.replace(/[^a-zA-Z0-9]/g,'_')+'_'+UID;
  db.ref('scans/'+scanKey).once('value', s => {
    if(s.exists()) { showToast(T('scanDuplicate'),'err'); return; }
    db.ref('users/'+UID+'/balance').transaction(c => (c||0)+EP);
    db.ref('scans/'+scanKey).set({ ts:Date.now(), uid:UID });
    addTx('earn', '+'+EP, '♻️ QR Skan'+(isPro?' ⚡ 2×PRO':'')+' — '+EP+' EP');
    updStat('earned', EP); updStat('scans', 1);
    showToast('🎉 +'+EP+' EP '+T('scanEarned')+(isPro?' ⚡ PRO!':''),'ok');
    epPopup && epPopup(EP);
    if(isPro) launchConfetti && launchConfetti();
  });
}

/* ═══════════════════════════════════════════════════════
   MY QR
   ═══════════════════════════════════════════════════════ */
function showMyQR() {
  if(!UID) return;
  document.getElementById('qr-user-name').textContent = auth.currentUser?.displayName || 'EcoPoint';
  document.getElementById('my-qr-overlay').classList.add('open');
  generateQR(UID, 'my-qr-canvas');
}
function closeMyQR() { document.getElementById('my-qr-overlay').classList.remove('open'); }

function generateQR(text, canvasId) {
  const canvas = document.getElementById(canvasId);
  if(!canvas) return;
  const ctx = canvas.getContext('2d');
  const size=200, modules=25, mSize=size/modules;
  const seed = text.split('').reduce((a,c)=>a+c.charCodeAt(0),0);
  ctx.fillStyle='#ffffff'; ctx.fillRect(0,0,size,size);
  ctx.fillStyle='#0a2a16';
  [[0,0],[modules-7,0],[0,modules-7]].forEach(([r,c]) => {
    ctx.fillStyle='#0a2a16'; ctx.fillRect(c*mSize,r*mSize,7*mSize,7*mSize);
    ctx.fillStyle='#fff';    ctx.fillRect((c+1)*mSize,(r+1)*mSize,5*mSize,5*mSize);
    ctx.fillStyle='#0a2a16'; ctx.fillRect((c+2)*mSize,(r+2)*mSize,3*mSize,3*mSize);
  });
  for(let row=0;row<modules;row++) for(let col=0;col<modules;col++) {
    const inTL=row<8&&col<8, inTR=row<8&&col>=modules-8, inBL=row>=modules-8&&col<8;
    if(inTL||inTR||inBL) continue;
    const idx=(row*modules+col)%text.length;
    const bit=((text.charCodeAt(idx)^(row*7+col*13+seed))&1)===1;
    if(bit) {
      ctx.fillStyle='#0a2a16'; ctx.beginPath();
      ctx.roundRect?ctx.roundRect(col*mSize+.5,row*mSize+.5,mSize-1,mSize-1,2):ctx.fillRect(col*mSize+.5,row*mSize+.5,mSize-1,mSize-1);
      ctx.fill();
    }
  }
  const cx=size/2,cy=size/2;
  ctx.fillStyle='#fff'; ctx.beginPath(); ctx.arc(cx,cy,20,0,Math.PI*2); ctx.fill();
  ctx.font='bold 26px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
  ctx.fillText('🌿',cx,cy+1);
}

/* ═══════════════════════════════════════════════════════
   SEND
   ═══════════════════════════════════════════════════════ */
function openSend() {
  const el = document.getElementById('s-bal'); if(el) el.textContent = myBal;
  document.getElementById('ov-send').classList.add('open');
  switchSendTab('uid');
}

function switchSendTab(tab) {
  sendMode = tab;
  const uid = document.getElementById('send-uid-section');
  const srch= document.getElementById('send-search-section');
  const tu  = document.getElementById('send-tab-uid');
  const ts  = document.getElementById('send-tab-search');
  if(tab==='uid') {
    uid.style.display='block'; srch.style.display='none';
    tu.classList.add('on'); ts.classList.remove('on');
  } else {
    uid.style.display='none'; srch.style.display='block';
    ts.classList.add('on'); tu.classList.remove('on');
  }
}

function doSend() {
  let tid = document.getElementById('s-uid').value.trim();
  if(sendMode==='search' && selectedSearchUser) tid = selectedSearchUser;
  const amt = parseInt(document.getElementById('s-amt').value);
  if(!tid)         { showToast(T('sendUIDEnter'),'err'); return; }
  if(!amt||amt<=0) { showToast(T('sendAmtEnter'),'err'); return; }
  if(amt > myBal)  { showToast(T('noBalance'),'err'); return; }
  if(tid===UID)    { showToast(T('selfSend'),'err'); return; }
  if(amt>10000)    { showToast(T('maxSend'),'err'); return; }

  db.ref('users/'+tid).once('value', s => {
    if(!s.exists()) { showToast(T('uidNotFound'),'err'); return; }
    const rName = s.val().name||'İstifadəçi';
    db.ref('users/'+UID+'/balance').transaction(cur => {
      if((cur||0)<amt) return undefined;
      return (cur||0)-amt;
    }, (err, committed) => {
      if(err||!committed) { showToast(T('noBalance'),'err'); return; }
      const txId = 'TRF_'+Date.now()+'_'+Math.random().toString(36).slice(2,6);
      db.ref('users/'+tid+'/incoming/'+txId).set({ from:UID, fromName:auth.currentUser?.displayName||'—', amount:amt, ts:Date.now() });
      db.ref('users/'+tid+'/balance').transaction(c=>(c||0)+amt);
      addTx('snd','-'+amt,'➤ '+rName+'-ə göndərildi');
      updStat('sent', amt);
      db.ref('users/'+tid+'/transactions').push({ type:'received', amount:'+'+amt, desc:'⬇ '+(auth.currentUser?.displayName||'—')+' tərəfindən', date:new Date().toLocaleDateString('az-AZ',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}), ts:Date.now(), rawAmount:amt });
      showToast(T('sendSuccess')+' '+amt.toLocaleString()+' EP → '+rName,'ok');
      closeOv('ov-send');
      document.getElementById('s-uid').value='';
      document.getElementById('s-amt').value='';
      selectedSearchUser=null;
    });
  });
}

function applyIncomingTransfers() {
  if(!UID) return;
  db.ref('users/'+UID+'/incoming').once('value', snap => {
    if(!snap.exists()) return;
    snap.forEach(child => {
      const t = child.val(); if(!t||!t.amount) return;
      db.ref('users/'+UID+'/balance').transaction(c=>(c||0)+t.amount);
      db.ref('users/'+UID+'/transactions').push({ type:'received', amount:'+'+t.amount, desc:'⬇ '+(t.fromName||'—')+' tərəfindən', date:new Date().toLocaleDateString('az-AZ',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}), ts:t.ts||Date.now(), rawAmount:t.amount });
      child.ref.remove();
    });
  });
}

// User search
let searchTimer;
function searchUsers(query) {
  const res = document.getElementById('user-search-results');
  if(!res) return;
  if(!query||query.length<2) { res.style.display='none'; return; }
  res.style.display='block';
  res.innerHTML='<div class="loading-center"><div class="spin spin-g"></div></div>';
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    db.ref('users').orderByChild('name').startAt(query).endAt(query+'\uf8ff').limitToFirst(8).once('value', snap => {
      const users=[];
      snap.forEach(c=>{ if(c.key!==UID) users.push({id:c.key,...c.val()}); });
      if(!users.length) { res.innerHTML=`<div class="search-empty">🔍 ${T('uidNotFound')}</div>`; return; }
      res.innerHTML=users.map(u=>`
        <div class="user-result-item" onclick="selectSearchUser('${u.id}','${escHtml(u.name||'İstifadəçi')}')">
          <div class="user-result-av">${u.photoURL?`<img src="${escHtml(u.photoURL)}" style="width:100%;height:100%;border-radius:50%;object-fit:cover;" onerror="this.style.display='none'">`:((u.name||'?')[0].toUpperCase())}</div>
          <div><div class="user-result-nm">${escHtml(u.name||'—')}</div><div class="user-result-ep">${(u.balance||0).toLocaleString()} EP</div></div>
          <i class="fa-solid fa-chevron-right user-result-sel"></i>
        </div>`).join('');
    });
  }, 350);
}

function selectSearchUser(uid, name) {
  selectedSearchUser = uid;
  document.getElementById('s-search').value = name;
  document.getElementById('user-search-results').style.display='none';
  showToast('✅ '+name+' seçildi','ok');
  document.getElementById('s-amt').focus();
}

/* ═══════════════════════════════════════════════════════
   ADMIN
   ═══════════════════════════════════════════════════════ */
function adminGive() {
  const tid = document.getElementById('adm-uid').value.trim();
  const amt = parseInt(document.getElementById('adm-amt').value);
  if(!tid||!amt||amt<=0) { showToast(T('sendUIDEnter'),'err'); return; }
  if(amt>999999) { showToast('Çox böyük miqdar','err'); return; }
  db.ref('users/'+tid).once('value', s => {
    if(!s.exists()) { showToast(T('uidNotFound'),'err'); return; }
    db.ref('users/'+tid+'/balance').transaction(c=>(c||0)+amt).then(() => {
      db.ref('users/'+tid+'/stats/earned').transaction(c=>(c||0)+amt);
      db.ref('users/'+tid+'/transactions').push({ type:'earn', amount:'+'+amt, desc:'⚡ Admin tərəfindən verildi', date:new Date().toLocaleDateString('az-AZ'), ts:Date.now(), rawAmount:amt });
      showToast('✅ '+amt.toLocaleString()+' EP verildi!','ok');
      document.getElementById('adm-uid').value='';
      document.getElementById('adm-amt').value='';
      if(document.getElementById('adm-reason')) document.getElementById('adm-reason').value='';
      setTimeout(loadAdmStats, 600);
    });
  });
}

function adminDeduct() {
  const tid = document.getElementById('adm-uid2').value.trim();
  const amt = parseInt(document.getElementById('adm-amt2').value);
  if(!tid||!amt||amt<=0) { showToast(T('sendUIDEnter'),'err'); return; }
  db.ref('users/'+tid).once('value', s => {
    if(!s.exists()) { showToast(T('uidNotFound'),'err'); return; }
    db.ref('users/'+tid+'/balance').transaction(cur => Math.max(0,(cur||0)-amt)).then(() => {
      showToast('✅ '+amt.toLocaleString()+' EP çıxıldı!','ok');
      document.getElementById('adm-uid2').value='';
      document.getElementById('adm-amt2').value='';
    });
  });
}

function adminResetBalance() {
  const tid = document.getElementById('adm-uid2').value.trim();
  if(!tid) { showToast(T('sendUIDEnter'),'err'); return; }
  if(!confirm(T('resetConfirm'))) return;
  db.ref('users/'+tid).once('value', s => {
    if(!s.exists()) { showToast(T('uidNotFound'),'err'); return; }
    db.ref('users/'+tid+'/balance').set(0).then(() => showToast('✅ Balans sıfırlandı!','ok'));
  });
}

function admTab(tab, el) {
  document.querySelectorAll('.adm-tab').forEach(t=>t.classList.remove('on'));
  el.classList.add('on');
  document.querySelectorAll('.adm-section').forEach(s=>s.classList.remove('on'));
  const sec = document.getElementById('adm-'+tab);
  if(sec) sec.classList.add('on');
  if(tab==='users') loadAdmUsers();
  if(tab==='activity') loadAdmActivity();
  if(tab==='iot' && typeof IoTModule !== 'undefined') IoTModule.startDeviceMonitoring();
}

function loadAdmStats() {
  db.ref('users').once('value', snap => {
    let count=0, totalScans=0, totalEP=0;
    snap.forEach(c => { count++; totalScans+=(c.val().stats?.scans||0); totalEP+=(c.val().balance||0); });
    const tu = document.getElementById('adm-total-users'); if(tu) tu.textContent = count;
    const ts = document.getElementById('adm-total-scans'); if(ts) ts.textContent = totalScans;
    const te = document.getElementById('adm-total-ep');   if(te) te.textContent = totalEP>999?(totalEP/1000).toFixed(1)+'k':totalEP;
  });
}

function loadAdmUsers() {
  const ul = document.getElementById('adm-user-list');
  if(!ul) return;
  ul.innerHTML='<div class="loading-center"><div class="spin spin-g"></div></div>';
  db.ref('users').orderByChild('balance').limitToLast(15).once('value', snap => {
    const list=[];
    snap.forEach(c=>list.unshift({id:c.key,...c.val()}));
    if(!list.length) { ul.innerHTML='<div style="padding:16px;text-align:center;font-size:12px;color:var(--t2);">—</div>'; return; }
    ul.innerHTML = list.map((u,i) => `
      <div class="adm-user-row" onclick="admQuickFill('${u.id}')">
        <div style="font-size:10px;color:var(--t3);width:16px;text-align:right;flex-shrink:0;">${i+1}</div>
        <div class="adm-user-av">${u.photoURL?`<img src="${escHtml(u.photoURL)}" style="width:100%;height:100%;object-fit:cover;border-radius:50%;" onerror="this.style.display='none'">`:((u.name||'?')[0].toUpperCase())}</div>
        <div class="adm-user-nm">${escHtml(u.name||'—')}</div>
        <div class="adm-user-ep">${(u.balance||0).toLocaleString()} EP</div>
      </div>`).join('');
  });
}

function loadAdmActivity() {
  const el = document.getElementById('adm-activity-list');
  if(!el) return;
  el.innerHTML='<div class="loading-center"><div class="spin spin-g"></div></div>';
  db.ref('scans').limitToLast(20).once('value', snap => {
    const items=[];
    snap.forEach(c=>items.unshift({key:c.key,...c.val()}));
    if(!items.length) { el.innerHTML='<div style="padding:14px;text-align:center;font-size:12px;color:var(--t2);">—</div>'; return; }
    el.innerHTML=items.map(item=>`
      <div class="adm-activity-item">
        <div class="adm-act-ico">♻️</div>
        <div class="adm-act-info">
          <div>QR Skan — <span style="color:var(--g1);font-weight:700;">+50 EP</span></div>
          <div class="adm-act-time">${item.uid?item.uid.slice(0,12)+'...':'—'} • ${new Date(item.ts||Date.now()).toLocaleString('az-AZ')}</div>
        </div>
      </div>`).join('');
  });
}

function admSearchUsers(query) {
  const ul = document.getElementById('adm-user-list');
  if(!ul) return;
  if(!query||query.length<2) { loadAdmUsers(); return; }
  ul.innerHTML='<div class="loading-center"><div class="spin spin-g"></div></div>';
  db.ref('users').orderByChild('name').startAt(query).endAt(query+'\uf8ff').limitToFirst(10).once('value', snap => {
    const list=[];
    snap.forEach(c=>list.push({id:c.key,...c.val()}));
    if(!list.length) { ul.innerHTML='<div style="padding:14px;text-align:center;font-size:12px;color:var(--t2);">—</div>'; return; }
    ul.innerHTML=list.map(u=>`
      <div class="adm-user-row" onclick="admQuickFill('${u.id}')">
        <div class="adm-user-av">${u.photoURL?`<img src="${escHtml(u.photoURL)}" style="width:100%;height:100%;object-fit:cover;" onerror="this.style.display='none'">`:((u.name||'?')[0].toUpperCase())}</div>
        <div class="adm-user-nm">${escHtml(u.name||'—')}</div>
        <div class="adm-user-ep">${(u.balance||0).toLocaleString()} EP</div>
      </div>`).join('');
  });
}

function admQuickFill(uid) {
  document.querySelectorAll('.adm-section.on .adm-in[id^="adm-uid"]').forEach(inp=>{inp.value=uid;});
  showToast('✅ UID seçildi','ok');
}

function adminBroadcast() {
  const msg   = document.getElementById('adm-broadcast-txt')?.value.trim();
  const title = document.getElementById('adm-broadcast-title')?.value.trim() || T('notifTitle');
  if(!msg) { showToast(T('sendAmtEnter'),'err'); return; }
  db.ref('globalNotifications').push({ title, body:msg, icon:'📢', ts:Date.now(), by:UID }).then(() => {
    const ok = document.getElementById('adm-broadcast-ok');
    if(ok) { ok.style.display='block'; setTimeout(()=>ok.style.display='none',3000); }
    document.getElementById('adm-broadcast-txt').value='';
    if(document.getElementById('adm-broadcast-title')) document.getElementById('adm-broadcast-title').value='';
  });
}

/* ═══════════════════════════════════════════════════════
   PROFILE LEVEL
   ═══════════════════════════════════════════════════════ */
const LEVELS = [
  { min:0,    name:{az:'Başlanğıc',en:'Beginner',ru:'Новичок',tr:'Başlangıç'},   badge:'🌱' },
  { min:500,  name:{az:'Ekoloji',en:'Eco',ru:'Эко',tr:'Eko'},                   badge:'♻️' },
  { min:2000, name:{az:'Yaşıl Döyüşçü',en:'Green Warrior',ru:'Зелёный воин',tr:'Yeşil Savaşçı'}, badge:'🌿' },
  { min:5000, name:{az:'Eko Qəhrəman',en:'Eco Hero',ru:'Эко герой',tr:'Eko Kahraman'}, badge:'🦸' },
  { min:10000,name:{az:'Planet Qoruyucusu',en:'Planet Guardian',ru:'Страж планеты',tr:'Gezegen Koruyucusu'}, badge:'🌍' },
  { min:25000,name:{az:'EcoPoint Ustası',en:'EcoPoint Master',ru:'Мастер EcoPoint',tr:'EcoPoint Ustası'}, badge:'👑' },
];

function updateProfileLevel(earned) {
  let cur = LEVELS[0], next = LEVELS[1];
  for(let i=0;i<LEVELS.length;i++) {
    if(earned >= LEVELS[i].min) { cur=LEVELS[i]; next=LEVELS[i+1]||null; }
  }
  const lName = cur.name[currentLang] || cur.name.az;
  const badge = document.getElementById('acc-level-badge');
  if(badge) badge.innerHTML = `<i class="fa-solid fa-star" style="font-size:8px;"></i> ${cur.badge} ${lName.toUpperCase()}`;
  const xpName = document.getElementById('xp-level-name'); if(xpName) xpName.textContent = lName;
  const xpTxt  = document.getElementById('xp-progress-txt');
  const xpBar  = document.getElementById('xp-bar-fill');
  if(next) {
    const pct = Math.round(((earned - cur.min) / (next.min - cur.min)) * 100);
    if(xpTxt) xpTxt.textContent = earned.toLocaleString()+' / '+next.min.toLocaleString()+' EP';
    if(xpBar) xpBar.style.width = pct + '%';
  } else {
    if(xpTxt) xpTxt.textContent = earned.toLocaleString()+' EP ✓ MAX';
    if(xpBar) xpBar.style.width = '100%';
  }
}

/* ═══════════════════════════════════════════════════════
   ECO IMPACT
   ═══════════════════════════════════════════════════════ */
function updateEcoImpact(scans) {
  const plastic = scans * 42;
  const co2     = scans * 85;
  const water   = scans * 3.2;
  const energy  = scans * 14;
  const animEl = (id, val) => {
    const el = document.getElementById(id); if(!el) return;
    const start = parseInt(el.textContent) || 0;
    const steps = 24; let s = 0;
    const iv = setInterval(() => {
      s++;
      el.textContent = Math.round(start + (val-start)*s/steps);
      if(s>=steps) { clearInterval(iv); el.textContent = val; }
    }, 30);
  };
  animEl('eco-plastic', plastic);
  animEl('eco-co2',     co2);
  animEl('eco-water',   Math.round(water));
  animEl('eco-energy',  energy);
}

/* ═══════════════════════════════════════════════════════
   CHALLENGES (Daily Missions)
   ═══════════════════════════════════════════════════════ */
const CHALLENGES_DEF = [
  { id:'scan3',  ico:'♻️', t:{az:'3 QR Skan et',en:'Scan 3 QR codes',ru:'Сканируй 3 QR',tr:'3 QR tara'}, s:{az:'Gündəlik skan tapşırığı',en:'Daily scan mission',ru:'Ежедневное задание',tr:'Günlük görev'}, ep:30, type:'scans', goal:3 },
  { id:'invite', ico:'🎯', t:{az:'1 Dost Dəvət et',en:'Invite 1 friend',ru:'Пригласи 1 друга',tr:'1 arkadaş davet et'}, s:{az:'+100 EP bonus',en:'+100 EP bonus',ru:'+100 EP бонус',tr:'+100 EP bonus'}, ep:100, type:'manual' },
  { id:'login2', ico:'🔥', t:{az:'2 Gün Ardıcıl Giriş',en:'Login 2 days in a row',ru:'Войди 2 дня подряд',tr:'2 gün üst üste giriş'}, s:{az:'Seriya bonusu',en:'Streak bonus',ru:'Бонус серии',tr:'Seri bonusu'}, ep:20, type:'streak', goal:2 },
  { id:'eco5',   ico:'🌿', t:{az:'5 Eko Hərəkət',en:'5 Eco Actions',ru:'5 экодействий',tr:'5 eko eylem'}, s:{az:'EP qazanın',en:'Earn EP',ru:'Зарабатывай EP',tr:'EP kazan'}, ep:50, type:'scans', goal:5 },
];

function renderChallenges() {
  const el = document.getElementById('challenges-list');
  if(!el) return;
  const streak = JSON.parse(localStorage.getItem('ep-streak')||'{"count":0}');
  el.innerHTML = CHALLENGES_DEF.map(ch => {
    let prog = 0, goal = ch.goal || 1, done = false;
    if(ch.type==='scans') { prog=Math.min(goal,stats.scans); done=prog>=goal; }
    else if(ch.type==='streak') { prog=Math.min(goal,streak.count||0); done=prog>=goal; }
    const pct = Math.round((prog/goal)*100);
    const t = ch.t[currentLang]||ch.t.az;
    const s = ch.s[currentLang]||ch.s.az;
    return `
    <div class="challenge-card${done?' done':''}">
      <div class="ch-ico">${ch.ico}</div>
      <div class="ch-info">
        <div class="ch-title">${t}</div>
        <div class="ch-desc">${s}</div>
        ${ch.goal ? `<div class="ch-prog"><div class="ch-prog-fill" style="width:${pct}%"></div></div>` : ''}
      </div>
      ${done
        ? `<div class="ch-done-ico">✅</div>`
        : `<div class="ch-ep">+${ch.ep} EP</div>`}
    </div>`;
  }).join('');
}

/* ═══════════════════════════════════════════════════════
   ACHIEVEMENTS
   ═══════════════════════════════════════════════════════ */
const ACHIEVEMENTS = [
  { id:'first_scan',  ico:'🌱', t:{az:'İlk Skan',en:'First Scan',ru:'Первый скан',tr:'İlk Tarama'}, d:{az:'İlk QR skanınız',en:'Your first QR scan',ru:'Ваш первый скан',tr:'İlk taramanız'}, cond:s=>s.scans>=1 },
  { id:'scan10',      ico:'♻️', t:{az:'10 Skan',en:'10 Scans',ru:'10 сканов',tr:'10 Tarama'}, d:{az:'10 QR skan edin',en:'Scan 10 QR codes',ru:'Сканируй 10 QR',tr:'10 QR tara'}, cond:s=>s.scans>=10 },
  { id:'scan50',      ico:'🔥', t:{az:'50 Skan',en:'50 Scans',ru:'50 сканов',tr:'50 Tarama'}, d:{az:'50 QR skan edin',en:'Scan 50 QR codes',ru:'50 QR',tr:'50 QR tara'}, cond:s=>s.scans>=50 },
  { id:'earned500',   ico:'💰', t:{az:'500 EP',en:'500 EP',ru:'500 EP',tr:'500 EP'}, d:{az:'500 EP qazanın',en:'Earn 500 EP',ru:'Заработай 500 EP',tr:'500 EP kazan'}, cond:s=>s.earned>=500 },
  { id:'earned5000',  ico:'🚀', t:{az:'5000 EP',en:'5000 EP',ru:'5000 EP',tr:'5000 EP'}, d:{az:'5000 EP qazanın',en:'Earn 5000 EP',ru:'Заработай 5000 EP',tr:'5000 EP kazan'}, cond:s=>s.earned>=5000 },
  { id:'sent1',       ico:'💸', t:{az:'İlk Köçürmə',en:'First Transfer',ru:'Первый перевод',tr:'İlk Transfer'}, d:{az:'EP göndərin',en:'Send EP',ru:'Отправь EP',tr:'EP gönder'}, cond:s=>s.sent>=1 },
  { id:'streak7',     ico:'🔥', t:{az:'7 Günlük Seriya',en:'7-day Streak',ru:'Серия 7 дней',tr:'7 Günlük Seri'}, d:{az:'7 gün ardıcıl',en:'7 days in a row',ru:'7 дней подряд',tr:'7 gün üst üste'}, cond:s=>s.streak>=7 },
  { id:'early',       ico:'🏅', t:{az:'Erkən Dəstəkçi',en:'Early Supporter',ru:'Ранний сторонник',tr:'Erken Destekçi'}, d:{az:'EcoPoint-ə ilk qoşulanlar',en:'First EcoPoint members',ru:'Первые участники',tr:'İlk katılanlar'}, cond:()=>true },
];

let unlockedAchs = JSON.parse(localStorage.getItem('ep-ach')||'[]');

function checkAchievements(stats) {
  const streak = JSON.parse(localStorage.getItem('ep-streak')||'{"count":0}');
  const enriched = {...stats, streak:streak.count||0};
  ACHIEVEMENTS.forEach(ach => {
    if(!unlockedAchs.includes(ach.id) && ach.cond(enriched)) {
      unlockedAchs.push(ach.id);
      localStorage.setItem('ep-ach', JSON.stringify(unlockedAchs));
      showAchievementUnlock(ach);
    }
  });
}

function showAchievementUnlock(ach) {
  const toast = document.getElementById('ach-unlock-toast');
  const ico   = document.getElementById('ach-unlock-ico');
  const nm    = document.getElementById('ach-unlock-nm');
  const ttl   = document.getElementById('ach-unlock-ttl-lbl');
  if(!toast) return;
  if(ico) ico.textContent = ach.ico;
  if(nm)  nm.textContent  = ach.t[currentLang]||ach.t.az;
  if(ttl) ttl.textContent = T('achUnlock');
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 3500);
}

/* ═══════════════════════════════════════════════════════
   STREAK
   ═══════════════════════════════════════════════════════ */
function updateStreak() {
  const today = new Date().toDateString();
  const stored = JSON.parse(localStorage.getItem('ep-streak')||'{"count":0,"lastDay":"","history":[]}');
  const yesterday = new Date(Date.now()-86400000).toDateString();
  if(stored.lastDay===today) {}
  else if(stored.lastDay===yesterday) { stored.count++; stored.lastDay=today; stored.history=[...(stored.history||[]).slice(-6),today]; }
  else { stored.count=1; stored.lastDay=today; stored.history=[today]; }
  localStorage.setItem('ep-streak', JSON.stringify(stored));
  renderStreak(stored);
  // Give streak bonus
  if(stored.count>0 && stored.count%7===0 && UID) {
    const bonusKey = 'ep-streak-bonus-'+stored.count;
    if(!localStorage.getItem(bonusKey)) {
      localStorage.setItem(bonusKey,'1');
      db.ref('users/'+UID+'/balance').transaction(c=>(c||0)+50);
      addTx('earn','+50','🔥 7 Günlük Seriya Bonusu');
      updStat('earned',50);
      showToast('🔥 7 Günlük Seriya! +50 EP','ok');
    }
  }
}

function renderStreak(data) {
  const card = document.getElementById('streak-card');
  if(!card||!UID) return;
  card.style.display='flex';
  const num  = document.getElementById('streak-num');
  const sub  = document.getElementById('streak-sub');
  const days = document.getElementById('streak-days');
  if(num) num.textContent = data.count;
  if(sub) {
    sub.textContent = data.count>=7 ? '🔥 '+T('streakLabel')+'!' :
                      data.count>=3 ? '⭐ '+T('streakDay')+'!' : 'Davam edən seriya';
  }
  if(days) {
    const dayNames = T('days');
    const today = new Date().getDay();
    days.innerHTML = Array(7).fill(0).map((_,i) => {
      const dayIdx = (today-6+i+7)%7;
      const isToday = i===6;
      const isDone  = data.history && data.history.length>(6-i);
      return `<div class="streak-day ${isToday?'today':isDone?'done':''}">${dayNames[dayIdx]}</div>`;
    }).join('');
  }
}

/* ═══════════════════════════════════════════════════════
   REFERRAL
   ═══════════════════════════════════════════════════════ */
function initReferral() {
  if(!UID) return;
  const code = 'EP'+UID.slice(0,6).toUpperCase();
  const codeEl = document.getElementById('ref-code-txt');
  if(codeEl) codeEl.textContent = code;
  db.ref('users/'+UID+'/referralCode').set(code);
  document.getElementById('ref-card').style.display = 'block';
  // Check if came via referral
  const urlRef = new URLSearchParams(window.location.search).get('ref');
  if(urlRef && urlRef!==code && !localStorage.getItem('ep-ref-used')) {
    localStorage.setItem('ep-ref-used','1');
    db.ref('users/'+UID+'/balance').transaction(c=>(c||0)+200);
    addTx('earn','+200','🎯 Referral bonusu');
    updStat('earned',200);
    showToast(T('refBonus'),'ok');
  }
}

function copyReferral() {
  if(!UID) return;
  const code = 'EP'+UID.slice(0,6).toUpperCase();
  const url = window.location.href.split('?')[0]+'?ref='+code;
  if(navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(url).then(()=>showToast(T('refCopied'),'ok'));
  } else {
    const el=document.createElement('textarea'); el.value=url;
    document.body.appendChild(el); el.select(); document.execCommand('copy'); document.body.removeChild(el);
    showToast(T('refCopied'),'ok');
  }
}

/* ═══════════════════════════════════════════════════════
   NOTIFICATIONS
   ═══════════════════════════════════════════════════════ */

function loadNotifications() {
  const list = document.getElementById('notif-list');
  if(!list) return;
  list.innerHTML='<div class="loading-center"><div class="spin spin-g"></div></div>';
  db.ref('globalNotifications').orderByChild('ts').limitToLast(20).once('value', snap => {
    const items=[];
    snap.forEach(c=>items.unshift({id:c.key,...c.val()}));
    const userPromise = UID ? db.ref('users/'+UID+'/notifications').orderByChild('ts').limitToLast(10).once('value') : Promise.resolve(null);
    userPromise.then(uSnap => {
      const userItems=[];
      if(uSnap) uSnap.forEach(c=>userItems.unshift({id:c.key,...c.val(),personal:true}));
      const all = [...userItems,...items].sort((a,b)=>(b.ts||0)-(a.ts||0)).slice(0,15);
      if(!all.length) {
        list.innerHTML=`<div class="notif-item"><div class="notif-ico">🌿</div><div style="flex:1;"><div class="notif-body-t">${T('notifWelcomeT')}</div><div class="notif-body-s">${T('notifWelcomeS')}</div><div class="notif-time">İndi</div></div></div>`;
        return;
      }
      list.innerHTML=all.map(n=>`
        <div class="notif-item${n.personal?' notif-personal':''}">
          <div class="notif-ico">${n.icon||(n.personal?'👤':'📢')}</div>
          <div style="flex:1;">
            <div class="notif-body-t">${escHtml(n.title||n.text||T('notifTitle'))}</div>
            <div class="notif-body-s">${escHtml(n.body||n.desc||'')}</div>
            <div class="notif-time">${n.ts?formatNotifTime(n.ts):'İndi'}</div>
          </div>
        </div>`).join('');
    });
  });
}

function formatNotifTime(ts) {
  const diff = Math.floor((Date.now()-ts)/1000);
  if(diff<60)    return diff+' san';
  if(diff<3600)  return Math.floor(diff/60)+' dəq';
  if(diff<86400) return Math.floor(diff/3600)+' saat';
  return Math.floor(diff/86400)+' gün';
}

function checkNotifDot() {
  if(!UID) return;
  db.ref('globalNotifications').orderByChild('ts').limitToLast(1).once('value', snap => {
    if(!snap.exists()) return;
    const lastSeen = parseInt(localStorage.getItem('ep-notif-seen')||'0');
    let hasNew=false;
    snap.forEach(c=>{ if((c.val().ts||0)>lastSeen) hasNew=true; });
    if(hasNew) {
      const pip=document.getElementById('notif-pip'); if(pip) pip.style.display='block';
      const d1=document.getElementById('dsb-notif-dot'); if(d1) d1.style.display='block';
      const d2=document.getElementById('dtb-notif-dot'); if(d2) d2.style.display='block';
    }
  });
}

/* ═══════════════════════════════════════════════════════
   THEME SYSTEM
   ═══════════════════════════════════════════════════════ */
function setTheme(theme) {
  document.body.classList.remove('light','theme-neon','theme-ocean');
  if(theme==='light') document.body.classList.add('light');
  else if(theme==='neon') document.body.classList.add('theme-neon');
  else if(theme==='ocean') document.body.classList.add('theme-ocean');
  localStorage.setItem('ep-theme', theme);
  showToast('🎨 '+theme,'ok');
}
function toggleTheme() {
  const cur = localStorage.getItem('ep-theme')||'dark';
  setTheme(cur==='dark'?'light':'dark');
}
// Restore theme
const savedTheme = localStorage.getItem('ep-theme');
if(savedTheme) setTheme(savedTheme);

/* ═══════════════════════════════════════════════════════
   ABOUT US
   ═══════════════════════════════════════════════════════ */
// openAboutUs — aşağıda təyin edilib

/* ═══════════════════════════════════════════════════════
   HELPERS
   ═══════════════════════════════════════════════════════ */
function copyUid() {
  if(!UID) return;
  const copy=()=>{const el=document.createElement('textarea');el.value=UID;document.body.appendChild(el);el.select();document.execCommand('copy');document.body.removeChild(el);};
  if(navigator.clipboard?.writeText) navigator.clipboard.writeText(UID).then(()=>showToast(T('uidCopied'),'ok')).catch(copy);
  else{copy();showToast(T('uidCopied'),'ok');}
}

function shareApp() {
  const data = { title:'EcoPoint Pro', text:'🌿 '+T('acc-tagline'), url:window.location.href };
  if(navigator.share) navigator.share(data).catch(()=>{});
  else if(navigator.clipboard?.writeText) navigator.clipboard.writeText(window.location.href).then(()=>showToast(T('linkCopied'),'ok'));
}

function closeOv(id) {
  const el = document.getElementById(id);
  if(el) el.classList.remove('open');
}

function openAboutUs() { document.getElementById('ov-aboutus').classList.add('open'); }

function openNotifPanel() {
  document.getElementById('notif-panel').classList.add('open');
  document.getElementById('notif-pip').style.display='none';
  const d1=document.getElementById('dsb-notif-dot'); if(d1) d1.style.display='none';
  const d2=document.getElementById('dtb-notif-dot'); if(d2) d2.style.display='none';
  localStorage.setItem('ep-notif-seen', Date.now());
  loadNotifications();
}
function closeNotifPanel() { document.getElementById('notif-panel').classList.remove('open'); }

function openAchievements() {
  document.getElementById('achievements-overlay').classList.add('open');
  const body = document.getElementById('ach-body');
  if(!body) return;
  body.innerHTML = ACHIEVEMENTS.map(ach => {
    const unlocked = unlockedAchs.includes(ach.id);
    return `<div class="ach-item${unlocked?' unlocked':''}">
      <div class="ach-ico">${ach.ico}</div>
      <div class="ach-nm">${ach.t[currentLang]||ach.t.az}</div>
      <div class="ach-desc">${ach.d[currentLang]||ach.d.az}</div>
      ${!unlocked?`<div class="ach-locked">🔒</div>`:'<div style="font-size:10px;color:var(--g1);margin-top:4px;">✅</div>'}
    </div>`;
  }).join('');
}
function closeAchievements() { document.getElementById('achievements-overlay').classList.remove('open'); }

// Overlay backdrop close — HTML-də onclick ilə idarə olunur

function escHtml(str) {
  return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

/* ═══════════════════════════════════════════════════════
   TOAST & ANIMATIONS
   ═══════════════════════════════════════════════════════ */
let toastTimer;
function showToast(msg, type='') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = 'vis'+(type?' '+type:'');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(()=>t.className='', type==='err'?3500:2800);
}

function countUp(id, target) {
  const el = document.getElementById(id); if(!el) return;
  const cur = parseInt(el.textContent.replace(/,/g,''))||0;
  if(cur===target){el.textContent=target.toLocaleString();return;}
  const diff=target-cur, steps=28; let step=0;
  const iv=setInterval(()=>{step++;el.textContent=Math.round(cur+diff*step/steps).toLocaleString();if(step>=steps){clearInterval(iv);el.textContent=target.toLocaleString();}},14);
}

function epPopup(pts) {
  const pop = document.getElementById('ep-popup');
  const num = document.getElementById('ep-popup-num');
  if(!pop) return;
  if(num) num.textContent = '+'+pts;
  pop.classList.add('show');
  setTimeout(()=>pop.classList.remove('show'), 2000);
}

function triggerScanRipple() {
  const el=document.getElementById('scan-ripple'); if(!el) return;
  el.classList.remove('animate');
  void el.offsetWidth;
  el.classList.add('animate');
  setTimeout(()=>el.classList.remove('animate'),900);
}

/* ═══════════════════════════════════════════════════════
   CONFETTI
   ═══════════════════════════════════════════════════════ */
function launchConfetti() {
  const canvas = document.getElementById('confetti-canvas');
  if(!canvas) return;
  const ctx = canvas.getContext('2d');
  canvas.width=window.innerWidth; canvas.height=window.innerHeight;
  const particles=[];
  const colors=['#00ff7a','#00e5cc','#ffa502','#4cc9f0','#ff4757'];
  for(let i=0;i<120;i++) particles.push({ x:Math.random()*canvas.width, y:Math.random()*canvas.height-canvas.height, w:Math.random()*10+4, h:Math.random()*6+3, color:colors[Math.floor(Math.random()*colors.length)], vy:Math.random()*4+2, vx:(Math.random()-0.5)*3, rot:Math.random()*360, rotV:Math.random()*6-3 });
  let frame=0;
  const animate=()=>{
    ctx.clearRect(0,0,canvas.width,canvas.height);
    particles.forEach(p=>{p.y+=p.vy;p.x+=p.vx;p.rot+=p.rotV;ctx.save();ctx.translate(p.x,p.y);ctx.rotate(p.rot*Math.PI/180);ctx.fillStyle=p.color;ctx.globalAlpha=Math.max(0,1-frame/90);ctx.fillRect(-p.w/2,-p.h/2,p.w,p.h);ctx.restore();});
    frame++;
    if(frame<100) requestAnimationFrame(animate);
    else ctx.clearRect(0,0,canvas.width,canvas.height);
  };
  animate();
}

/* ═══════════════════════════════════════════════════════
   PWA
   ═══════════════════════════════════════════════════════ */
window.addEventListener('beforeinstallprompt', e=>{
  e.preventDefault(); deferredPrompt=e;
  document.getElementById('install-strip').style.display='flex';
});
function doInstall() {
  if(!deferredPrompt) return;
  deferredPrompt.prompt();
  deferredPrompt.userChoice.then(()=>{ deferredPrompt=null; document.getElementById('install-strip').style.display='none'; });
}
window.addEventListener('appinstalled',()=>{ document.getElementById('install-strip').style.display='none'; showToast(T('appInstalled'),'ok'); });
if('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(()=>{});

/* ═══════════════════════════════════════════════════════
   KEYBOARD / BIO
   ═══════════════════════════════════════════════════════ */
document.addEventListener('keydown', e=>{
  if(e.key==='Escape') { closeOv('ov-send');closeOv('ov-buy');closeScanner();closeMyQR();closeNotifPanel();closeLangQuick(); }
});
document.getElementById('s-amt').addEventListener('keydown',e=>{ if(e.key==='Enter') doSend(); });

function editBio() {
  if(!UID) return;
  const cur = document.getElementById('acc-bio-txt')?.textContent;
  const newBio = prompt(T('bioPlaceholder'), cur===T('bioPlaceholder')? '' : cur);
  if(newBio===null) return;
  db.ref('users/'+UID+'/bio').set(newBio);
  const bioEl = document.getElementById('acc-bio-txt');
  if(bioEl) { bioEl.textContent = newBio||T('bioPlaceholder'); bioEl.classList.toggle('filled',!!newBio); }
}

/* ═══════════════════════════════════════════════════════
   DESKTOP LAYOUT INIT
   ═══════════════════════════════════════════════════════ */
function initDesktopLayout() {
  const isDesktop = window.innerWidth >= 1024;
  const sb = document.querySelector('.desktop-sidebar');
  const tb = document.getElementById('desktop-topbar');
  if(sb) sb.style.display = isDesktop ? 'flex' : 'none';
  if(tb) tb.style.display = isDesktop ? 'flex' : 'none';
}
initDesktopLayout();
window.addEventListener('resize', initDesktopLayout);

/* ═══════════════════════════════════════════════════════
   FLOATING LEAVES
   ═══════════════════════════════════════════════════════ */
function spawnLeaf() {
  const leaves=['🌿','♻️','🌱','🍃'];
  const leaf=document.createElement('div');
  leaf.textContent=leaves[Math.floor(Math.random()*leaves.length)];
  leaf.style.cssText=`position:fixed;bottom:-40px;left:${Math.random()*100}vw;font-size:${14+Math.random()*10}px;opacity:0;z-index:1;pointer-events:none;animation:floatLeaf ${7+Math.random()*5}s linear forwards;`;
  document.body.appendChild(leaf);
  setTimeout(()=>leaf.remove(),14000);
}
setInterval(()=>{ if(Math.random()>0.6) spawnLeaf(); },5000);

/* ═══════════════════════════════════════════════════════
   BOOT
   ═══════════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', () => {
  // Apply translations first
  applyTranslations();
  renderChallenges();
  updateEcoImpact(0);
  loadBinList();
});
// Also apply immediately (for elements already in DOM)
applyTranslations();

import 'reward.dart';

/// The reward catalog that shipped hard-coded in the legacy web app
/// (`ITEMS` in app.js). It is used as a fallback only when `rewards/` is empty
/// in the database; purchases are always priced by the *server's* catalog
/// (the Cloud Functions embed the same list in `src/catalog.ts`).
///
/// Availability (stock) was never modelled in the legacy app, so none is
/// invented here.
abstract final class RewardCatalog {
  static Reward _i(
    String id,
    String az,
    String en,
    String ru,
    String tr,
    String brand,
    int ep,
    RewardCategory cat,
    String icon,
  ) =>
      Reward(
        id: id,
        names: {'az': az, 'en': en, 'ru': ru, 'tr': tr},
        brand: brand,
        ep: ep,
        category: cat,
        iconKey: icon,
      );

  static final List<Reward> builtIn = <Reward>[
    _i('p1', 'Şəkərsiz Çay', 'Sugar-free Tea', 'Чай без сахара',
        'Şekersiz Çay', 'EcoCafe', 150, RewardCategory.food, 'tea'),
    _i('p2', 'Üzvi Meyvə Paketi', 'Organic Fruit Pack',
        'Органические фрукты', 'Organik Meyve', 'GreenMarket', 300,
        RewardCategory.food, 'fruit'),
    _i('p3', 'Enerji İçki', 'Energy Drink', 'Энергетик', 'Enerji İçeceği',
        'GreenBoost', 100, RewardCategory.food, 'drink'),
    _i('p4', 'Plov Porsiyası', 'Pilaf Portion', 'Плов', 'Pilav Porsiyonu',
        'Novruz Çayxana', 400, RewardCategory.food, 'meal'),
    _i('p16', 'Kombucha İçki', 'Kombucha Drink', 'Чайный гриб',
        'Kombucha İçeceği', 'FermentBaku', 220, RewardCategory.food,
        'kombucha'),
    _i('p5', 'USB Günəş Şarjı', 'Solar USB Charger',
        'Солнечное зарядное', 'Güneş USB Şarj', 'SolarTech', 1200,
        RewardCategory.tech, 'solar'),
    _i('p6', 'Eko Qulaqlıq', 'Eco Headphones', 'Эко наушники',
        'Eko Kulaklık', 'EcoSound', 900, RewardCategory.tech, 'headphones'),
    _i('p7', 'Smart Tracker', 'Smart Tracker', 'Смарт трекер',
        'Akıllı Takip', 'GreenTech', 1800, RewardCategory.tech, 'tracker'),
    _i('p8', 'Wireless Şarj', 'Wireless Charger', 'Беспроводная зарядка',
        'Kablosuz Şarj', 'SolarTech', 1500, RewardCategory.tech, 'charger'),
    _i('p9', 'Bambu Dişfırçası', 'Bamboo Toothbrush', 'Бамбуковая щётка',
        'Bambu Diş Fırçası', 'EcoLife', 200, RewardCategory.eco,
        'toothbrush'),
    _i('p10', 'Bərpaolunan Torba', 'Reusable Bag', 'Многоразовая сумка',
        'Yeniden Kullanımlı Çanta', 'GreenBag', 250, RewardCategory.eco,
        'bag'),
    _i('p11', 'Eko Termos', 'Eco Thermos', 'Эко термос', 'Eko Termos',
        'EcoLife', 600, RewardCategory.eco, 'thermos'),
    _i('p12', 'Eko Sabun Dəsti', 'Eco Soap Set', 'Эко набор мыла',
        'Eko Sabun Seti', 'NaturePure', 180, RewardCategory.eco, 'soap'),
    _i('p13', 'Avtobus Kartı', 'Bus Card', 'Карта автобуса',
        'Otobüs Kartı', 'BakuBus', 500, RewardCategory.service, 'bus'),
    _i('p14', 'Kino Bileti', 'Cinema Ticket', 'Билет в кино',
        'Sinema Bileti', 'CinePlex', 800, RewardCategory.service, 'cinema'),
    _i('p15', 'Kitabxana Aylığı', 'Library Monthly',
        'Абонемент библиотеки', 'Kütüphane Aboneliği', 'BakuLib', 350,
        RewardCategory.service, 'library'),
    const Reward(
      id: 'c1',
      names: {
        'az': 'Bravo Kuponu',
        'en': 'Bravo Coupon',
        'ru': 'Купон Bravo',
        'tr': 'Bravo Kuponu',
      },
      brand: 'Bravo',
      ep: 500,
      category: RewardCategory.service,
      iconKey: 'cart',
      kind: RewardKind.coupon,
      partnerId: 'bravo',
    ),
    const Reward(
      id: 'c2',
      names: {
        'az': 'Bolmart Kuponu',
        'en': 'Bolmart Coupon',
        'ru': 'Купон Bolmart',
        'tr': 'Bolmart Kuponu',
      },
      brand: 'Bolmart',
      ep: 300,
      category: RewardCategory.service,
      iconKey: 'store',
      kind: RewardKind.coupon,
      partnerId: 'bolmart',
    ),
    const Reward(
      id: 't1',
      names: {
        'az': 'BakıKart Doldur',
        'en': 'Top Up BakiCard',
        'ru': 'Пополнить BakiCard',
        'tr': 'BakiCard Yükle',
      },
      brand: 'BakuBus',
      ep: 100,
      category: RewardCategory.service,
      iconKey: 'bus',
      kind: RewardKind.transport,
    ),
  ];
}

/// Coupon partner terms (from the legacy MarketplaceModule).
class CouponPartner {
  const CouponPartner({
    required this.id,
    required this.name,
    required this.minEp,
    required this.commissionPercent,
    this.epPerAzn = 500,
  });

  final String id;
  final String name;
  final int minEp;
  final int commissionPercent;
  final int epPerAzn;

  static const Map<String, CouponPartner> all = {
    'bravo': CouponPartner(
        id: 'bravo', name: 'Bravo', minEp: 500, commissionPercent: 5),
    'bolmart': CouponPartner(
        id: 'bolmart', name: 'Bolmart', minEp: 300, commissionPercent: 5),
  };

  /// Commission in EP, rounded like the legacy `Math.round`.
  int feeFor(int ep) => (ep * commissionPercent / 100).round();

  /// AZN value after commission (display only; server is authoritative).
  double aznFor(int ep) => (ep - feeFor(ep)) / epPerAzn;
}

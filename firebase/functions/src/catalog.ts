import type { PartnerId } from './lib/config';

export type RewardKind = 'item' | 'coupon' | 'transport';

export interface CatalogItem {
  id: string;
  name: { az: string; en: string; ru: string; tr: string };
  brand: string;
  ep: number;
  cat: 'food' | 'tech' | 'eco' | 'service';
  icon: string;
  kind: RewardKind;
  partnerId?: PartnerId;
  /** `undefined` = unlimited. */
  stock?: number;
  active: boolean;
}

function item(
  id: string,
  az: string,
  en: string,
  ru: string,
  tr: string,
  brand: string,
  ep: number,
  cat: CatalogItem['cat'],
  icon: string,
): CatalogItem {
  return { id, name: { az, en, ru, tr }, brand, ep, cat, icon, kind: 'item', active: true };
}

/**
 * The catalog that shipped hard-coded in the legacy web app. It is used to
 * (a) seed `rewards/` (see ../seed/rewards.json) and (b) price purchases when
 * `rewards/` is empty. Mirrors `RewardCatalog.builtIn` in the Flutter app.
 */
export const BUILT_IN_CATALOG: CatalogItem[] = [
  item('p1', 'Şəkərsiz Çay', 'Sugar-free Tea', 'Чай без сахара', 'Şekersiz Çay', 'EcoCafe', 150, 'food', 'tea'),
  item('p2', 'Üzvi Meyvə Paketi', 'Organic Fruit Pack', 'Органические фрукты', 'Organik Meyve', 'GreenMarket', 300, 'food', 'fruit'),
  item('p3', 'Enerji İçki', 'Energy Drink', 'Энергетик', 'Enerji İçeceği', 'GreenBoost', 100, 'food', 'drink'),
  item('p4', 'Plov Porsiyası', 'Pilaf Portion', 'Плов', 'Pilav Porsiyonu', 'Novruz Çayxana', 400, 'food', 'meal'),
  item('p16', 'Kombucha İçki', 'Kombucha Drink', 'Чайный гриб', 'Kombucha İçeceği', 'FermentBaku', 220, 'food', 'kombucha'),
  item('p5', 'USB Günəş Şarjı', 'Solar USB Charger', 'Солнечное зарядное', 'Güneş USB Şarj', 'SolarTech', 1200, 'tech', 'solar'),
  item('p6', 'Eko Qulaqlıq', 'Eco Headphones', 'Эко наушники', 'Eko Kulaklık', 'EcoSound', 900, 'tech', 'headphones'),
  item('p7', 'Smart Tracker', 'Smart Tracker', 'Смарт трекер', 'Akıllı Takip', 'GreenTech', 1800, 'tech', 'tracker'),
  item('p8', 'Wireless Şarj', 'Wireless Charger', 'Беспроводная зарядка', 'Kablosuz Şarj', 'SolarTech', 1500, 'tech', 'charger'),
  item('p9', 'Bambu Dişfırçası', 'Bamboo Toothbrush', 'Бамбуковая щётка', 'Bambu Diş Fırçası', 'EcoLife', 200, 'eco', 'toothbrush'),
  item('p10', 'Bərpaolunan Torba', 'Reusable Bag', 'Многоразовая сумка', 'Yeniden Kullanımlı Çanta', 'GreenBag', 250, 'eco', 'bag'),
  item('p11', 'Eko Termos', 'Eco Thermos', 'Эко термос', 'Eko Termos', 'EcoLife', 600, 'eco', 'thermos'),
  item('p12', 'Eko Sabun Dəsti', 'Eco Soap Set', 'Эко набор мыла', 'Eko Sabun Seti', 'NaturePure', 180, 'eco', 'soap'),
  item('p13', 'Avtobus Kartı', 'Bus Card', 'Карта автобуса', 'Otobüs Kartı', 'BakuBus', 500, 'service', 'bus'),
  item('p14', 'Kino Bileti', 'Cinema Ticket', 'Билет в кино', 'Sinema Bileti', 'CinePlex', 800, 'service', 'cinema'),
  item('p15', 'Kitabxana Aylığı', 'Library Monthly', 'Абонемент библиотеки', 'Kütüphane Aboneliği', 'BakuLib', 350, 'service', 'library'),
  {
    id: 'c1',
    name: { az: 'Bravo Kuponu', en: 'Bravo Coupon', ru: 'Купон Bravo', tr: 'Bravo Kuponu' },
    brand: 'Bravo', ep: 500, cat: 'service', icon: 'cart', kind: 'coupon', partnerId: 'bravo', active: true,
  },
  {
    id: 'c2',
    name: { az: 'Bolmart Kuponu', en: 'Bolmart Coupon', ru: 'Купон Bolmart', tr: 'Bolmart Kuponu' },
    brand: 'Bolmart', ep: 300, cat: 'service', icon: 'store', kind: 'coupon', partnerId: 'bolmart', active: true,
  },
  {
    id: 't1',
    name: { az: 'BakıKart Doldur', en: 'Top Up BakiCard', ru: 'Пополнить BakiCard', tr: 'BakiCard Yükle' },
    brand: 'BakuBus', ep: 100, cat: 'service', icon: 'bus', kind: 'transport', active: true,
  },
];

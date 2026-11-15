/// Katalogo ng mga produktong karaniwang ibinebenta sa mga tindahan.
/// Ginagamit ng owner para mabilis mag-set up: pumili sa listahan, may
/// larawan, pangalan at packaging na agad, tapos presyo at stock na lang
/// ang ilalagay. (Galing sa Agri_products_for_4_store.xlsx.)
class CatalogItem {
  final String name;
  final String category; // hal. "Fertilizer", "Rice seeds"
  final String packaging; // hal. "50kg sack"
  const CatalogItem(this.name, this.category, this.packaging);

  /// Katumbas na unit sa product form ng owner (kg, sack, liter, piece).
  String get unit {
    final p = packaging.toLowerCase();
    if (p.contains('sack')) return 'sack';
    if (p.contains('liter')) return 'liter';
    if (RegExp(r'\dkg').hasMatch(p)) return 'kg';
    return 'piece';
  }
}

const productCatalog = [
  CatalogItem('Urea 46-0-0 Fertilizer', 'Fertilizer', '50kg sack'),
  CatalogItem('Complete 14-14-14 Fertilizer', 'Fertilizer', '50kg sack'),
  CatalogItem('DAP 18-46-0 Fertilizer', 'Fertilizer', '50kg sack'),
  CatalogItem('Muriate of Potash (MOP) 0-0-60', 'Fertilizer', '50kg sack'),
  CatalogItem('Solophos 0-18-0 Fertilizer', 'Fertilizer', '50kg sack'),
  CatalogItem('NPK 14-14-14 Fertilizer', 'Fertilizer', '50kg sack'),
  CatalogItem('NSIC Rc 222 Rice Seeds', 'Rice seeds', '20kg sack'),
  CatalogItem('NSIC Rc 160 Rice Seeds', 'Rice seeds', '20kg sack'),
  CatalogItem('NSIC Rc 216 Rice Seeds', 'Rice seeds', '20kg sack'),
  CatalogItem('NSIC Rc 402 Rice Seeds', 'Rice seeds', '20kg sack'),
  CatalogItem('Tomato Seeds', 'Vegetable seeds', '10g pack'),
  CatalogItem('Eggplant Seeds', 'Vegetable seeds', '10g pack'),
  CatalogItem('Ammonium Sulfate 21-0-0', 'Fertilizer', '50kg sack'),
  CatalogItem('Zinc Sulfate', 'Fertilizer', '1kg pack'),
  CatalogItem('Agricultural Lime', 'Fertilizer / soil amendment', '50kg sack'),
  CatalogItem('Humic Acid Liquid Fertilizer', 'Fertilizer', '1 liter bottle'),
  CatalogItem('Hybrid Rice Seeds', 'Rice seeds', '5kg pack'),
  CatalogItem('NSIC Rc 300 Rice Seeds', 'Rice seeds', '20kg sack'),
  CatalogItem('Pechay Seeds', 'Vegetable seeds', '10g pack'),
  CatalogItem('Squash Seeds', 'Vegetable seeds', '10g pack'),
  CatalogItem('Potassium Sulfate 0-0-50', 'Fertilizer', '50kg sack'),
  CatalogItem('Calcium Nitrate', 'Fertilizer', '25kg sack'),
  CatalogItem('Boron Fertilizer', 'Fertilizer', '1kg pack'),
  CatalogItem('NSIC Rc 124 Rice Seeds', 'Rice seeds', '20kg sack'),
  CatalogItem('Cucumber Seeds', 'Vegetable seeds', '10g pack'),
  CatalogItem('Magnesium Sulfate', 'Fertilizer', '1kg pack'),
  CatalogItem('Organic Compost', 'Fertilizer / soil amendment', '25kg sack'),
  CatalogItem('Watermelon Seeds', 'Vegetable seeds', '10g pack'),
  CatalogItem('Vermicast', 'Fertilizer / soil amendment', '25kg sack'),
];

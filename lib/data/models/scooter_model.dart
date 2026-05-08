class ScooterModel {
  const ScooterModel({
    required this.id,
    required this.brand,
    required this.name,
    required this.displacementCc,
    this.description,
    this.communityCreated = false,
  });

  final String id;
  final String brand;
  final String name;
  final int displacementCc;
  final String? description;
  final bool communityCreated;

  String get label => '$brand $name';
  String get ccLabel => '${displacementCc}cc';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'brandLower': brand.toLowerCase(),
      'name': name,
      'nameLower': name.toLowerCase(),
      'displacementCc': displacementCc,
      'description': description,
      'communityCreated': communityCreated,
      'label': label,
    };
  }

  factory ScooterModel.fromMap(Map<String, dynamic> map) {
    return ScooterModel(
      id: (map['id'] as String?) ?? '',
      brand: (map['brand'] as String?) ?? 'Motorcycle',
      name: (map['name'] as String?) ?? 'Custom model',
      displacementCc: (map['displacementCc'] as num?)?.toInt() ?? 0,
      description: map['description'] as String?,
      communityCreated: (map['communityCreated'] as bool?) ?? true,
    );
  }
}

class ScooterCatalog {
  const ScooterCatalog._();

  static const List<ScooterModel> models = [
    ScooterModel(
      id: 'honda-beat-110',
      brand: 'Honda',
      name: 'BeAT',
      displacementCc: 110,
    ),
    ScooterModel(
      id: 'honda-click-125',
      brand: 'Honda',
      name: 'Click 125',
      displacementCc: 125,
    ),
    ScooterModel(
      id: 'honda-click-160',
      brand: 'Honda',
      name: 'Click 160',
      displacementCc: 157,
    ),
    ScooterModel(
      id: 'honda-airblade-160',
      brand: 'Honda',
      name: 'AirBlade 160',
      displacementCc: 157,
    ),
    ScooterModel(
      id: 'honda-pcx-160',
      brand: 'Honda',
      name: 'PCX 160',
      displacementCc: 157,
    ),
    ScooterModel(
      id: 'honda-adv-160',
      brand: 'Honda',
      name: 'ADV 160',
      displacementCc: 157,
    ),
    ScooterModel(
      id: 'yamaha-mio-sporty-115',
      brand: 'Yamaha',
      name: 'Mio Sporty',
      displacementCc: 115,
    ),
    ScooterModel(
      id: 'yamaha-mio-i-125',
      brand: 'Yamaha',
      name: 'Mio i 125',
      displacementCc: 125,
    ),
    ScooterModel(
      id: 'yamaha-mio-gear-125',
      brand: 'Yamaha',
      name: 'Mio Gear',
      displacementCc: 125,
    ),
    ScooterModel(
      id: 'yamaha-mio-gravis-125',
      brand: 'Yamaha',
      name: 'Mio Gravis',
      displacementCc: 125,
    ),
    ScooterModel(
      id: 'yamaha-mio-fazzio-125',
      brand: 'Yamaha',
      name: 'Mio Fazzio',
      displacementCc: 125,
    ),
    ScooterModel(
      id: 'yamaha-lexi-155',
      brand: 'Yamaha',
      name: 'Lexi',
      displacementCc: 155,
    ),
    ScooterModel(
      id: 'yamaha-nmax-155',
      brand: 'Yamaha',
      name: 'NMAX',
      displacementCc: 155,
    ),
    ScooterModel(
      id: 'yamaha-aerox-155',
      brand: 'Yamaha',
      name: 'Aerox',
      displacementCc: 155,
    ),
  ];

  static const ScooterModel defaultModel = ScooterModel(
    id: 'honda-beat-110',
    brand: 'Honda',
    name: 'BeAT',
    displacementCc: 110,
  );

  static ScooterModel? findById(String? id, {List<ScooterModel>? models}) {
    if (id == null || id.trim().isEmpty) {
      return null;
    }
    for (final model in models ?? ScooterCatalog.models) {
      if (model.id == id) {
        return model;
      }
    }
    return null;
  }

  static List<ScooterModel> byBrand(
    String brand, {
    List<ScooterModel>? models,
  }) {
    return (models ?? ScooterCatalog.models)
        .where((model) => model.brand == brand)
        .toList();
  }

  static List<ScooterModel> mergeWith(List<ScooterModel> communityModels) {
    final byId = {
      for (final model in models) model.id: model,
      for (final model in communityModels) model.id: model,
    };
    final merged = byId.values.toList()
      ..sort((a, b) {
        final brandCompare = a.brand.toLowerCase().compareTo(
          b.brand.toLowerCase(),
        );
        if (brandCompare != 0) {
          return brandCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return merged;
  }

  static String idFor({
    required String brand,
    required String name,
    required int displacementCc,
  }) {
    final slug = '$brand-$name-$displacementCc'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'custom-motorcycle-$displacementCc' : slug;
  }
}

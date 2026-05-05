// lib/models/nutrition_model.dart

class NutrientValue {
  final double value;
  final String unit;
  const NutrientValue({this.value = 0.0, this.unit = ''});

  factory NutrientValue.fromJson(Map<String, dynamic> json) {
    return NutrientValue(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
    );
  }
}

class Nutrients {
  final NutrientValue calories;
  final NutrientValue fat;
  final NutrientValue sugar;
  final NutrientValue protein;
  final NutrientValue salt;

  const Nutrients({
    this.calories = const NutrientValue(value: 0, unit: 'kcal'),
    this.fat = const NutrientValue(value: 0, unit: 'g'),
    this.sugar = const NutrientValue(value: 0, unit: 'g'),
    this.protein = const NutrientValue(value: 0, unit: 'g'),
    this.salt = const NutrientValue(value: 0, unit: 'mg'),
  });

  factory Nutrients.fromJson(Map<String, dynamic> json) {
    return Nutrients(
      calories: NutrientValue.fromJson(
          json['calories'] as Map<String, dynamic>? ?? {}),
      fat: NutrientValue.fromJson(json['fat'] as Map<String, dynamic>? ?? {}),
      sugar:
          NutrientValue.fromJson(json['sugar'] as Map<String, dynamic>? ?? {}),
      protein: NutrientValue.fromJson(
          json['protein'] as Map<String, dynamic>? ?? {}),
      salt: NutrientValue.fromJson(json['salt'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class NutritionModel {
  final String foodName;
  final String servingSize;
  final Nutrients nutrients;
  final int healthRating;
  final String healthierNote;

  const NutritionModel({
    this.foodName = '',
    this.servingSize = '',
    this.nutrients = const Nutrients(),
    this.healthRating = 3,
    this.healthierNote = '',
  });

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    return NutritionModel(
      foodName: json['food_name'] as String? ?? '',
      servingSize: json['serving_size'] as String? ?? '',
      nutrients:
          Nutrients.fromJson(json['nutrients'] as Map<String, dynamic>? ?? {}),
      healthRating: (json['health_rating'] as num?)?.toInt() ?? 3,
      healthierNote: json['healthier_note'] as String? ?? '',
    );
  }

  bool get meetsSpec2 {
    final n = nutrients;
    return [
          n.calories.value,
          n.fat.value,
          n.sugar.value,
          n.protein.value,
          n.salt.value
        ].where((v) => v > 0).length >=
        3;
  }

  String get healthLabel {
    if (healthRating <= 2) return 'Kurang Sehat';
    if (healthRating == 3) return 'Cukup Sehat';
    return 'Sehat';
  }
}

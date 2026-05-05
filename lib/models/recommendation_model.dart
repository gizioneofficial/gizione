// lib/models/recommendation_model.dart

enum FoodAvailability { warung, restoran, supermarket, kantin }

extension FoodAvailabilityX on FoodAvailability {
  String get label {
    switch (this) {
      case FoodAvailability.warung:
        return 'Warung';
      case FoodAvailability.restoran:
        return 'Restoran';
      case FoodAvailability.supermarket:
        return 'Supermarket';
      case FoodAvailability.kantin:
        return 'Kantin';
    }
  }

  String get emoji {
    switch (this) {
      case FoodAvailability.warung:
        return '🏪';
      case FoodAvailability.restoran:
        return '🍽️';
      case FoodAvailability.supermarket:
        return '🛒';
      case FoodAvailability.kantin:
        return '🏫';
    }
  }
}

class RecommendationModel {
  final String foodName;
  final String whyHealthier;
  final int estimatedCalories;
  final FoodAvailability availability;
  final String priceRange;

  const RecommendationModel({
    this.foodName = '',
    this.whyHealthier = '',
    this.estimatedCalories = 0,
    this.availability = FoodAvailability.warung,
    this.priceRange = '',
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    FoodAvailability avail = FoodAvailability.warung;
    final raw = json['availability'] as String? ?? '';
    switch (raw) {
      case 'restoran':
        avail = FoodAvailability.restoran;
        break;
      case 'supermarket':
        avail = FoodAvailability.supermarket;
        break;
      case 'kantin':
        avail = FoodAvailability.kantin;
        break;
      default:
        avail = FoodAvailability.warung;
    }
    return RecommendationModel(
      foodName: json['food_name'] as String? ?? '',
      whyHealthier: json['why_healthier'] as String? ?? '',
      estimatedCalories: (json['estimated_calories'] as num?)?.toInt() ?? 0,
      availability: avail,
      priceRange: json['price_range'] as String? ?? '',
    );
  }
}

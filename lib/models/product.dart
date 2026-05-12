import 'farmer.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final String unit;
  final double quantity;
  final String imageUrl;
  final String emoji;
  final Farmer farmer;
  final bool inSeason;
  final bool organic;
  final String location;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.imageUrl,
    this.emoji = '🥕',
    required this.farmer,
    this.inSeason = true,
    this.organic = true,
    required this.location,
  });
}

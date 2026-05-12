class Farmer {
  final String id;
  final String name;
  final String farmName;
  final String location;
  final String description;
  final String imageUrl;
  final String phone;
  final double rating;
  final int reviewCount;
  final List<String> certifications;

  const Farmer({
    required this.id,
    required this.name,
    required this.farmName,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.phone,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.certifications = const [],
  });
}

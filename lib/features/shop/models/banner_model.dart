class BannerModel {
  String id;
  String name;
  String imageUrl;
  bool? isFeatured;
  String? link; // ID du produit, catégorie ou établissement
  String? linkType; // 'product', 'category', 'establishment'
  DateTime? createdAt;
  DateTime? updatedAt;

  BannerModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isFeatured,
    this.link,
    this.linkType,
    this.createdAt,
    this.updatedAt,
  });

  static BannerModel empty() {
    return BannerModel(
      id: '',
      imageUrl: '',
      name: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'is_featured': isFeatured ?? false,
      'link': link,
      'link_type': linkType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BannerModel.fromJson(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return BannerModel.empty();
    }
    return BannerModel(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      imageUrl: data['image_url'] ?? '',
      isFeatured: data['is_featured'] as bool? ?? false,
      link: data['link']?.toString(),
      linkType: data['link_type']?.toString(),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : null,
    );
  }

  factory BannerModel.fromMap(Map<String, dynamic> data) {
    return BannerModel.fromJson(data);
  }
}

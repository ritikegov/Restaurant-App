class MenuItemModel {
  final int? id;
  final String name;
  final int priceInPaise;
  final String description;
  final String category;

  const MenuItemModel({
    this.id,
    required this.name,
    required this.priceInPaise,
    required this.description,
    required this.category,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    try {
      return MenuItemModel(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        priceInPaise: map['price_in_paise'] as int? ?? 0,
        description: map['description'] as String? ?? '',
        category: map['category'] as String? ?? '',
      );
    } catch (e) {
      throw Exception('Failed to create MenuItemModel from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      final map = <String, dynamic>{
        'name': name,
        'price_in_paise': priceInPaise,
        'description': description,
        'category': category,
      };

      if (id != null) {
        map['id'] = id;
      }

      return map;
    } catch (e) {
      throw Exception('Failed to convert MenuItemModel to map: $e');
    }
  }

  MenuItemModel copyWith({
    int? id,
    String? name,
    int? priceInPaise,
    String? description,
    String? category,
  }) {
    try {
      return MenuItemModel(
        id: id ?? this.id,
        name: name ?? this.name,
        priceInPaise: priceInPaise ?? this.priceInPaise,
        description: description ?? this.description,
        category: category ?? this.category,
      );
    } catch (e) {
      throw Exception('Failed to copy MenuItemModel: $e');
    }
  }

  double get priceInRupees => priceInPaise / 100.0;

  @override
  String toString() {
    return 'MenuItemModel(id: $id, name: $name, priceInPaise: $priceInPaise, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItemModel &&
        other.id == id &&
        other.name == name &&
        other.priceInPaise == priceInPaise &&
        other.description == description &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        priceInPaise.hashCode ^
        description.hashCode ^
        category.hashCode;
  }
}

class TableModel {
  final int? id;
  final String name;
  final int totalCapacity;
  final int availableSeats;

  const TableModel({
    this.id,
    required this.name,
    required this.totalCapacity,
    required this.availableSeats,
  });

  factory TableModel.fromMap(Map<String, dynamic> map) {
    try {
      return TableModel(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        totalCapacity: map['total_capacity'] as int? ?? 0,
        availableSeats: map['available_seats'] as int? ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to create TableModel from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      final map = <String, dynamic>{
        'name': name,
        'total_capacity': totalCapacity,
        'available_seats': availableSeats,
      };

      if (id != null) {
        map['id'] = id;
      }

      return map;
    } catch (e) {
      throw Exception('Failed to convert TableModel to map: $e');
    }
  }

  TableModel copyWith({
    int? id,
    String? name,
    int? totalCapacity,
    int? availableSeats,
  }) {
    try {
      return TableModel(
        id: id ?? this.id,
        name: name ?? this.name,
        totalCapacity: totalCapacity ?? this.totalCapacity,
        availableSeats: availableSeats ?? this.availableSeats,
      );
    } catch (e) {
      throw Exception('Failed to copy TableModel: $e');
    }
  }

  bool get isAvailable => availableSeats > 0;
  bool get isFullyBooked => availableSeats == 0;
  int get bookedSeats => totalCapacity - availableSeats;

  @override
  String toString() {
    return 'TableModel(id: $id, name: $name, totalCapacity: $totalCapacity, availableSeats: $availableSeats)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableModel &&
        other.id == id &&
        other.name == name &&
        other.totalCapacity == totalCapacity &&
        other.availableSeats == availableSeats;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        totalCapacity.hashCode ^
        availableSeats.hashCode;
  }
}

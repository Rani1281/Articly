import 'package:cloud_firestore/cloud_firestore.dart';

class Tag {
  final String id;
  final String name;
  final DateTime createdAt;

  Tag({this.id = '', required this.name, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  static String normalize(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll('/', '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  // ignore: non_constant_identifier_names
  String normalize_name() => normalize(name);
  String normalizeName() => normalize_name();

  Map<String, dynamic> toFirestore({bool isEdit = false}) {
    return {
      'name': name,
      if (!isEdit) 'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Tag.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return Tag(
      id: snapshot.id,
      name: data?['name'] as String? ?? '',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Tag copyWith({String? id, String? name, DateTime? createdAt}) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, createdAt: $createdAt)';
  }
}

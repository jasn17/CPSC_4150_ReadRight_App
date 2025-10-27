class Item {
  final int? id;
  final String title;
  final String? note;
  final bool isDone;
  final DateTime createdAt;


  const Item({
    this.id,
    required this.title,
    this.note,
    this.isDone = false,
    required this.createdAt,
  });


  Item copyWith({
    int? id,
    String? title,
    String? note,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }


  factory Item.fromMap(Map<String, Object?> map) {
    return Item(
      id: map['id'] as int?,
      title: map['title'] as String,
      note: map['note'] as String?,
      isDone: (map['is_done'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }


  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
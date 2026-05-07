class Task {
  final String id;
  final String title;
  final String categoryId;
  bool isCompleted;
  final String date;
  final List<int> repeatDays;

  Task({
    required this.id,
    required this.title,
    required this.categoryId,
    this.isCompleted = false,
    required this.date,
    required this.repeatDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'categoryId': categoryId,
      'isCompleted': isCompleted ? 1 : 0,
      'date': date,
      'repeatDays': repeatDays.join(','),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      categoryId: map['categoryId'],
      isCompleted: map['isCompleted'] == 1,
      date: map['date'],
      repeatDays: map['repeatDays'].toString().isNotEmpty
          ? map['repeatDays'].toString().split(',').map(int.parse).toList()
          : [],
    );
  }
}

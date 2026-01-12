enum TaskStatus {
  pending,
  inProgress,
  completed,
}

class StudyTask {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final String parentId;
  final String childId;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int rewardMinutes; // Free time rewarded after completion

  StudyTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.durationMinutes,
    required this.parentId,
    required this.childId,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.rewardMinutes = 0,
  });

  factory StudyTask.fromMap(Map<String, dynamic> map, String id) {
    return StudyTask(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      durationMinutes: map['durationMinutes'] as int,
      parentId: map['parentId'] as String,
      childId: map['childId'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == 'TaskStatus.${map['status']}',
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      rewardMinutes: map['rewardMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'parentId': parentId,
      'childId': childId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rewardMinutes': rewardMinutes,
    };
  }

  StudyTask copyWith({
    TaskStatus? status,
    DateTime? completedAt,
  }) {
    return StudyTask(
      id: id,
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      parentId: parentId,
      childId: childId,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      rewardMinutes: rewardMinutes,
    );
  }
}

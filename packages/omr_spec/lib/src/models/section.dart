/// A logical section of the exam (e.g. Physics). Sections carry the subject
/// tag used by analytics and the optional N-of-M rule.
class SectionSpec {
  const SectionSpec({
    required this.id,
    required this.name,
    required this.subject,
    required this.questionLabels,
    this.maxCounted,
  });

  final String id;

  /// Display name ("Physics — Section A").
  final String name;

  /// Subject bucket for subject-wise analytics.
  final String subject;

  /// Question labels covered, using the same range syntax as field blocks
  /// ("q1..q45").
  final List<String> questionLabels;

  /// N-of-M: only the first [maxCounted] valid responses in sheet serial
  /// order count; extras are ignored without penalty (NEET Section II rule).
  final int? maxCounted;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'subject': subject,
        'questionLabels': questionLabels,
        if (maxCounted != null) 'maxCounted': maxCounted,
      };

  static SectionSpec fromJson(Map<String, Object?> j) => SectionSpec(
        id: j['id']! as String,
        name: j['name']! as String,
        subject: j['subject']! as String,
        questionLabels: (j['questionLabels']! as List<Object?>).cast<String>(),
        maxCounted: j['maxCounted'] as int?,
      );
}

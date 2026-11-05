enum TaskSource {
  whatsApp('WhatsApp'),
  telegram('Telegram'),
  gmail('Gmail'),
  voiceInput('Voice_Input'),
  manualText('Manual_Text');

  final String value;
  const TaskSource(this.value);

  static TaskSource fromString(String val) {
    return TaskSource.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase().replaceAll(' ', '_'),
      orElse: () => TaskSource.manualText,
    );
  }
}

enum EisenhowerQuadrant {
  q1('Q1', 'Do First (Urgent & Important)', '11'),
  q2('Q2', 'Schedule (Not Urgent & Important)', '9'),
  q3('Q3', 'Delegate (Urgent & Not Important)', '5'),
  q4('Q4', 'Eliminate (Not Urgent & Not Important)', '8');

  final String code;
  final String label;
  final String defaultColorId;
  const EisenhowerQuadrant(this.code, this.label, this.defaultColorId);

  static EisenhowerQuadrant fromCode(String code) {
    final clean = code.trim().toUpperCase();
    if (clean.contains('Q1')) return EisenhowerQuadrant.q1;
    if (clean.contains('Q2')) return EisenhowerQuadrant.q2;
    if (clean.contains('Q3')) return EisenhowerQuadrant.q3;
    if (clean.contains('Q4')) return EisenhowerQuadrant.q4;
    return EisenhowerQuadrant.q2;
  }
}

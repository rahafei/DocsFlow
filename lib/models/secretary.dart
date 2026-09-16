class Secretary {
  final String name;
  final int sampleCount;

  const Secretary({
    required this.name,
    required this.sampleCount,
  });

  factory Secretary.fromJson(Map<String, dynamic> json) {
    return Secretary(
      name: json['name'] as String,
      sampleCount: json['sample_count'] as int? ?? 0,
    );
  }
}
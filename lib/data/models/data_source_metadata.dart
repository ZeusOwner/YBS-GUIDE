class DataSourceMetadata {
  const DataSourceMetadata({
    required this.id,
    required this.name,
    required this.sourceUrl,
    required this.version,
    required this.lastUpdated,
    required this.confidence,
  });

  final String id;
  final String name;
  final String sourceUrl;
  final String version;
  final DateTime lastUpdated;
  final double confidence;

  factory DataSourceMetadata.fromJson(Map<String, dynamic> json) {
    return DataSourceMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceUrl: json['sourceUrl'] as String,
      version: json['version'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sourceUrl': sourceUrl,
      'version': version,
      'lastUpdated': lastUpdated.toIso8601String(),
      'confidence': confidence,
    };
  }
}

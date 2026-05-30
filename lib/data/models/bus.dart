class Bus {
  const Bus({
    required this.id,
    required this.number,
    required this.operatorName,
  });

  final String id;
  final String number;
  final String operatorName;

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as String,
      number: json['number'] as String,
      operatorName: json['operatorName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'number': number, 'operatorName': operatorName};
  }
}

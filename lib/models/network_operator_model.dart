// lib/models/network_operator_model.dart

enum NetworkOperator {
  mtn,
  airtel,
  glo,
  nineMobile,
}

class NetworkOperatorModel {
  final NetworkOperator operator;
  final String displayName;
  final String code;
  final String imageUrl;
  final String color;

  const NetworkOperatorModel({
    required this.operator,
    required this.displayName,
    required this.code,
    required this.imageUrl,
    required this.color,
  });

  // Predefined operators
  static const mtn = NetworkOperatorModel(
    operator: NetworkOperator.mtn,
    displayName: 'MTN',
    code: 'MTN',
    imageUrl: 'assets/icons/mtn.png',
    color: '#FFD700', // Yellow
  );

  static const airtel = NetworkOperatorModel(
    operator: NetworkOperator.airtel,
    displayName: 'Airtel',
    code: 'AIRTEL',
    imageUrl: 'assets/icons/airtel.png',
    color: '#DC143C', // Red
  );

  static const glo = NetworkOperatorModel(
    operator: NetworkOperator.glo,
    displayName: 'Glo',
    code: 'GLO',
    imageUrl: 'assets/icons/glo.png',
    color: '#008000', // Green
  );

  static const nineMobile = NetworkOperatorModel(
    operator: NetworkOperator.nineMobile,
    displayName: '9mobile',
    code: '9MOBILE',
    imageUrl: 'assets/icons/9mobile.png',
    color: '#0066CC', // Blue
  );

  static List<NetworkOperatorModel> getAll() => [mtn, airtel, glo, nineMobile];
}

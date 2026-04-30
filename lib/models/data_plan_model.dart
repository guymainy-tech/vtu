// lib/models/data_plan_model.dart

class DataPlanModel {
  final String planId;
  final String name;
  final double size; // in GB
  final double price;
  final String validity; // e.g., "30 days", "7 days"
  final String description;
  final bool isPopular;

  const DataPlanModel({
    required this.planId,
    required this.name,
    required this.size,
    required this.price,
    required this.validity,
    required this.description,
    this.isPopular = false,
  });

  // Sample data plans for MTN
  static const List<DataPlanModel> mtnPlans = [
    DataPlanModel(
      planId: 'mtn_500mb',
      name: '500MB',
      size: 0.5,
      price: 100,
      validity: '7 days',
      description: '500MB for 7 days',
    ),
    DataPlanModel(
      planId: 'mtn_1gb',
      name: '1GB',
      size: 1,
      price: 200,
      validity: '30 days',
      description: '1GB for 30 days',
      isPopular: true,
    ),
    DataPlanModel(
      planId: 'mtn_2gb',
      name: '2GB',
      size: 2,
      price: 350,
      validity: '30 days',
      description: '2GB for 30 days',
      isPopular: true,
    ),
    DataPlanModel(
      planId: 'mtn_5gb',
      name: '5GB',
      size: 5,
      price: 750,
      validity: '30 days',
      description: '5GB for 30 days',
    ),
    DataPlanModel(
      planId: 'mtn_10gb',
      name: '10GB',
      size: 10,
      price: 1500,
      validity: '30 days',
      description: '10GB for 30 days',
    ),
  ];

  // Sample data plans for Airtel
  static const List<DataPlanModel> airtelPlans = [
    DataPlanModel(
      planId: 'airtel_500mb',
      name: '500MB',
      size: 0.5,
      price: 100,
      validity: '7 days',
      description: '500MB for 7 days',
    ),
    DataPlanModel(
      planId: 'airtel_1gb',
      name: '1GB',
      size: 1,
      price: 200,
      validity: '30 days',
      description: '1GB for 30 days',
      isPopular: true,
    ),
    DataPlanModel(
      planId: 'airtel_3gb',
      name: '3GB',
      size: 3,
      price: 500,
      validity: '30 days',
      description: '3GB for 30 days',
    ),
    DataPlanModel(
      planId: 'airtel_5gb',
      name: '5GB',
      size: 5,
      price: 800,
      validity: '30 days',
      description: '5GB for 30 days',
    ),
  ];

  // Sample data plans for Glo
  static const List<DataPlanModel> gloPlans = [
    DataPlanModel(
      planId: 'glo_500mb',
      name: '500MB',
      size: 0.5,
      price: 80,
      validity: '7 days',
      description: '500MB for 7 days',
    ),
    DataPlanModel(
      planId: 'glo_1gb',
      name: '1GB',
      size: 1,
      price: 150,
      validity: '30 days',
      description: '1GB for 30 days',
      isPopular: true,
    ),
    DataPlanModel(
      planId: 'glo_2gb',
      name: '2GB',
      size: 2,
      price: 300,
      validity: '30 days',
      description: '2GB for 30 days',
    ),
    DataPlanModel(
      planId: 'glo_10gb',
      name: '10GB',
      size: 10,
      price: 1000,
      validity: '30 days',
      description: '10GB for 30 days',
    ),
  ];

  // Sample data plans for 9mobile
  static const List<DataPlanModel> nineMobilePlans = [
    DataPlanModel(
      planId: '9m_500mb',
      name: '500MB',
      size: 0.5,
      price: 90,
      validity: '7 days',
      description: '500MB for 7 days',
    ),
    DataPlanModel(
      planId: '9m_1gb',
      name: '1GB',
      size: 1,
      price: 180,
      validity: '30 days',
      description: '1GB for 30 days',
      isPopular: true,
    ),
    DataPlanModel(
      planId: '9m_5gb',
      name: '5GB',
      size: 5,
      price: 850,
      validity: '30 days',
      description: '5GB for 30 days',
    ),
  ];

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'name': name,
        'size': size,
        'price': price,
        'validity': validity,
        'description': description,
        'is_popular': isPopular,
      };

  factory DataPlanModel.fromJson(Map<String, dynamic> json) => DataPlanModel(
        planId: json['plan_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        size: (json['size'] as num?)?.toDouble() ?? 0.0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        validity: json['validity'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isPopular: json['is_popular'] as bool? ?? false,
      );
}

// lib/screens/main/services_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final List<Map<String, dynamic>> services = [
    {
      'icon': Icons.phone_android,
      'title': 'Buy Airtime',
      'subtitle': 'Purchase airtime for any network',
      'route': '/buy-airtime',
      'color': Colors.blue,
    },
    {
      'icon': Icons.signal_cellular_4_bar,
      'title': 'Buy Data',
      'subtitle': 'Get data bundles instantly',
      'route': '/buy-data',
      'color': Colors.green,
    },
    {
      'icon': Icons.transfer_within_a_station,
      'title': 'Fund Transfer',
      'subtitle': 'Send money to other users',
      'route': '/transfer-funds',
      'color': Colors.orange,
    },
    {
      'icon': Icons.receipt_long,
      'title': 'Utility Payments',
      'subtitle': 'Pay electricity, water, internet',
      'route': '/utility-payment',
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VTU Services'),
        centerTitle: true,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _buildServiceCard(context, service);
        },
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => context.push(service['route']),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [service['color'].withOpacity(0.8), service['color']],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                service['icon'],
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                service['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  service['subtitle'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

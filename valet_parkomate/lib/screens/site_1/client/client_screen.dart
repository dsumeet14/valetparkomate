import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/car.dart';
import '../../../services/api_service.dart';
import '../../../ui/shared/toast.dart';

class ClientScreen extends StatefulWidget {
  final int siteNo;
  final String valetId;
  const ClientScreen({super.key, required this.siteNo, required this.valetId});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  Car? _car;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadCar();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => loadCar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadCar() async {
    try {
      final res = await ApiService().get(
          'api/site_${widget.siteNo}/client-car/${widget.siteNo}/${Uri.encodeComponent(widget.valetId)}');
      if (res != null) {
        setState(() => _car = Car.fromJson(Map<String, dynamic>.from(res)));
      }
    } catch (_) {}
  }

  Future<void> requestOut() async {
    try {
      final res = await ApiService().post(
          'api/site_${widget.siteNo}/car-out-request',
          {'valet_id': widget.valetId, 'site_no': widget.siteNo});
      Toast.show(context, res['message'] ?? 'Requested');
      await loadCar();
    } catch (_) {
      Toast.show(context, 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = _car;
    return Scaffold(
      appBar: AppBar(
        title: Text('Client • Site ${widget.siteNo}'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: car == null
          ? const Center(child: Text('No car linked'))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(car.carNo,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      Text('Status: ${car.status ?? '-'}'),
                      Text('Valet: ${car.valetId ?? '-'}'),
                      Text('Spot: ${car.parkingSpot ?? '-'}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: requestOut,
                          child: const Text('Request Car Out'))
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

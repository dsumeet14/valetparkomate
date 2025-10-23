import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/car.dart';
import '../../../services/api_service.dart';
import '../../../services/notification_service.dart';

class ClientScreen extends StatefulWidget {
  final int siteNo;
  const ClientScreen({super.key, required this.siteNo});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  Car? _car;
  Timer? _timer;
  String? _valetId;
  bool _loading = false;

  Future<void> loadByValet(String valetId) async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().get('api/site_${widget.siteNo}/client-car/${widget.siteNo}/${Uri.encodeComponent(valetId)}');
      if (res is Map) {
        final c = Car.fromJson(Map<String, dynamic>.from(res));
        if (_car != null && _car!.status != c.status) {
          await NotificationService().notifyWithSound(title: 'Car Status changed', body: '${c.carNo} -> ${c.status}');
        }
        setState(() {
          _car = c;
          _valetId = valetId;
        });
      } else {
        setState(() {
          _car = null;
        });
      }
    } catch (e) {
      setState(() {
        _car = null;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> requestOut(String carNo) async {
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/car-out-request', {'car_no': carNo, 'site_no': widget.siteNo});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Requested')));
      if (_valetId != null) await loadByValet(_valetId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request failed')));
    } finally {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 2), (_) {
      if (_valetId != null) loadByValet(_valetId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client • Site ${widget.siteNo}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(children: [
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'Valet ID'), onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  loadByValet(v.trim());
                  _startPolling();
                })),
                SizedBox(width: 8),
                ElevatedButton(onPressed: () {}, child: Text('Load'))
              ]),
            ),
          ),
          SizedBox(height: 12),
          Expanded(child: Card(child: Padding(padding: EdgeInsets.all(12), child: _loading ? Center(child: CircularProgressIndicator()) : _car == null ? Center(child: Text('No car loaded')) : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Car No: ${_car!.carNo}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Valet ID: ${_car!.valetId ?? '-'}'),
              Text('Phone: ${_car!.phoneNumber ?? '-'}'),
              Text('Status: ${_car!.status ?? '-'}'),
              Text('Parking Spot: ${_car!.parkingSpot ?? '-'}'),
              SizedBox(height: 12),
              if (_car!.status == 'parked') ElevatedButton(onPressed: () => requestOut(_car!.carNo), child: Text('Request Car Out'))
            ],
          ))))
        ]),
      ),
    );
  }
}

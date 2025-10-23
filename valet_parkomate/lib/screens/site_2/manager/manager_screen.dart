import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/car.dart';
import '../../../models/driver_stats.dart';
import '../../../services/api_service.dart';
import '../../../services/notification_service.dart';
import '../../../ui/shared/toast.dart';

class ManagerScreen extends StatefulWidget {
  final int siteNo;
  const ManagerScreen({super.key, required this.siteNo});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen>
    with SingleTickerProviderStateMixin {
  List<Car> _requests = [];
  List<DriverStats> _driverStats = [];
  Timer? _timer;
  List<String> _drivers = [];
  Map<String, Car> _prevMap = {};
  late TabController _tabCtl;
  final _dateFmt = DateFormat('HH:mm');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtl = TabController(length: 5, vsync: this);
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabCtl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    await Future.wait([
      loadDrivers(),
      loadRequests(),
      loadDriverStats(),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> loadDrivers() async {
    try {
      final res = await ApiService()
          .get('api/site_${widget.siteNo}/admin-users/${widget.siteNo}');
      if (res is List) {
        final drv = res
            .where((e) => e['role'] == 'driver')
            .map<String>((e) => e['id'].toString())
            .toList();
        if (mounted) {
          setState(() => _drivers = drv);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        Toast.show(context, 'Error fetching drivers: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to load drivers: $e');
      }
    }
  }

  Future<void> loadRequests() async {
    try {
      final res = await ApiService()
          .get('api/site_${widget.siteNo}/car-requests/${widget.siteNo}');
      if (res is List) {
        final list =
            res.map((e) => Car.fromJson(Map<String, dynamic>.from(e))).toList();
        final newMap = {for (var c in list) c.carNo: c};
        for (final key in newMap.keys) {
          if (!_prevMap.containsKey(key)) {
            NotificationService()
                .notifyWithSound(title: 'New Request', body: key);
          }
        }
        _prevMap = newMap;
        if (mounted) {
          setState(() => _requests = list);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        Toast.show(context, 'Error fetching requests: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to load requests: $e');
      }
    }
  }

  Future<void> loadDriverStats() async {
    try {
      final res = await ApiService()
          .get('api/site_${widget.siteNo}/driver-stats?site_no=${widget.siteNo}');
      if (res is List) {
        final stats = res.map((e) => DriverStats.fromJson(e)).toList();
        if (mounted) {
          setState(() => _driverStats = stats);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        Toast.show(context, 'Error fetching stats: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to load stats: $e');
      }
    }
  }

  Future<void> assignDriver(String carNo, String driverId) async {
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/assign-driver',
          {'car_no': carNo, 'driver_id': driverId, 'site_no': widget.siteNo});
      Toast.show(context, res['message'] ?? 'Assigned');
      _loadData();
    } on ApiException catch (e) {
      Toast.show(context, 'Assign failed: ${e.message}');
    } catch (_) {
      Toast.show(context, 'Assign failed');
    }
  }

  Future<void> markHandedOver(String carNo) async {
    try {
      final res = await ApiService().post(
          'api/site_${widget.siteNo}/mark-handed-over',
          {'car_no': carNo, 'site_no': widget.siteNo});
      Toast.show(context, res['message'] ?? 'Handed over');
      _loadData();
    } on ApiException catch (e) {
      Toast.show(context, 'Hand over failed: ${e.message}');
    } catch (_) {
      Toast.show(context, 'Failed');
    }
  }

  Widget _carCard(Car req) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 72,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(req.carNo,
              style: GoogleFonts.montserrat(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(req.status ?? '...'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valet: ${req.valetId ?? '-'}'),
            const SizedBox(height: 2),
            if (req.driverAssignedForParking != null)
              Row(
                children: [
                  Text('DriverP: ${req.driverAssignedForParking}'),
                  if (req.seenParking)
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                ],
              ),
            if (req.driverAssignedForBringing != null)
              Row(
                children: [
                  Text('DriverB: ${req.driverAssignedForBringing}'),
                  if (req.seenBringing)
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                ],
              ),
            if (req.timestampCarInRequest != null)
              Text(_dateFmt.format(req.timestampCarInRequest!)),
          ],
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            if (req.status == 'in_request' || req.status == 'assigned_parking')
              ElevatedButton(
                  onPressed: () => _openDriverDialog(req.carNo), child: const Text('Assign')),
            if (req.status == 'out_request' || req.status == 'assigned_bringing')
              ElevatedButton(
                  onPressed: () => _openDriverDialog(req.carNo), child: const Text('Assign')),
            if (req.status == 'brought_to_client')
              OutlinedButton(
                  onPressed: () => markHandedOver(req.carNo),
                  child: const Text('Hand Over'))
          ],
        ),
      ),
    );
  }

  void _openDriverDialog(String carNo) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Assign driver for $carNo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _drivers.map((d) {
              final driverStats = _driverStats.firstWhere(
                (s) => s.driverId == d,
                orElse: () => DriverStats(
                  driverId: d,
                  totalJobsToday: 0,
                  parkingJobsToday: 0,
                  retrievalJobsToday: 0,
                  currentAssignedJobs: 0,
                    onDuty: false, // 👈 added

                ),
              );

              return ListTile(
                title: Text(d),
                subtitle: Text(
                  'Total: ${driverStats.totalJobsToday} | Assigned: ${driverStats.currentAssignedJobs}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  assignDriver(carNo, d);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            )
          ],
        );
      });
  }

  void _showDriverStatsDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Driver Performance', style: GoogleFonts.montserrat()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _driverStats.isEmpty
                  ? [const Text('No stats available.')]
                  : _driverStats.map((stats) {
                      return ListTile(
                        title: Text(stats.driverId, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Total Jobs: ${stats.totalJobsToday}\nParking: ${stats.parkingJobsToday} • Retrieval: ${stats.retrievalJobsToday}\nCurrently Assigned: ${stats.currentAssignedJobs}'),
                      );
                    }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            )
          ],
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    List<Car> filtered(String tab) => _requests.where((c) {
          switch (tab) {
            case 'Car In':
              return c.status == 'in_request' || c.status == 'assigned_parking';
            case 'Car Out':
              return c.status == 'out_request' || c.status == 'assigned_bringing';
            case 'Parked':
              return c.status == 'parked';
            case 'Ready':
              return c.status == 'brought_to_client';
            case 'Completed':
              return c.status == 'completed' || c.status == 'handed_over';
          }
          return false;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manager • Site ${widget.siteNo}', style: GoogleFonts.montserrat()),
        actions: [
          IconButton(
              onPressed: _showDriverStatsDialog,
              icon: const Icon(Icons.leaderboard)),
          IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              icon: const Icon(Icons.logout))
        ],
        bottom: TabBar(
          controller: _tabCtl,
          indicatorColor: Colors.blueAccent,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Car In'),
            Tab(text: 'Car Out'),
            Tab(text: 'Parked'),
            Tab(text: 'Ready'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtl,
              children: [
                _buildList(filtered('Car In')),
                _buildList(filtered('Car Out')),
                _buildList(filtered('Parked')),
                _buildList(filtered('Ready')),
                _buildList(filtered('Completed')),
              ],
            ),
    );
  }

  Widget _buildList(List<Car> list) {
    list.sort((a, b) {
      if (a.timestampCarInRequest == null && b.timestampCarInRequest == null) return 0;
      if (a.timestampCarInRequest == null) return 1;
      if (b.timestampCarInRequest == null) return -1;
      return b.timestampCarInRequest!.compareTo(a.timestampCarInRequest!);
    });

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: list.isEmpty
          ? const Center(child: Text('No cars'))
          : ListView(children: list.map(_carCard).toList()),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valet_parkomate/models/car.dart';
import 'package:valet_parkomate/services/api_service.dart';
import 'package:valet_parkomate/services/notification_service.dart';
import 'package:valet_parkomate/ui/shared/toast.dart';

class DriverScreen extends StatefulWidget {
  final int siteNo;
  final String driverId;

  const DriverScreen({super.key, required this.siteNo, required this.driverId});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> with SingleTickerProviderStateMixin {
  List<Car> _tasks = [];
  Timer? _timer;
  final Map<String, String?> _prevStatus = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// Fetches tasks from the API with a 2-second auto-refresh.
  Future<void> loadTasks() async {
    if (widget.driverId.isEmpty) return;
    try {
      final res = await ApiService().get(
        'api/site_${widget.siteNo}/driver-tasks/${widget.siteNo}/${Uri.encodeComponent(widget.driverId)}',
      );
      if (res is List) {
        final newTasks = res.map((e) => Car.fromJson(Map<String, dynamic>.from(e))).toList();
        _handleNotifications(newTasks);
        setState(() => _tasks = newTasks);
      }
    } catch (_) {
      // Errors are handled gracefully without showing a toast on every failed poll.
    }
  }

  void _handleNotifications(List<Car> tasks) {
    final currentCarNos = tasks.map((t) => t.carNo).toSet();
    final prevCarNos = _tasks.map((t) => t.carNo).toSet();

    // Notify for new tasks
    final newAssignments = currentCarNos.difference(prevCarNos);
    if (newAssignments.isNotEmpty) {
      for (final carNo in newAssignments) {
        NotificationService().notifyWithSound(
          title: 'New Task',
          body: 'Assigned: $carNo',
        );
      }
    }

    // Notify for status changes
    for (final task in tasks) {
      final prevStatus = _prevStatus[task.carNo];
      if (prevStatus != null && prevStatus != task.status) {
        NotificationService().notifyWithSound(
          title: 'Task Updated',
          body: '${task.carNo}: ${task.status}',
        );
      }
      _prevStatus[task.carNo] = task.status;
    }
  }

  /// Starts the periodic fetching of tasks.
  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => loadTasks());
  }

  /// Marks a task as "seen" by the driver.
  Future<void> _markSeen(String carNo, String type) async {
    try {
      await ApiService().post('api/site_${widget.siteNo}/driver-seen', {
        'car_no': carNo,
        'site_no': widget.siteNo,
        'driver_id': widget.driverId,
        'type': type,
      });
    } on ApiException catch (e) {
      // Show an error toast if the API call fails
      Toast.show(context, 'Failed to mark as seen: ${e.message}');
    } catch (_) {}
  }

  /// Marks a car as "parked" with a specific spot.
  Future<void> _markParked(String carNo, String spot) async {
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/mark-parked', {
        'car_no': carNo,
        'parking_spot': spot,
        'site_no': widget.siteNo,
      });
      Toast.show(context, res['message'] ?? 'Marked parked', isSuccess: true);
      await loadTasks();
    } on ApiException catch (e) {
      Toast.show(context, 'Failed to mark as parked: ${e.message}');
    } catch (_) {
      Toast.show(context, 'Failed to mark as parked');
    }
  }

  /// Marks a car as "brought to client."
  Future<void> _markBrought(String carNo) async {
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/mark-brought', {
        'car_no': carNo,
        'site_no': widget.siteNo,
      });
      Toast.show(context, res['message'] ?? 'Marked brought', isSuccess: true);
      await loadTasks();
    } on ApiException catch (e) {
      Toast.show(context, 'Failed to mark as brought: ${e.message}');
    } catch (_) {
      Toast.show(context, 'Failed to mark as brought');
    }
  }

  /// Displays the task details in a full-screen modal.
  void _showTaskDetailsModal(Car task) async {
    await _markSeen(task.carNo, task.status == 'assigned_parking' ? 'parking' : 'bringing');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Task Details', style: GoogleFonts.montserrat(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87,
                      )),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1.5),
                  _buildDetailRow('Car Number', task.carNo),
                  _buildDetailRow('Valet ID', task.valetId ?? '-'),
                  _buildDetailRow('Status', task.status ?? '-'),
                  if (task.status == 'assigned_bringing')
                    _buildDetailRow('Parking Spot', task.parkingSpot ?? 'N/A'),
                  const SizedBox(height: 32),
                  if (task.status == 'assigned_parking')
                    _buildMarkParkedButton(context, task.carNo),
                  if (task.status == 'assigned_bringing')
                    _buildMarkBroughtButton(context, task.carNo),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54,
          )),
          Text(value, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87,
          )),
        ],
      ),
    );
  }

  Widget _buildMarkParkedButton(BuildContext context, String carNo) {
    final spotCtl = TextEditingController();
    return Column(
      children: [
        TextField(
          controller: spotCtl,
          decoration: InputDecoration(
            labelText: 'Enter Parking Spot',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            fillColor: Colors.grey[100],
            filled: true,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final spot = spotCtl.text.trim();
              if (spot.isNotEmpty) {
                await _markParked(carNo, spot);
                if (mounted) Navigator.of(context).pop();
              } else {
                Toast.show(context, 'Please enter a parking spot');
              }
            },
            child: Text('Mark as Parked', style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkBroughtButton(BuildContext context, String carNo) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          await _markBrought(carNo);
          if (mounted) Navigator.of(context).pop();
        },
        child: Text('Mark as Brought', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parkingTasks = _tasks.where((t) => t.status == 'assigned_parking').toList();
    final bringingTasks = _tasks.where((t) => t.status == 'assigned_bringing').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver • Site ${widget.siteNo}', style: GoogleFonts.montserrat()),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            icon: const Icon(Icons.logout),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          tabs: [
            Tab(child: Text('Parking (${parkingTasks.length})')),
            Tab(child: Text('Car Out (${bringingTasks.length})')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(parkingTasks),
          _buildTaskList(bringingTasks),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Car> list) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No tasks found.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final task = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showTaskDetailsModal(task),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.carNo.split('').join('\n'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Car: ${task.carNo}',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Status: ${task.status}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
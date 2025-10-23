import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// Note: The custom SwipeConfirm widget is now imported from a common location 
// (assuming it was moved, or is available via a relative path from the driver screen).
import '../driver/driver_screen.dart'; // Assuming SwipeConfirm is available here

// Assuming these models and services are defined elsewhere in your project
import '../../../models/car.dart';
import '../../../models/driver_stats.dart';
import '../../../services/api_service.dart';
import '../../../services/notification_service.dart';
import '../../../ui/shared/toast.dart';
// Removed: import 'package:flutter_swipe_button/flutter_swipe_button.dart';


// Helper Widget for Real-time Timer
class _CarTimer extends StatefulWidget {
  final DateTime? timestamp;
  final bool showRed;
  const _CarTimer({super.key, required this.timestamp, required this.showRed});

  @override
  State<_CarTimer> createState() => _CarTimerState();
}

class _CarTimerState extends State<_CarTimer> {
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.timestamp != null) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(_CarTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timestamp != oldWidget.timestamp) {
      _timer?.cancel();
      if (widget.timestamp != null) {
        _startTimer();
      } else {
        if (mounted) setState(() => _duration = Duration.zero);
      }
    }
  }

  void _startTimer() {
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDuration();
    });
  }

  void _updateDuration() {
    if (widget.timestamp != null) {
      final now = DateTime.now();
      final diff = now.difference(widget.timestamp!);
      if (mounted) setState(() => _duration = diff);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return '${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final text = _formatDuration(_duration);
    // The timer logic: turns red if showRed is true AND time is past 10 minutes
    final isOver10Min = widget.showRed && _duration.inMinutes >= 10;
    final color = isOver10Min ? Colors.red : Colors.green.shade700;

    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// =================================================================
// MANAGER SCREEN STATE
// =================================================================

class ManagerScreen extends StatefulWidget {
  final int siteNo;
  const ManagerScreen({super.key, required this.siteNo});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> with SingleTickerProviderStateMixin {
  List<Car> _requests = [];
  // Combining driver info (name, photo, status) with stats for a single source of truth
  List<DriverStats> _driverPoolAndStats = []; 
  Timer? _loadDataTimer;
  Map<String, Car> _prevMap = {};
  late TabController _tabCtl;
  final _dateFmt = DateFormat('HH:mm');
  bool _isLoading = true;

  // State variable to hold the currently selected driver ID for assignment
  String? _selectedDriverId; 
  String? _selectedDriverName;
  String? _selectedDriverPhoto;

  final Map<String, TextEditingController> _searchControllers = {
    'Car In': TextEditingController(),
    'Car Out': TextEditingController(),
    'Parked': TextEditingController(),
    'Ready': TextEditingController(),
    'Completed': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _tabCtl = TabController(length: 5, vsync: this);
    _loadData();
    _loadDataTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabCtl.dispose();
    _loadDataTimer?.cancel();
    _searchControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadData() async {
    final isInitialLoad = _requests.isEmpty;
    if (isInitialLoad && mounted) setState(() => _isLoading = true);

    await Future.wait([
      _loadDriverPoolAndStats(), // Single call to load both
      loadRequests(),
    ]);

    if (isInitialLoad && mounted) setState(() => _isLoading = false);
    if (mounted) setState(() {});
  }

  Future<void> _loadDriverPoolAndStats() async {
    try {
      // 1. Fetch all drivers (provides ID, Name, Photo, on_duty)
      final driverPoolRes = await ApiService().get('api/site_${widget.siteNo}/driver-pool/${widget.siteNo}');
      
      // 2. Fetch all driver stats (provides ID, totalJobs, currentAssignedJobs)
      final statsRes = await ApiService().get('api/site_${widget.siteNo}/driver-stats?site_no=${widget.siteNo}');

      if (driverPoolRes is List && statsRes is List) {
        final Map<String, DriverStats> statsMap = {
          for (var item in statsRes) item['driver_id']?.toString() ?? 'unknown': DriverStats.fromJson(item)
        };
        
        // 3. Merge: Iterate through the driver pool, merge with stats, and create the final list
        final mergedList = driverPoolRes.map((d) {
          final driverId = d['driver_id']?.toString() ?? 'unknown';
          final stats = statsMap[driverId];
          
          // FIX 1: Logically invert the 'on_duty' status as reported by the user 
          // ("switched up"). If true means inactive, we flip it.
          final bool onDutyStatus = d['on_duty'] is bool
              ? !d['on_duty'] 
              : !(d['on_duty'] == 0); 
          
          return DriverStats(
            driverId: driverId,
            driverName: d['driver_name']?.toString(),
            driverPhoto: d['driver_photo']?.toString(),
            onDuty: onDutyStatus, // Use the corrected status
            lastLogin: d['last_login'] != null ? DateTime.tryParse(d['last_login']) : null,
            lastLogout: d['last_logout'] != null ? DateTime.tryParse(d['last_logout']) : null,
            // Stats from the other endpoint. Default to 0/false if not found.
            totalJobsToday: stats?.totalJobsToday ?? 0,
            parkingJobsToday: stats?.parkingJobsToday ?? 0,
            retrievalJobsToday: stats?.retrievalJobsToday ?? 0,
            currentAssignedJobs: stats?.currentAssignedJobs ?? 0,
          );
        }).toList();

        if (mounted) setState(() => _driverPoolAndStats = mergedList);
      }
    } on ApiException catch (e) {
      if (mounted) Toast.show(context, 'Error fetching drivers/stats: ${e.message}');
    } catch (e) {
      if (mounted) Toast.show(context, 'Failed to load driver data: $e');
    }
  }


  Future<void> loadRequests() async {
    try {
      final res = await ApiService().get('api/site_${widget.siteNo}/car-requests/${widget.siteNo}');
      if (res is List) {
        final list = res.map((e) => Car.fromJson(Map<String, dynamic>.from(e))).toList();
        final newMap = {for (var c in list) c.carNo: c};
        for (final key in newMap.keys) {
          if (!_prevMap.containsKey(key)) {
            NotificationService().notifyWithSound(title: 'New Request', body: newMap[key]!.carNo);
          }
        }
        _prevMap = newMap;
        if (mounted) setState(() => _requests = list);
      }
    } on ApiException catch (e) {
      if (mounted) Toast.show(context, 'Error fetching requests: ${e.message}');
    } catch (e) {
      if (mounted) Toast.show(context, 'Failed to load requests: $e');
    }
  }

  Future<void> assignDriver(String carNo, String driverId) async {
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/assign-driver', {
        'car_no': carNo,
        'driver_id': driverId,
        'site_no': widget.siteNo,
      });
      Toast.show(context, res['message'] ?? 'Assigned', isSuccess: true);
      _loadData();
    } on ApiException catch (e) {
      Toast.show(context, 'Assign failed: ${e.message}');
    } catch (_) {
      Toast.show(context, 'Assign failed');
    }
  }

  Future<void> markHandedOver(String carNo) async {
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/mark-handed-over', {
        'car_no': carNo,
        'site_no': widget.siteNo,
      });
      Toast.show(context, res['message'] ?? 'Handed over', isSuccess: true);
      _loadData();
    } on ApiException catch (e) {
      Toast.show(context, 'Hand over failed: ${e.message}');
    } catch (_) {
      Toast.show(context, 'Failed');
    }
  }
  
  // =================================================================
  // HELPER WIDGETS AND DIALOGS
  // =================================================================

  Widget _avatarFromDynamic(String? maybeDataUrl, {double radius = 30}) {
    if (maybeDataUrl == null || maybeDataUrl.isEmpty) {
      return CircleAvatar(radius: radius, child: const Icon(Icons.person, size: 30));
    }
    if (maybeDataUrl.startsWith('data:')) {
      final comma = maybeDataUrl.indexOf(',');
      final base64Part = comma >= 0 ? maybeDataUrl.substring(comma + 1) : maybeDataUrl;
      try {
        final bytes = base64Decode(base64Part);
        return CircleAvatar(radius: radius, backgroundImage: MemoryImage(Uint8List.fromList(bytes)));
      } catch (_) {
        return CircleAvatar(radius: radius, child: const Icon(Icons.person, size: 30));
      }
    } else {
      // Assuming a URL if it's not base64 encoded data
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(maybeDataUrl));
    }
  }

  // New Dialog for Manual Driver Assignment
  void _showDriverAssignmentDialog(Car car) {
    // Reset selection state when opening dialog
    setState(() {
      _selectedDriverId = null;
      _selectedDriverName = null;
      _selectedDriverPhoto = null;
    });

    // Determine the relevant request timestamp for the timer
    final DateTime? requestTimestamp = car.status == 'in_request' || car.status == 'assigned_parking'
        ? car.timestampCarInRequest
        : car.timestampCarOutRequest;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedStats = _driverPoolAndStats.firstWhere(
              (s) => s.driverId == _selectedDriverId,
              orElse: () => DriverStats(
                driverId: 'unknown', totalJobsToday: 0, parkingJobsToday: 0, retrievalJobsToday: 0, currentAssignedJobs: 0, onDuty: true,
              ),
            );

            return AlertDialog(
              title: Text(
                'Assign Driver to ${car.carNo}',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display the Request Timer
                    if (requestTimestamp != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Text('Request Time Elapsed: ', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                            _CarTimer(timestamp: requestTimestamp, showRed: true), // Timer handles the red highlight
                          ],
                        ),
                      ),
                    
                    if (_selectedDriverId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            // Increased size
                            _avatarFromDynamic(_selectedDriverPhoto, radius: 30), 
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedDriverName ?? 'Unknown Driver',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Text(
                                  'Active Jobs: ${selectedStats.currentAssignedJobs} • Today Done: ${selectedStats.totalJobsToday}',
                                  // Orange color indicates the driver has assigned jobs and is not free
                                  style: TextStyle(
                                      color: selectedStats.currentAssignedJobs > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    Text(
                      'Select an active driver:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    // List of Drivers
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _driverPoolAndStats
                              .where((d) => d.onDuty) // Only show active drivers
                              .map((d) {
                                final isSelected = d.driverId == _selectedDriverId;
                                return Container(
                                  color: isSelected ? Colors.lightBlue.shade50 : null,
                                  child: ListTile(
                                    onTap: () {
                                      setDialogState(() {
                                        _selectedDriverId = d.driverId;
                                        _selectedDriverName = d.driverName;
                                        _selectedDriverPhoto = d.driverPhoto;
                                      });
                                    },
                                    leading: _avatarFromDynamic(d.driverPhoto, radius: 22),
                                    title: Text(d.driverName ?? 'Unknown Driver', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      'Active Jobs: ${d.currentAssignedJobs} • Today Done: ${d.totalJobsToday}',
                                      // Orange color indicates the driver has assigned jobs and is not free
                                      style: TextStyle(color: d.currentAssignedJobs > 0 ? Colors.orange : null),
                                    ),
                                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : const Icon(Icons.chevron_right),
                                  ),
                                );
                              }).toList().cast<Widget>(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Replaced SwipeButton.expand with custom SwipeConfirm
                    if (_selectedDriverId != null)
                      SwipeConfirm(
                        label: 'Swipe to Confirm Assignment to ${_selectedDriverName ?? ''}',
                        color: Colors.blueAccent,
                        onConfirm: () {
                          Navigator.of(context).pop(); // Close dialog
                          assignDriver(car.carNo, _selectedDriverId!); // Call assignment
                        },
                      )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _carCard(Car req) {
    String? assignedDriverId;
    bool isParkingFlow = req.status == 'in_request' || req.status == 'assigned_parking' || req.status == 'parked';
    bool isBringingFlow = req.status == 'out_request' || req.status == 'assigned_bringing' || req.status == 'brought_to_client';
    bool isAssignmentNeeded = req.status == 'in_request' || req.status == 'assigned_parking' || req.status == 'out_request' || req.status == 'assigned_bringing';

    if (isParkingFlow) {
      assignedDriverId = req.driverAssignedForParking;
    } else if (isBringingFlow) {
      assignedDriverId = req.driverAssignedForBringing;
    }

    final assignedDriverData = assignedDriverId != null
        ? _driverPoolAndStats.firstWhere((d) => d.driverId == assignedDriverId,
              orElse: () => DriverStats(driverId: assignedDriverId! , totalJobsToday: 0, parkingJobsToday: 0, retrievalJobsToday: 0, currentAssignedJobs: 0, onDuty: true,))
            : null;

    final isDriverInactive = assignedDriverData != null && assignedDriverData.onDuty == true;

    // FIX 3: Expanded showTimer logic to cover all assignment phases.
    final bool showTimer = req.status == 'in_request' || req.status == 'assigned_parking' || 
                           req.status == 'out_request' || req.status == 'assigned_bringing';
    
    // The timer timestamp logic already correctly picks the timestamp based on flow
    final timerTimestamp = isParkingFlow ? req.timestampCarInRequest : req.timestampCarOutRequest;
    
    // Check for 10 min threshold only if a timer is shown
    final over10MinCheck = showTimer && timerTimestamp != null
        ? DateTime.now().difference(timerTimestamp).inMinutes >= 10
        : false;

    // FIX 2: Only apply the inactive driver red highlight if the car is in a pending job status.
    final bool applyInactiveDriverRed = isDriverInactive && 
        (req.status == 'in_request' || req.status == 'assigned_parking' || 
         req.status == 'out_request' || req.status == 'assigned_bringing');

    Color cardColor = applyInactiveDriverRed
        ? Colors.red.shade100
        : (showTimer && over10MinCheck ? Colors.red.shade50 : Colors.white);

    // Main Card
    return GestureDetector(
      onTap: isAssignmentNeeded
          ? () => _showDriverAssignmentDialog(req) // Tap to assign driver
          : null,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 72,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(req.carNo,
                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(req.status ?? '...'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valet: ${req.valetId ?? '-'}'),
                    if (req.status == 'parked') Text('Spot: ${req.parkingSpot ?? 'N/A'}'),
                    const SizedBox(height: 2),
                    
                    if (assignedDriverData != null && assignedDriverId == req.driverAssignedForParking)
                      Row(
                        children: [
                          _avatarFromDynamic(assignedDriverData.driverPhoto, radius: 15),
                          const SizedBox(width: 4),
                          Text('DriverP: ${assignedDriverData.driverName ?? assignedDriverId}'),
                          if (req.seenParking) const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          // Keep the warning icon even for parked cars, as it's useful for the manager
                          if (isDriverInactive) const Icon(Icons.warning, size: 16, color: Colors.red, semanticLabel: 'Inactive'),
                        ],
                      ),
                      
                    if (assignedDriverData != null && assignedDriverId == req.driverAssignedForBringing)
                      Row(
                        children: [
                          _avatarFromDynamic(assignedDriverData.driverPhoto, radius: 15),
                          const SizedBox(width: 4),
                          Text('DriverB: ${assignedDriverData.driverName ?? assignedDriverId}'),
                          if (req.seenBringing) const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          if (isDriverInactive) const Icon(Icons.warning, size: 16, color: Colors.red, semanticLabel: 'Inactive'),
                        ],
                      ),
                      
                    const SizedBox(height: 4),
                    if (timerTimestamp != null)
                      Row(
                        children: [
                          const Text('Requested: '),
                          Text(_dateFmt.format(timerTimestamp)),
                          if (showTimer) ...[
                            const SizedBox(width: 10),
                            const Text('Timer: '),
                            _CarTimer(timestamp: timerTimestamp, showRed: showTimer), // Timer logic handles red
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              // Replaced SwipeButton.expand with custom SwipeConfirm
              if (req.status == 'brought_to_client')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SwipeConfirm(
                    label: 'Swipe to Mark Handed Over',
                    color: Colors.green,
                    onConfirm: () {
                      markHandedOver(req.carNo);
                    },
                  ),
                ),
              // Hint for assignment
              if (isAssignmentNeeded && req.status != 'brought_to_client')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Tap card to assign driver manually.',
                    style: TextStyle(color: Colors.blueGrey.shade600, fontStyle: FontStyle.italic),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  void _showDriverPool() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Driver Pool', style: GoogleFonts.montserrat()),
          content: SizedBox(
            width: double.maxFinite,
            child: _driverPoolAndStats.isEmpty
                ? const Text('No drivers')
                : SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _driverPoolAndStats.map((d) {
                          final id = d.driverId;
                          return ListTile(
                            leading: _avatarFromDynamic(d.driverPhoto, radius: 22),
                            title: Text(d.driverName ?? id),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('ID: $id'),
                              Text('Status: ${d.onDuty ? 'Active' : 'Inactive'}', style: TextStyle(color: d.onDuty ? Colors.green : Colors.red)),
                              Text('Current Jobs: ${d.currentAssignedJobs} • Today Done: ${d.totalJobsToday}'),
                              if (!d.onDuty && d.lastLogout != null) Text('Last Logged Out: ${_dateFmt.format(d.lastLogout!)}'),
                            ]),
                          );
                        }).toList().cast<Widget>(),
                      ),
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
        );
      },
    );
  }

  void _showDriverStatsDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Driver Performance', style: GoogleFonts.montserrat()),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _driverPoolAndStats.isEmpty
                    ? [const Text('No stats available.')]
                    : _driverPoolAndStats.map((stats) {
                        return ListTile(
                          leading: _avatarFromDynamic(stats.driverPhoto),
                          title: Text(stats.driverName ?? stats.driverId, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          subtitle: Text('Total Jobs: ${stats.totalJobsToday}\nParking: ${stats.parkingJobsToday} • Retrieval: ${stats.retrievalJobsToday}\nCurrently Assigned: ${stats.currentAssignedJobs}', 
                            // Orange color indicates the driver has assigned jobs and is not free
                            style: TextStyle(color: stats.currentAssignedJobs > 0 ? Colors.orange.shade800 : null),
                          ),
                          trailing: Icon(stats.onDuty ? Icons.check_circle : Icons.person_off, color: stats.onDuty ? Colors.green : Colors.red),
                        );
                      }).toList().cast<Widget>(),
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Car> filtered(String tab) {
      final tabRequests = _requests.where((c) {
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

      final currentSearch = _searchControllers[tab]?.text.toLowerCase() ?? '';
      if (currentSearch.isEmpty) return tabRequests;

      return tabRequests.where((car) => car.carNo.toLowerCase().contains(currentSearch)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manager • Site ${widget.siteNo}', style: GoogleFonts.montserrat()),
        actions: [
          IconButton(onPressed: _showDriverStatsDialog, icon: const Icon(Icons.leaderboard)),
          IconButton(onPressed: _showDriverPool, icon: const Icon(Icons.people)),
          IconButton(onPressed: () => Navigator.of(context).pushReplacementNamed('/login'), icon: const Icon(Icons.logout)),
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
          onTap: (_) => setState(() {}),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtl,
              children: [
                _buildList(filtered('Car In'), 'Car In'),
                _buildList(filtered('Car Out'), 'Car Out'),
                _buildList(filtered('Parked'), 'Parked'),
                _buildList(filtered('Ready'), 'Ready'),
                _buildList(filtered('Completed'), 'Completed'),
              ],
            ),
    );
  }

  Widget _buildList(List<Car> list, String tabLabel) {
    list.sort((a, b) {
      // Sort by the earliest request time
      final timestampA = a.timestampCarInRequest ?? a.timestampCarOutRequest;
      final timestampB = b.timestampCarInRequest ?? b.timestampCarOutRequest;

      if (timestampA == null && timestampB == null) return 0;
      if (timestampA == null) return 1;
      if (timestampB == null) return -1;
      // Note: Comparing B to A sorts descending (newest first), which is typical for request queues
      return timestampB.compareTo(timestampA);
    });

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextField(
              controller: _searchControllers[tabLabel],
              decoration: InputDecoration(
                labelText: 'Search by Car No. in "$tabLabel"',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchControllers[tabLabel]?.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No cars found'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => _carCard(list[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
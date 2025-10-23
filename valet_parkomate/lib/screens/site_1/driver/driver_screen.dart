// lib/screens/site_1/driver/driver_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valet_parkomate/models/car.dart';
import 'package:valet_parkomate/services/api_service.dart';
import 'package:valet_parkomate/services/notification_service.dart';
import 'package:valet_parkomate/ui/shared/toast.dart';

/// Swipe-to-confirm widget
class SwipeConfirm extends StatefulWidget {
  final String label;
  final VoidCallback onConfirm;
  final Color color;
  final bool disabled;
  final double height;
  const SwipeConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.color = Colors.blueAccent,
    this.disabled = false,
    this.height = 56,
  });

  @override
  State<SwipeConfirm> createState() => _SwipeConfirmState();
}

class _SwipeConfirmState extends State<SwipeConfirm> with SingleTickerProviderStateMixin {
  double _dragX = 0.0;
  double _maxDrag = 0.0;
  bool _confirmed = false;
  late AnimationController _resetController;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))
      ..addListener(() {
        setState(() {
          _dragX = _dragX * (1 - _resetController.value);
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails d) {
    if (widget.disabled || _confirmed) return;
    _resetController.stop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (widget.disabled || _confirmed) return;
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (widget.disabled || _confirmed) return;
    final threshold = _maxDrag * 0.75;
    if (_dragX >= threshold) {
      setState(() {
        _confirmed = true;
        _dragX = _maxDrag;
      });
      Future.delayed(const Duration(milliseconds: 150), () {
        widget.onConfirm();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _confirmed = false;
              _dragX = 0.0;
            });
          }
        });
      });
    } else {
      _resetController.reset();
      _resetController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      _maxDrag = max(48.0, constraints.maxWidth - (widget.height + 16));
      final percent = (_maxDrag == 0) ? 0.0 : (_dragX / _maxDrag).clamp(0.0, 1.0);
      return Opacity(
        opacity: widget.disabled ? 0.6 : 1.0,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(color: widget.color.withOpacity(0.25)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned.fill(
                child: Center(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      color: widget.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                left: 0,
                child: FractionallySizedBox(
                  widthFactor: percent,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _dragX,
                child: GestureDetector(
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: widget.height,
                    height: widget.height,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [BoxShadow(color: widget.color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Driver Screen
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

  bool _sessionActive = false;
  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  bool _cameraInitializing = false;
  String? _capturedBase64;
  final TextEditingController _nameCtl = TextEditingController();
  bool _isStartingSession = false;
  bool _isStoppingSession = false;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowSessionModal();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _cameraController?.dispose();
    _nameCtl.dispose();
    super.dispose();
  }

  // ================= Camera =================
  Future<void> _initCamera() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) return;
    setState(() => _cameraInitializing = true);
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras == null || _availableCameras!.isEmpty) throw Exception('No cameras found');
      _cameraIndex = _cameraIndex.clamp(0, _availableCameras!.length - 1);
      final cam = _availableCameras![_cameraIndex];
      _cameraController = CameraController(cam, ResolutionPreset.medium, imageFormatGroup: ImageFormatGroup.jpeg);
      await _cameraController!.initialize();
    } catch (e) {
      Toast.show(context, 'Camera init failed: $e');
      _cameraController = null;
    } finally {
      if (mounted) setState(() => _cameraInitializing = false);
    }
  }

  Future<void> _disposeCamera() async {
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;
  }

  Future<void> _switchCamera() async {
    if (_availableCameras == null || _availableCameras!.isEmpty) return;
    _cameraIndex = (_cameraIndex + 1) % _availableCameras!.length;
    await _disposeCamera();
    await _initCamera();
    if (mounted) setState(() {});
  }

  Future<void> _capturePhoto({bool showToastOnSuccess = false}) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      Toast.show(context, 'Camera not ready');
      return;
    }
    try {
      final xfile = await _cameraController!.takePicture();
      final bytes = await xfile.readAsBytes();
      _capturedBase64 = base64Encode(bytes);
      if (showToastOnSuccess) Toast.show(context, 'Photo captured', isSuccess: true);
      if (mounted) setState(() {});
    } catch (e) {
      Toast.show(context, 'Capture failed: $e');
    }
  }

  Future<void> _capturePhotoBySwipe() async {
    await _capturePhoto(showToastOnSuccess: true);
  }

  // ================= Session Start/Stop =================
  Future<void> _startSession() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      Toast.show(context, 'Enter your name');
      return;
    }
    if (_capturedBase64 == null) {
      Toast.show(context, 'Capture a photo');
      return;
    }

    setState(() => _isStartingSession = true);
    try {
      final payload = {
        'driver_id': widget.driverId,
        'site_no': widget.siteNo,
        'driver_name': name,
        'driver_photo': 'data:image/png;base64,$_capturedBase64',
      };
      final res = await ApiService().post('api/site_${widget.siteNo}/driver-session/start', payload);
      Toast.show(context, res['message'] ?? 'Session started', isSuccess: true);
      _sessionActive = true;
      _startPolling();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      Toast.show(context, 'Start session failed');
    } finally {
      if (mounted) setState(() => _isStartingSession = false);
    }
  }

  Future<void> _endSessionAndLogout() async {
    if (_isStoppingSession) return;
    setState(() => _isStoppingSession = true);
    try {
      await ApiService().post('api/site_${widget.siteNo}/driver-session/end', {
        'driver_id': widget.driverId,
        'site_no': widget.siteNo,
      });
      Toast.show(context, 'Session ended', isSuccess: true);
    } catch (_) {}
    finally {
      setState(() => _isStoppingSession = false);
      _sessionActive = false;
      _stopPolling();
      await _disposeCamera();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  // ================= Polling =================
  void _startPolling() {
    _timer?.cancel();
    loadTasks();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => loadTasks());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> loadTasks() async {
    if (!_sessionActive) return;
    if (widget.driverId.isEmpty) return;
    try {
      final res = await ApiService().get('api/site_${widget.siteNo}/driver-tasks/${widget.siteNo}/${Uri.encodeComponent(widget.driverId)}');
      if (res is List) {
        final newTasks = res.map((e) => Car.fromJson(Map<String, dynamic>.from(e))).toList();
        _handleNotifications(newTasks);
        if (mounted) setState(() => _tasks = newTasks);
      }
    } catch (_) {}
  }

  void _handleNotifications(List<Car> tasks) {
    final currentCarNos = tasks.map((t) => t.carNo).toSet();
    final prevCarNos = _tasks.map((t) => t.carNo).toSet();

    final newAssignments = currentCarNos.difference(prevCarNos);
    for (final carNo in newAssignments) {
      NotificationService().notifyWithSound(title: 'New Task', body: 'Assigned: $carNo');
    }

    for (final task in tasks) {
      final prevStatus = _prevStatus[task.carNo];
      if (prevStatus != null && prevStatus != task.status) {
        NotificationService().notifyWithSound(title: 'Task Updated', body: '${task.carNo}: ${task.status}');
      }
      _prevStatus[task.carNo] = task.status;
    }
  }

  // ================= Actions =================
  Future<void> _markSeen(String carNo, String type) async {
    try {
      await ApiService().post('api/site_${widget.siteNo}/driver-seen', {
        'car_no': carNo,
        'site_no': widget.siteNo,
        'driver_id': widget.driverId,
        'type': type,
      });
    } catch (_) {}
  }

  Future<void> _markParked(String carNo, String spot) async {
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/mark-parked', {
        'car_no': carNo,
        'parking_spot': spot,
        'site_no': widget.siteNo,
      });
      Toast.show(context, res['message'] ?? 'Marked parked', isSuccess: true);
      await loadTasks();
    } catch (_) {
      Toast.show(context, 'Failed to mark parked');
    }
  }

  Future<void> _markBrought(String carNo) async {
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/mark-brought', {
        'car_no': carNo,
        'site_no': widget.siteNo,
      });
      Toast.show(context, res['message'] ?? 'Marked brought', isSuccess: true);
      await loadTasks();
    } catch (_) {
      Toast.show(context, 'Failed to mark brought');
    }
  }

  // ================= Session Modal =================
  Future<void> _maybeShowSessionModal() async {
    if (_sessionActive) return;
    await _showSessionModal();
  }

  Future<void> _showSessionModal() async {
    await _initCamera();
    if (!mounted) return;

    _capturedBase64 = null;
    _nameCtl.text = '';

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return WillPopScope(
            onWillPop: () async => false, // Disable back button
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StatefulBuilder(
                    builder: (ctx2, setLocal) {
                      Widget cameraArea() {
                        if (_cameraInitializing) return const Center(child: CircularProgressIndicator());
                        if (_cameraController == null || !_cameraController!.value.isInitialized)
                          return const Center(child: Text('Camera not available'));
                        return SizedBox(
                          height: 300,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CameraPreview(_cameraController!),
                          ),
                        );
                      }

                      Widget capturedPreview() {
                        if (_capturedBase64 == null) return const SizedBox.shrink();
                        final bytes = base64Decode(_capturedBase64!);
                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            SizedBox(height: 140, child: Image.memory(bytes)),
                          ],
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    if (_nameCtl.text.trim().isNotEmpty && _capturedBase64 != null) {
                                      Navigator.of(context).pop();
                                    } else {
                                      Toast.show(context, 'Name and photo required to start session');
                                    }
                                  },
                                ),
                              ],
                            ),
                            Text(
                              'Start Temporary Driver Session',
                              style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameCtl,
                              decoration: const InputDecoration(labelText: 'Enter your name'),
                              onChanged: (_) => setLocal(() {}),
                            ),
                            const SizedBox(height: 12),
                            cameraArea(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SwipeConfirm(
                                    label: _capturedBase64 == null ? 'Swipe to capture photo' : 'Swipe to retake photo',
                                    color: Colors.deepPurple,
                                    disabled: _cameraController == null || !_cameraController!.value.isInitialized,
                                    onConfirm: () async {
                                      await _capturePhoto(showToastOnSuccess: true);
                                      setLocal(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _availableCameras != null && _availableCameras!.length > 1
                                      ? () async {
                                          await _switchCamera();
                                          setLocal(() {});
                                        }
                                      : null,
                                  icon: const Icon(Icons.flip_camera_android),
                                ),
                              ],
                            ),
                            capturedPreview(),
                            const SizedBox(height: 12),
                            SwipeConfirm(
                              label: 'Swipe to start session',
                              color: Colors.green,
                              disabled: _capturedBase64 == null || _nameCtl.text.trim().isEmpty || _isStartingSession,
                              onConfirm: _startSession,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (!_sessionActive) await _disposeCamera();
  }

  // ================= Task Details / Double Confirm =================
  void _showTaskDetailsModal(Car task) async {
    await _markSeen(task.carNo, task.status == 'assigned_parking' ? 'parking' : 'bringing');

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setLocal) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Task Details', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop())
                      ]),
                      const SizedBox(height: 8),
                      _buildDetailRow('Car Number', task.carNo),
                      _buildDetailRow('Valet ID', task.valetId ?? '-'),
                      _buildDetailRow('Status', task.status ?? '-'),
                      if (task.status == 'assigned_bringing') _buildDetailRow('Parking Spot', task.parkingSpot ?? 'N/A'),
                      const SizedBox(height: 20),
                      if (task.status == 'assigned_parking')
                        _ParkSpotAndConfirm(
                          onFirstConfirm: (spot) async {
                            await _showParkDoubleConfirm(task.carNo, task.valetId ?? '-', spot);
                            if (mounted) Navigator.of(ctx).pop(); // close first modal after double confirm
                          },
                        ),
                      if (task.status == 'assigned_bringing')
                        SwipeConfirm(
                          label: 'Swipe to mark as brought (first confirm)',
                          color: Colors.orange,
                          onConfirm: () async {
                            await _showBroughtDoubleConfirm(task.carNo);
                            if (mounted) Navigator.of(ctx).pop(); // close first modal after double confirm
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Future<void> _showParkDoubleConfirm(String carNo, String valetId, String spot) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StatefulBuilder(
                  builder: (ctx2, setLocal) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.red))
                        ]),
                        Text('Confirm Parking', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildDetailRow('Car', carNo),
                        _buildDetailRow('Valet ID', valetId),
                        _buildDetailRow('Spot', spot),
                        const SizedBox(height: 20),
                        SwipeConfirm(
                          label: 'Swipe to confirm parked',
                          color: Colors.green,
                          onConfirm: () async {
                            Navigator.of(context).pop();
                            await _markParked(carNo, spot);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _showBroughtDoubleConfirm(String carNo) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StatefulBuilder(
                  builder: (ctx2, setLocal) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.red))
                        ]),
                        Text('Confirm Delivery', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildDetailRow('Car', carNo),
                        const SizedBox(height: 20),
                        SwipeConfirm(
                          label: 'Swipe to confirm brought to client',
                          color: Colors.green,
                          onConfirm: () async {
                            Navigator.of(context).pop();
                            await _markBrought(carNo);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  // ================= Task List =================
  @override
  Widget build(BuildContext context) {
    final parkingTasks = _tasks.where((t) => t.status == 'assigned_parking').toList();
    final bringingTasks = _tasks.where((t) => t.status == 'assigned_bringing').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver • Site ${widget.siteNo}', style: GoogleFonts.montserrat()),
        actions: [
          IconButton(
            onPressed: _endSessionAndLogout,
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
      floatingActionButton: !_sessionActive
          ? FloatingActionButton.extended(
              onPressed: _showSessionModal,
              label: const Text('Start Session'),
              icon: const Icon(Icons.play_arrow),
            )
          : null,
    );
  }

  Widget _buildTaskList(List<Car> list) {
    if (list.isEmpty) return Center(child: Text('No tasks found.', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)));
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
              child: Row(children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(8)),
                  child: Text(task.carNo.split('').join('\n'), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Car: ${task.carNo}', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('Status: ${task.status}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
                    if (task.valetId != null) Text('Valet ID: ${task.valetId}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45)),
                  ]),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// Parking spot first swipe widget
class _ParkSpotAndConfirm extends StatefulWidget {
  final Future<void> Function(String spot) onFirstConfirm;
  const _ParkSpotAndConfirm({required this.onFirstConfirm});

  @override
  State<_ParkSpotAndConfirm> createState() => _ParkSpotAndConfirmState();
}

class _ParkSpotAndConfirmState extends State<_ParkSpotAndConfirm> {
  final TextEditingController _spotCtl = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _spotCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        controller: _spotCtl,
        decoration: InputDecoration(labelText: 'Enter Parking Spot', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
      const SizedBox(height: 12),
      SwipeConfirm(
        label: 'Swipe to propose parking spot',
        color: Colors.blueAccent,
        disabled: _spotCtl.text.trim().isEmpty || _isProcessing,
        onConfirm: () async {
          final s = _spotCtl.text.trim();
          if (s.isEmpty) {
            Toast.show(context, 'Please enter a spot first');
            return;
          }
          setState(() => _isProcessing = true);
          try {
            await widget.onFirstConfirm(s);
          } finally {
            setState(() => _isProcessing = false);
          }
        },
      ),
    ]);
  }
}

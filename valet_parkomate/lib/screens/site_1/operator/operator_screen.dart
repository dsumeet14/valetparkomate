import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/site_config.dart';
import '../../../models/car.dart';
import '../../../services/api_service.dart';
import '../../../services/notification_service.dart';
import '../../../ui/shared/toast.dart';

class OperatorScreen extends StatefulWidget {
  final int siteNo;
  const OperatorScreen({super.key, required this.siteNo});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  final _carNoCtl = TextEditingController();
  final _valetIdCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  List<Car> _todayCars = [];
  Timer? _timer;
  final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');
  final Set<String> _knownCars = {};
  String? _lastLink;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _loadData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _carNoCtl.dispose();
    _valetIdCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiService()
          .get('api/site_${widget.siteNo}/admin-car-today/${widget.siteNo}');
      if (res is List) {
        final cars = res.map((e) => Car.fromJson(Map<String, dynamic>.from(e))).toList();
        final incoming = cars.map((c) => c.carNo).where((n) => !_knownCars.contains(n)).toList();
        if (incoming.isNotEmpty) {
          for (final n in incoming) {
            NotificationService()
                .notifyWithSound(title: 'New Car In', body: '$n (site ${widget.siteNo})');
          }
        }
        _knownCars.addAll(cars.map((c) => c.carNo));
        if (mounted) {
          setState(() => _todayCars = cars);
        }
      }
    } catch (e) {
      // Toast.show(context, 'Failed to load data');
    }
  }

  Future<void> submitCarIn() async {
    final carNo = _carNoCtl.text.trim();
    final valetId = _valetIdCtl.text.trim();
    final phone = _phoneCtl.text.trim();

    if (carNo.isEmpty || valetId.isEmpty) {
      Toast.show(context, 'Car number and valet ID are required.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/car-in', {
        'car_no': carNo,
        'valet_id': valetId,
        'phone_number': phone.isEmpty ? null : phone,
        'site_no': widget.siteNo
      });
      Toast.show(context, res['message'] ?? 'Submitted successfully');
      final link = '${ApiService().uri('')}site_${widget.siteNo}/client.html?site_no=${widget.siteNo}&valet_id=${Uri.encodeComponent(valetId)}';
      setState(() {
        _lastLink = link;
        _carNoCtl.clear();
        _valetIdCtl.clear();
        _phoneCtl.clear();
      });
      _loadData();

      if (mounted && _lastLink != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Client Link & QR Code'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(_lastLink!),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: QrImageView(data: _lastLink!),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _printQrCode,
                    icon: const Icon(Icons.print),
                    label: const Text('Print QR'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Toast.show(context, 'Error submitting car-in. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _printQrCode() async {
    if (_lastLink == null) {
      Toast.show(context, 'No QR code to print.');
      return;
    }
    
    final qrImageData = await QrPainter(
      data: _lastLink!,
      gapless: true,
      version: QrVersions.auto,
    ).toImageData(200);

    if (qrImageData == null) return;

    final doc = pw.Document();
    final image = pw.MemoryImage(qrImageData.buffer.asUint8List());

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Scan to Get Your Car',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Image(image),
                pw.SizedBox(height: 20),
                pw.Text(
                  _lastLink!,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Widget _buildCarRow(Car c) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 80,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            c.carNo,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          'Valet ID: ${c.valetId ?? 'N/A'}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${c.status ?? 'N/A'}'),
            Text('Time: ${_dateFmt.format(c.timestampCarInRequest ?? DateTime.now())}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = SiteConfig.forSite(widget.siteNo);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Operator • ${cfg.name ?? 'Site ${widget.siteNo}'}',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'New Car Entry',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _carNoCtl,
                        decoration: InputDecoration(
                          labelText: 'Car Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.directions_car),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _valetIdCtl,
                        decoration: InputDecoration(
                          labelText: 'Valet ID',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneCtl,
                        decoration: InputDecoration(
                          labelText: 'Phone (optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : submitCarIn,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3)) : const Icon(Icons.check_circle_outline),
                        label: Text(
                          'Submit Car In',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Today's Cars",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todayCars.length,
                itemBuilder: (_, i) => _buildCarRow(_todayCars[i]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
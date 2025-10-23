import 'package:flutter/material.dart';
// Site 1 imports
import 'site_1/operator/operator_screen.dart' as s1op;
import 'site_1/client/client_screen.dart' as s1client;
import 'site_1/driver/driver_screen.dart' as s1driver;
import 'site_1/manager/manager_screen.dart' as s1manager;
import 'site_1/admin/admin_screen.dart' as s1admin;
// Site 2 imports
import 'site_2/operator/operator_screen.dart' as s2op;
import 'site_2/client/client_screen.dart' as s2client;
import 'site_2/driver/driver_screen.dart' as s2driver;
import 'site_2/manager/manager_screen.dart' as s2manager;
import 'site_2/admin/admin_screen.dart' as s2admin;

class SiteHomeRouter extends StatelessWidget {
  final int siteNo;
  final String role;
  final String driverId; // Passes driver ID for API calls

  const SiteHomeRouter({
    super.key,
    required this.siteNo,
    required this.role,
    this.driverId = '',
  });

  @override
  Widget build(BuildContext context) {
    final r = role.toLowerCase();

    // Use a top-level switch to determine the site
    switch (siteNo) {
      case 2:
        // Handle routing for Site 2
        switch (r) {
          case 'operator':
            return s2op.OperatorScreen(siteNo: siteNo);
          case 'client':
            return s2client.ClientScreen(siteNo: siteNo);
          case 'driver':
            return s2driver.DriverScreen(siteNo: siteNo, driverId: driverId);
          case 'manager':
            return s2manager.ManagerScreen(siteNo: siteNo);
          case 'admin':
            return s2admin.AdminScreen(siteNo: siteNo);
          default:
            return s2op.OperatorScreen(siteNo: siteNo);
        }
      case 1:
      default:
        // Handle routing for Site 1 and all other sites as default
        switch (r) {
          case 'operator':
            return s1op.OperatorScreen(siteNo: siteNo);
          case 'client':
            // Pass the user ID as valetId if needed
            return s1client.ClientScreen(siteNo: siteNo, valetId: driverId);
          case 'driver':
            return s1driver.DriverScreen(siteNo: siteNo, driverId: driverId);
          case 'manager':
            return s1manager.ManagerScreen(siteNo: siteNo);
          case 'admin':
            return s1admin.AdminScreen(siteNo: siteNo);
          default:
            return s1op.OperatorScreen(siteNo: siteNo);
        }
    }
  }
}
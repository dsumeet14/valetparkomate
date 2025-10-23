import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  final int siteNo;
  const AdminScreen({super.key, required this.siteNo});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> _users = [];
  List<dynamic> _today = [];
  int? _maxUsers;
  Timer? _timer;

  final _newIdCtl = TextEditingController();
  final _passCtl = TextEditingController();
  String _newRole = 'operator';
  final _removeCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadStats();
    loadToday();
    _timer = Timer.periodic(Duration(seconds: 5), (_) {
      loadUsers();
      loadStats();
      loadToday();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _newIdCtl.dispose();
    _passCtl.dispose();
    _removeCtl.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    try {
      final res = await ApiService().get('api/site_${widget.siteNo}/admin-users/${widget.siteNo}');
      if (res is List) setState(() => _users = res);
    } catch (e) {}
  }

  Future<void> loadStats() async {
    try {
      final res = await ApiService().get('api/site_${widget.siteNo}/admin-stats/${widget.siteNo}');
      setState(() {
        _maxUsers = res['max_users'];
      });
    } catch (e) {}
  }

  Future<void> loadToday() async {
    try {
      final res = await ApiService().get('api/site_${widget.siteNo}/admin-car-today/${widget.siteNo}');
      if (res is List) setState(() => _today = res);
    } catch (e) {}
  }

  Future<void> addUser() async {
    final newId = _newIdCtl.text.trim();
    final pass = _passCtl.text.trim();
    if (newId.isEmpty || pass.isEmpty) return;
    try {
      final res = await ApiService().post('api/site_${widget.siteNo}/admin-add-user', {
        'admin_id': 'admin', // the backend checks "admin_id" for being admin — in mobile you'll need to pass real admin id
        'site_no': widget.siteNo,
        'new_id': newId,
        'password': pass,
        'role': _newRole,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Added')));
      _newIdCtl.clear();
      _passCtl.clear();
      loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add failed')));
    }
  }

  Future<void> removeUser() async {
    final id = _removeCtl.text.trim();
    if (id.isEmpty) return;
    try {
      final res = await ApiService().delete('api/site_${widget.siteNo}/admin-remove-user', body: {'admin_id': 'admin', 'site_no': widget.siteNo, 'user_id': id});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Removed')));
      _removeCtl.clear();
      loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remove failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin • Site ${widget.siteNo}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(children: [
                Text('Add User', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: _newIdCtl, decoration: InputDecoration(labelText: 'User ID')),
                TextField(controller: _passCtl, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
                DropdownButton<String>(value: _newRole, items: ['operator','driver','manager','client'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(()=>_newRole=v!)),
                Row(children: [ElevatedButton(onPressed: addUser, child: Text('Add User'))])
              ]),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(children: [
                Text('Remove User', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: _removeCtl, decoration: InputDecoration(labelText: 'User ID')),
                Row(children: [ElevatedButton(onPressed: removeUser, child: Text('Remove'))])
              ]),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(children: [
                Text('Site Stats: Users ${_users.length}/${_maxUsers ?? 'Unlimited'}'),
                Divider(),
                Text('Current Users', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: _users.isEmpty ? Center(child: Text('No users')) : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      return ListTile(title: Text(u['id']), subtitle: Text(u['role']));
                    },
                  ),
                )
              ]),
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Padding(padding: EdgeInsets.all(8), child: _today.isEmpty ? Center(child: Text('No cars today')) : ListView.builder(itemCount: _today.length, itemBuilder: (_, i) {
                final c = _today[i];
                return ListTile(title: Text(c['car_no'] ?? ''), subtitle: Text(c['status'] ?? ''));
              })),
            ),
          )
        ]),
      ),
    );
  }
}

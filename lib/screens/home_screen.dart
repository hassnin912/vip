import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';
import 'contact_form_screen.dart';
import 'wireless_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  Future<void> _loadContacts() async {
    final contacts = await _storage.getContacts();
    setState(() {
      _contacts = contacts;
      _filteredContacts = contacts;
    });
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((c) {
        return c.name.toLowerCase().contains(query) || 
               c.role.toLowerCase().contains(query) ||
               c.phoneNumber.contains(query);
      }).toList();
    });
  }

  // دالة الاتصال بعد التعديل لتنظيف الرقم من المسافات
  void _makeCall(String number) async {
    String cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إجراء الاتصال بهذا الرقم')),
        );
      }
    }
  }

  // دالة الواتساب بعد التعديل لتنظيف الرقم وفتحه في التطبيق مباشرة
  void _openWhatsApp(String number) async {
    String cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تطبيق واتساب غير مثبت أو الرقم غير صالح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر جهات اتصال VIP', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WirelessScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن جهة اتصال...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? const Center(child: Text('لا توجد جهات اتصال'))
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Text(contact.name[0], style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${contact.role} • ${contact.phoneNumber}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green),
                                onPressed: () => _makeCall(contact.phoneNumber),
                              ),
                              IconButton(
                                icon: const Icon(Icons.message, color: Colors.teal),
                                onPressed: () => _openWhatsApp(contact.phoneNumber),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ContactFormScreen(contact: contact),
                              ),
                            );
                            _loadContacts(); // تحديث القائمة بعد التعديل
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactFormScreen()),
          );
          _loadContacts(); // تحديث القائمة بعد الإضافة
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


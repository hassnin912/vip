import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';

class StorageService {
  static const String _key = 'vip_contacts';

  Future<List<Contact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString(_key);
    if (contactsJson == null) return [];
    
    List<dynamic> decoded = json.decode(contactsJson);
    return decoded.map((item) => Contact.fromMap(item)).toList();
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(contacts.map((c) => c.toMap()).toList());
    await prefs.setString(_key, encoded);
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';

class ContactForm extends StatefulWidget {
  final Contact? contact;
  ContactForm({this.contact});

  @override
  _ContactFormState createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _roleController = TextEditingController(text: widget.contact?.role ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phoneNumber ?? '');
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final contacts = await _storage.getContacts();
      if (widget.contact == null) {
        final newContact = Contact(
          id: Uuid().v4(),
          name: _nameController.text,
          role: _roleController.text,
          phoneNumber: _phoneController.text,
        );
        contacts.add(newContact);
      } else {
        final index = contacts.indexWhere((c) => c.id == widget.contact!.id);
        contacts[index] = Contact(
          id: widget.contact!.id,
          name: _nameController.text,
          role: _roleController.text,
          phoneNumber: _phoneController.text,
        );
      }
      await _storage.saveContacts(contacts);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.contact == null ? 'إضافة جهة اتصال' : 'تعديل جهة اتصال')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'الاسم'),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _roleController,
                  decoration: InputDecoration(labelText: 'الدور/الوظيفة'),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _save,
                  child: Text('حفظ'),
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

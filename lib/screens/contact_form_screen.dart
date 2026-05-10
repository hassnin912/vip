import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';

class ContactFormScreen extends StatefulWidget {
  final Contact? contact;
  const ContactFormScreen({super.key, this.contact});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
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
      final contact = Contact(
        id: widget.contact?.id ?? const Uuid().v4(),
        name: _nameController.text,
        role: _roleController.text,
        phoneNumber: _phoneController.text,
      );

      if (widget.contact == null) {
        await _storage.addContact(contact);
      } else {
        await _storage.updateContact(contact);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  void _delete() async {
    if (widget.contact != null) {
      await _storage.deleteContact(widget.contact!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'إضافة جهة اتصال' : 'تعديل جهة اتصال'),
        actions: widget.contact != null
            ? [IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _delete)]
            : [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                validator: (v) => v!.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'الدور / المسمى الوظيفي'),
                validator: (v) => v!.isEmpty ? 'يرجى إدخال الدور' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.amber,
                ),
                child: const Text('حفظ', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

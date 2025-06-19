import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, String>> _emergencyContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> contactsJson = prefs.getStringList('emergency_contacts') ?? [];
    if (mounted) {
      setState(() {
        _emergencyContacts = contactsJson
            .map((jsonString) =>
                Map<String, String>.from(jsonDecode(jsonString)))
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> contactsJson = _emergencyContacts
        .map((contactMap) => jsonEncode(contactMap))
        .toList();
    await prefs.setStringList('emergency_contacts', contactsJson);
  }

  Future<void> _addContact() async {
    if (await Permission.contacts.request().isGranted) {
      try {
        final Contact? contact = await FlutterContacts.openExternalPick();
        if (contact != null && contact.phones.isNotEmpty) {
          final String number = contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '');
          final newContact = {'id': contact.id, 'name': contact.displayName, 'number': number};

          if (!_emergencyContacts.any((c) => c['id'] == newContact['id'])) {
            setState(() {
              _emergencyContacts.add(newContact);
            });
            await _saveContacts();
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${contact.displayName} is already in the list.')),
              );
            }
          }
        } else if(contact != null) {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selected contact has no phone number.')),
            );
           }
        }
      } catch (e) {
        print('Failed to pick contact: $e');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission is required.')),
        );
      }
    }
  }

  Future<void> _removeContact(String id) async {
    setState(() {
      _emergencyContacts.removeWhere((c) => c['id'] == id);
    });
    await _saveContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _emergencyContacts.isEmpty
              ? const Center(
                  child: Text(
                    'No emergency contacts added yet.\nTap the + button to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _emergencyContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _emergencyContacts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(contact['name']![0])),
                        title: Text(contact['name']!),
                        subtitle: Text(contact['number']!),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeContact(contact['id']!),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: const Color(0xFF0B3D91),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

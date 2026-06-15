import 'package:flutter/material.dart';

import 'phone_contacts_page.dart';
import 'line_contacts_page.dart';

class ContactsMainPage extends StatelessWidget {
  const ContactsMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('聯絡人', style: TextStyle(fontSize: 28)),
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.phone), text: '電話'),
              Tab(icon: Icon(Icons.chat), text: 'Line'),
            ],
          ),
        ),
        body: const TabBarView(children: [PhoneContactsPage(), LineContactsPage()]),
      ),
    );
  }
}

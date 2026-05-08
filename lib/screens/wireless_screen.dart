import 'package:flutter/material.dart';
import '../services/nearby_service.dart';

class WirelessScreen extends StatefulWidget {
  final String userName;
  WirelessScreen({required this.userName});

  @override
  _WirelessScreenState createState() => _WirelessScreenState();
}

class _WirelessScreenState extends State<WirelessScreen> {
  late NearbyService _nearbyService;
  List<String> messages = [];
  TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nearbyService = NearbyService(
      userName: widget.userName,
      onMessageReceived: (id, msg) {
        setState(() {
          messages.add("من $id: $msg");
        });
      },
    );
    _startNearby();
  }

  void _startNearby() async {
    await _nearbyService.startAdvertising();
    await _nearbyService.startDiscovery();
  }

  @override
  void dispose() {
    _nearbyService.stopAll();
    super.dispose();
  }

  void _sendToAll() {
    if (_messageController.text.isNotEmpty) {
      _nearbyService.broadcastMessage(_messageController.text);
      setState(() {
        messages.add("أنا (للجميع): ${_messageController.text}");
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('اتصال لاسلكي (P2P)')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('الأجهزة المتصلة: ${_nearbyService.connectedDevices.length}'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) => ListTile(title: Text(messages[index])),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(hintText: 'اكتب رسالة...'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendToAll,
                    tooltip: 'إرسال للجميع',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

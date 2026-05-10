import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wireless_service.dart';

class WirelessScreen extends StatefulWidget {
  const WirelessScreen({super.key});

  @override
  State<WirelessScreen> createState() => _WirelessScreenState();
}

class _WirelessScreenState extends State<WirelessScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final wireless = Provider.of<WirelessService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الاتصال اللاسلكي VIP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('حالة الاتصال: ${wireless.isAdvertising ? "نشط" : "متوقف"}'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => wireless.isAdvertising 
                        ? wireless.stopAll() 
                        : wireless.startP2P("VIP_User"),
                      child: Text(wireless.isAdvertising ? 'إيقاف البث' : 'بدء البث والبحث'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة للمجموعة...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    wireless.sendMessageToAll(_messageController.text);
                    _messageController.clear();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('الأجهزة المتصلة:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: wireless.connectedDevices.length,
                itemBuilder: (context, index) {
                  final deviceId = wireless.connectedDevices[index];
                  return ListTile(
                    title: Text('جهاز: $deviceId'),
                    trailing: IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () {
                        wireless.sendMessageToIndividual(deviceId, "رسالة خاصة");
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

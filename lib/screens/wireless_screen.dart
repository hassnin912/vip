import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wireless_service.dart';

class WirelessScreen extends StatefulWidget {
  const WirelessScreen({super.key});

  @override
  State<WirelessScreen> createState() => _WirelessScreenState();
}

class _WirelessScreenState extends State<WirelessScreen> {
  final TextEditingController _channelIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isRoomCreator = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اللاسلكي الصوتي (Walkie-Talkie)'),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Consumer<WirelessService>(
        builder: (context, wireless, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إعدادات القناة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _channelIdController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'رقم القناة (ID)',
                                  prefixIcon: Icon(Icons.radio),
                                  border: OutlineInputBorder(),
                                ),
                                enabled: !wireless.isConnectedToRoom,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'الرقم السري (اختياري)',
                                  prefixIcon: Icon(Icons.lock),
                                  border: OutlineInputBorder(),
                                ),
                                obscureText: true,
                                enabled: !wireless.isConnectedToRoom,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        if (!wireless.isConnectedToRoom)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_channelIdController.text.isEmpty) {
                                    _showSnack('يرجى إدخال رقم القناة أولاً');
                                    return;
                                  }
                                  setState(() => _isRoomCreator = true);
                                  wireless.createRoom(
                                    _channelIdController.text,
                                    _passwordController.text,
                                  );
                                  _showSnack('جاري إنشاء القناة...');
                                },
                                icon: const Icon(Icons.cell_tower),
                                label: const Text('إنشاء وبث'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[800],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_channelIdController.text.isEmpty) {
                                    _showSnack('يرجى إدخال رقم القناة أولاً');
                                    return;
                                  }
                                  setState(() => _isRoomCreator = false);
                                  wireless.joinRoom(
                                    _channelIdController.text,
                                    _passwordController.text,
                                  );
                                  _showSnack('جاري البحث عن القناة...');
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('بحث وانضمام'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          )
                        else
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                wireless.disconnectRoom();
                                _channelIdController.clear();
                                _passwordController.clear();
                                _showSnack('تم قطع الاتصال');
                              },
                              icon: const Icon(Icons.stop_circle),
                              label: const Text('قطع الاتصال / مغادرة القناة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  wireless.isConnectedToRoom
                      ? 'متصل بالقناة: ${_channelIdController.text} 🟢'
                      : 'غير متصل بأي قناة 🔴',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: wireless.isConnectedToRoom ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 30),

                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onLongPressStart: (_) {
                        if (wireless.isConnectedToRoom) {
                          wireless.startRecording();
                        } else {
                          _showSnack('يجب الانضمام لقناة أولاً!');
                        }
                      },
                      onLongPressEnd: (_) {
                        if (wireless.isConnectedToRoom) {
                          wireless.stopRecordingAndSend();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: wireless.isRecording ? 180 : 150,
                        height: wireless.isRecording ? 180 : 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !wireless.isConnectedToRoom
                              ? Colors.grey
                              : (wireless.isRecording ? Colors.red : Colors.green[600]),
                          boxShadow: [
                            BoxShadow(
                              color: wireless.isRecording
                                  ? Colors.redAccent.withOpacity(0.6)
                                  : Colors.black26,
                              blurRadius: wireless.isRecording ? 30 : 10,
                              spreadRadius: wireless.isRecording ? 10 : 2,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              wireless.isRecording ? Icons.mic : Icons.mic_none,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              wireless.isRecording ? 'جاري التحدث...' : 'اضغط وتحدث',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Divider(),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('الأجهزة المتصلة بالقناة:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 1,
                  child: wireless.connectedDevices.isEmpty
                      ? const Center(
                          child: Text(
                            'لا يوجد أشخاص في القناة حالياً',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: wireless.connectedDevices.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.headset_mic, color: Colors.blueGrey),
                              title: Text(wireless.connectedDevices[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

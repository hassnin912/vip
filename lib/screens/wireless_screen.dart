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
  bool _isRoomCreator = false; // عشان نعرف هل هو اللي بيكريت الغرفة ولا بينضم ليها

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اللاسلكي الصوتي (Walkie-Talkie)'),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      // استخدمنا Consumer عشان نحدث الشاشة بكفاءة
      body: Consumer<WirelessService>(
        builder: (context, wireless, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // ==========================================
                // 1. إعدادات الغرفة / القناة
                // ==========================================
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
                                enabled: !wireless.isConnectedToRoom, // يتقفل لو هو متصل
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
                        // أزرار إنشاء أو الانضمام للغرفة
                        if (!wireless.isConnectedToRoom)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_channelIdController.text.isNotEmpty) {
                                    setState(() => _isRoomCreator = true);
                                    // دالة هنضيفها في الـ Service
                                    wireless.createRoom(_channelIdController.text, _passwordController.text);
                                  }
                                },
                                icon: const Icon(Icons.cell_tower),
                                label: const Text('إنشاء وبث'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_channelIdController.text.isNotEmpty) {
                                    setState(() => _isRoomCreator = false);
                                    // دالة هنضيفها في الـ Service
                                    wireless.joinRoom(_channelIdController.text, _passwordController.text);
                                  }
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('بحث وانضمام'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
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
                              },
                              icon: const Icon(Icons.stop_circle),
                              label: const Text('قطع الاتصال / مغادرة القناة'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ==========================================
                // 2. حالة الاتصال
                // ==========================================
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

                // ==========================================
                // 3. زرار الـ Walkie-Talkie (Push to Talk)
                // ==========================================
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      // لما يضغط ويفضل دايس (يبدأ تسجيل)
                      onLongPressStart: (_) {
                        if (wireless.isConnectedToRoom) {
                          wireless.startRecording();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يجب الانضمام لقناة أولاً!')),
                          );
                        }
                      },
                      // لما يشيل إيده (يوقف تسجيل ويبعت الصوت)
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
                              color: wireless.isRecording ? Colors.redAccent.withOpacity(0.6) : Colors.black26,
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // ==========================================
                // 4. الأعضاء المتصلين
                // ==========================================
                const Divider(),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('الأجهزة المتصلة بالقناة:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 1,
                  child: wireless.connectedDevices.isEmpty
                      ? const Center(child: Text('لا يوجد أشخاص في القناة حالياً', style: TextStyle(color: Colors.grey)))
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

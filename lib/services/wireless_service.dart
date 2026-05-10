import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class WirelessService extends ChangeNotifier {
  final Strategy strategy = Strategy.P2P_STAR; // مناسب للغرف المتعددة
  
  List<String> connectedDevices = [];
  bool isConnectedToRoom = false;
  bool isRecording = false;

  // أدوات الصوت
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentAudioPath;
  
  // لحفظ مسارات الملفات اللي بتتبعت
  final Map<int, String> _incomingFiles = {};

  // ==========================================
  // 1. إنشاء غرفة (بث)
  // ==========================================
  Future<void> createRoom(String channelId, String password) async {
    // دمج القناة والباسورد لعمل تردد فريد (Service ID)
    String roomFrequency = "vip_room_${channelId}_$password";
    String myName = "VIP_Creator"; // ممكن تخلي المستخدم يكتب اسمه

    try {
      bool a = await Nearby().startAdvertising(
        myName,
        strategy,
        serviceId: roomFrequency, // التردد السري
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            connectedDevices.add(id);
            isConnectedToRoom = true;
            notifyListeners();
          }
        },
        onDisconnected: (id) {
          connectedDevices.remove(id);
          if (connectedDevices.isEmpty) isConnectedToRoom = false;
          notifyListeners();
        },
      );
      
      if (a) {
        isConnectedToRoom = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error creating room: $e");
    }
  }

  // ==========================================
  // 2. الانضمام لغرفة (بحث)
  // ==========================================
  Future<void> joinRoom(String channelId, String password) async {
    String roomFrequency = "vip_room_${channelId}_$password";
    String myName = "VIP_Member";

    try {
      bool d = await Nearby().startDiscovery(
        myName,
        strategy,
        serviceId: roomFrequency, // لازم يطابق التردد السري
        onEndpointFound: (id, name, serviceId) {
          // أول ما يلاقي الغرفة، يطلب الانضمام فوراً
          Nearby().requestConnection(
            myName,
            id,
            onConnectionInitiated: onConnectionInit,
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                connectedDevices.add(id);
                isConnectedToRoom = true;
                Nearby().stopDiscovery(); // نوقف بحث عشان نوفر بطارية
                notifyListeners();
              }
            },
            onDisconnected: (id) {
              connectedDevices.remove(id);
              if (connectedDevices.isEmpty) isConnectedToRoom = false;
              notifyListeners();
            },
          );
        },
        onEndpointLost: (id) {},
      );
      
      if (d) {
        // جاري البحث... سيتم تحديث الحالة عند الاتصال
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error joining room: $e");
    }
  }

  // ==========================================
  // 3. تهيئة الاتصال واستقبال الصوت
  // ==========================================
  void onConnectionInit(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        // لما يوصل ملف (رسالة صوتية)
        if (payload.type == PayloadType.FILE) {
          _incomingFiles[payload.id] = payload.filePath ?? '';
        }
      },
      onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) async {
        // لما الملف يكتمل تحميله بالكامل
        if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
          String? path = _incomingFiles[payloadTransferUpdate.id];
          if (path != null && path.isNotEmpty) {
            // تشغيل الصوت فوراً زي اللاسلكي
            await _audioPlayer.play(DeviceFileSource(path));
          }
        }
      },
    );
  }

  // ==========================================
  // 4. تسجيل الصوت (عند الضغط)
  // ==========================================
  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _currentAudioPath = '${dir.path}/vip_walkie_talkie.m4a';
      
      // بدء التسجيل
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc), // صيغة خفيفة وسريعة
        path: _currentAudioPath!,
      );
      
      isRecording = true;
      notifyListeners();
    }
  }

  // ==========================================
  // 5. إيقاف التسجيل وإرسال الصوت (عند رفع الإصبع)
  // ==========================================
  Future<void> stopRecordingAndSend() async {
    final path = await _audioRecorder.stop();
    isRecording = false;
    notifyListeners();

    if (path != null && connectedDevices.isNotEmpty) {
      // إرسال الملف الصوتي لكل الأجهزة المتصلة بالقناة
      for (String deviceId in connectedDevices) {
        await Nearby().sendFilePayload(deviceId, path);
      }
    }
  }

  // ==========================================
  // 6. قطع الاتصال
  // ==========================================
  void disconnectRoom() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    connectedDevices.clear();
    isConnectedToRoom = false;
    isRecording = false;
    notifyListeners();
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class WirelessService extends ChangeNotifier {
  final Strategy strategy = Strategy.P2P_STAR;
  
  List<String> connectedDevices = [];
  bool isConnectedToRoom = false;
  bool isRecording = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Record _audioRecorder = Record();
  String? _currentAudioPath;
  
  final Map<int, String> _incomingFiles = {};

  Future<void> createRoom(String channelId, String password) async {
    String roomFrequency = "vip_room_${channelId}_$password";
    String myName = "VIP_Creator";

    try {
      bool a = await Nearby().startAdvertising(
        myName,
        strategy,
        serviceId: roomFrequency,
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

  Future<void> joinRoom(String channelId, String password) async {
    String roomFrequency = "vip_room_${channelId}_$password";
    String myName = "VIP_Member";

    try {
      bool d = await Nearby().startDiscovery(
        myName,
        strategy,
        serviceId: roomFrequency,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            myName,
            id,
            onConnectionInitiated: onConnectionInit,
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                connectedDevices.add(id);
                isConnectedToRoom = true;
                Nearby().stopDiscovery();
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
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error joining room: $e");
    }
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.FILE) {
          _incomingFiles[payload.id] = payload.filePath ?? '';
        }
      },
      onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) async {
        if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
          String? path = _incomingFiles[payloadTransferUpdate.id];
          if (path != null && path.isNotEmpty) {
            await _audioPlayer.play(DeviceFileSource(path));
          }
        }
      },
    );
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _currentAudioPath = '${dir.path}/vip_walkie_talkie.m4a';
      
      await _audioRecorder.start(
        path: _currentAudioPath!,
        encoder: AudioEncoder.aacLc,
      );
      
      isRecording = true;
      notifyListeners();
    }
  }

  Future<void> stopRecordingAndSend() async {
    final path = await _audioRecorder.stop();
    isRecording = false;
    notifyListeners();

    if (path != null && connectedDevices.isNotEmpty) {
      for (String deviceId in connectedDevices) {
        await Nearby().sendFilePayload(deviceId, path);
      }
    }
  }

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

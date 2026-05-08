import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';

class NearbyService {
  final Strategy strategy = Strategy.P2P_STAR;
  String userName;
  List<String> connectedDevices = [];
  Function(String, String)? onMessageReceived;

  NearbyService({required this.userName, this.onMessageReceived});

  Future<bool> startAdvertising() async {
    try {
      return await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {
            if (payload.type == PayloadType.BYTES) {
              String message = String.fromCharCodes(payload.bytes!);
              onMessageReceived?.call(id, message);
            }
          });
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            connectedDevices.add(id);
          }
        },
        onDisconnected: (id) {
          connectedDevices.remove(id);
        },
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> startDiscovery() async {
    try {
      return await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: (id, info) {
              Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {
                if (payload.type == PayloadType.BYTES) {
                  String message = String.fromCharCodes(payload.bytes!);
                  onMessageReceived?.call(id, message);
                }
              });
            },
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                connectedDevices.add(id);
              }
            },
            onDisconnected: (id) {
              connectedDevices.remove(id);
            },
          );
        },
        onEndpointLost: (id) {},
      );
    } catch (e) {
      return false;
    }
  }

  void sendMessage(String endpointId, String message) {
    Nearby().sendPayload(Payload.fromBytes(Uint8List.fromList(message.codeUnits)), endpointId);
  }

  void broadcastMessage(String message) {
    for (String id in connectedDevices) {
      sendMessage(id, message);
    }
  }

  void stopAll() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    connectedDevices.clear();
  }
}

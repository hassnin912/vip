import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter/foundation.dart';

class WirelessService extends ChangeNotifier {
  final Strategy strategy = Strategy.P2P_STAR;
  String userName = "VIP_User";
  List<String> connectedDevices = [];
  bool isAdvertising = false;
  bool isDiscovering = false;

  Future<void> startP2P(String name) async {
    userName = name;
    try {
      bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            connectedDevices.add(id);
            notifyListeners();
          }
        },
        onDisconnected: (id) {
          connectedDevices.remove(id);
          notifyListeners();
        },
      );
      isAdvertising = a;
      
      bool d = await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: onConnectionInit,
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                connectedDevices.add(id);
                notifyListeners();
              }
            },
            onDisconnected: (id) {
              connectedDevices.remove(id);
              notifyListeners();
            },
          );
        },
        onEndpointLost: (id) {},
      );
      isDiscovering = d;
      notifyListeners();
    } catch (e) {
      debugPrint("Error in Wireless Service: $e");
    }
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {
      // Handle received data
    });
  }

  Future<void> sendMessageToAll(String message) async {
    for (String id in connectedDevices) {
      await Nearby().sendBytesPayload(id, Uint8List.fromList(message.codeUnits));
    }
  }

  Future<void> sendMessageToIndividual(String id, String message) async {
    await Nearby().sendBytesPayload(id, Uint8List.fromList(message.codeUnits));
  }

  void stopAll() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    connectedDevices.clear();
    isAdvertising = false;
    isDiscovering = false;
    notifyListeners();
  }
}

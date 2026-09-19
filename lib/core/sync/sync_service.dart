import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../network/api_client.dart';

class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._init();
  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _lastSyncMessage;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  String? get lastSyncMessage => _lastSyncMessage;

  SyncService._init();

  Future<void> refreshPendingCount() async {
    _pendingCount = await AppDatabase.instance.getPendingCount();
    notifyListeners();
  }

  Future<bool> synchronize() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _lastSyncMessage = "Starting sync...";
    notifyListeners();

    try {
      final pendingRows = await AppDatabase.instance.getPendingObservations();
      if (pendingRows.isEmpty) {
        _isSyncing = false;
        _pendingCount = 0;
        _lastSyncMessage = "All observations are up to date";
        notifyListeners();
        return true;
      }

      final batchId = const Uuid().v4();
      final observationsPayload = pendingRows.map((row) {
        return {
          'client_id': row['client_id'],
          'crop': row['crop'],
          'symptoms': row['symptoms'],
          'weather_condition': row['weather_condition'],
          'notes': row['notes'],
          'latitude': row['latitude'],
          'longitude': row['longitude'],
          'predicted_disease': row['predicted_disease'],
          'confidence': row['confidence'],
          'created_at': row['created_at'],
        };
      }).toList();

      final response = await ApiClient.instance.syncBatch(
        batchId: batchId,
        observations: observationsPayload,
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final syncedIds = List<String>.from(response.data['synced_ids'] ?? []);
        for (var clientId in syncedIds) {
          await AppDatabase.instance.markObservationSynced(clientId);
        }

        _lastSyncMessage = "Successfully synced ${syncedIds.length} observation(s)";
        await refreshPendingCount();
        _isSyncing = false;
        notifyListeners();
        return true;
      } else {
        _lastSyncMessage = "Server synchronization failed";
      }
    } catch (e) {
      _lastSyncMessage = "Sync paused (Offline). Data remains safely stored locally.";
    }

    _isSyncing = false;
    await refreshPendingCount();
    notifyListeners();
    return false;
  }
}

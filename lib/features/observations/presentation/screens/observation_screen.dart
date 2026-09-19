import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/core/database/app_database.dart';
import 'package:fieldai_flutter/core/sync/sync_service.dart';

class ObservationScreen extends StatefulWidget {
  final String? prefilledCrop;
  final String? prefilledDisease;
  final double? prefilledConfidence;

  const ObservationScreen({
    super.key,
    this.prefilledCrop,
    this.prefilledDisease,
    this.prefilledConfidence,
  });

  @override
  State<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends State<ObservationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cropController;
  late TextEditingController _symptomsController;
  late TextEditingController _notesController;
  String _selectedWeather = 'Humid & Sunny (28°C)';
  double? _latitude = 9.0300;
  double? _longitude = 38.7400;
  bool _isLocating = false;
  bool _isSaving = false;

  final List<String> _weatherOptions = [
    'Humid & Sunny (28°C)',
    'Overcast & Rainy (19°C)',
    'Cool & Damp (16°C)',
    'Dry & Sunny (32°C)',
  ];

  @override
  void initState() {
    super.initState();
    _cropController = TextEditingController(text: widget.prefilledCrop ?? 'Tomato');
    _symptomsController = TextEditingController(
      text: widget.prefilledDisease != null
          ? 'Concentric target rings observed on lower leaf surface.'
          : '',
    );
    _notesController = TextEditingController();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 4),
        );
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (_) {
      setState(() {
        _latitude = 9.0320;
        _longitude = 38.7480;
      });
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _saveObservation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final clientId = const Uuid().v4();
    final newObservation = {
      'client_id': clientId,
      'crop': _cropController.text.trim(),
      'symptoms': _symptomsController.text.trim(),
      'weather_condition': _selectedWeather,
      'notes': _notesController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'predicted_disease': widget.prefilledDisease ?? 'Early Blight',
      'confidence': widget.prefilledConfidence ?? 87.0,
      'image_path': 'local_storage/leaf_${DateTime.now().millisecondsSinceEpoch}.jpg',
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    };

    await AppDatabase.instance.insertObservation(newObservation);
    await SyncService.instance.refreshPendingCount();

    if (!mounted) return;
    setState(() => _isSaving = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen),
            SizedBox(width: 8),
            Text('Saved Locally', style: TextStyle(color: AppTheme.textLight, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Observation saved securely to local SQLite database.\n\nWill automatically synchronize when internet connection becomes available.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Record Field Observation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _cropController,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Crop',
                  prefixIcon: Icon(Icons.eco_outlined, color: AppTheme.accentGreen),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter crop name' : null,
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GPS Coordinates', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            _isLocating
                                ? 'Acquiring GPS fix...'
                                : 'Lat: ${_latitude?.toStringAsFixed(4)}, Lon: ${_longitude?.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location_rounded, color: AppTheme.accentGreen, size: 20),
                      onPressed: _fetchLocation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedWeather,
                dropdownColor: AppTheme.surfaceCard,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Weather & Microclimate',
                  prefixIcon: Icon(Icons.wb_sunny_outlined, color: AppTheme.warningAmber),
                ),
                items: _weatherOptions.map((w) {
                  return DropdownMenuItem(value: w, child: Text(w));
                }).toList(),
                onChanged: (val) => setState(() => _selectedWeather = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _symptomsController,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Observed Foliar Symptoms',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.coronavirus_outlined, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Field Notes & Agronomic Interventions',
                  alignLabelWithHint: true,
                  hintText: 'e.g. Row 4 lower foliage trimmed. Mulched with straw.',
                  prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveObservation,
                icon: const Icon(Icons.save_rounded),
                label: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Observation (Offline)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

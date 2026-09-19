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
  String _selectedSeverity = 'Moderate';
  double? _latitude = 8.5412;
  double? _longitude = 39.2689;
  bool _isLocating = false;
  bool _isSaving = false;

  final List<String> _commonCrops = [
    'Tomato',
    'Maize',
    'Potato',
    'Wheat',
    'Coffee',
    'Pepper'
  ];

  final List<String> _severities = [
    'Mild',
    'Moderate',
    'High',
    'Critical'
  ];

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
          ? 'Concentric target lesions identified on lower foliar canopy.'
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
        if (mounted) {
          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _latitude = 8.5412;
          _longitude = 39.2689;
        });
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _saveObservation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final clientId = 'obs_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}';
    final newObservation = {
      'client_id': clientId,
      'crop': _cropController.text.trim(),
      'symptoms': _symptomsController.text.trim(),
      'weather_condition': '$_selectedWeather | Severity: $_selectedSeverity',
      'notes': _notesController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'predicted_disease': widget.prefilledDisease ?? 'Early Blight',
      'confidence': widget.prefilledConfidence ?? 88.0,
      'image_path': 'local_storage/obs_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
        backgroundColor: context.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Saved to SQLite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Field observation recorded successfully to on-device database.\n\nPending queue updated and ready for cloud synchronization.',
          style: TextStyle(color: context.textMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Return to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
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
              // Crop Quick Chips
              Text(
                'Target Crop',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _commonCrops.map((c) {
                  final isSelected = _cropController.text == c;
                  return ChoiceChip(
                    label: Text(c, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : context.textPrimary)),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: context.surfaceCard,
                    onSelected: (val) {
                      if (val) setState(() => _cropController.text = c);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _cropController,
                style: TextStyle(color: context.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Crop Species / Variety',
                  prefixIcon: Icon(Icons.eco_outlined, color: AppTheme.primaryGreen),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter crop name' : null,
              ),
              const SizedBox(height: 16),

              // GPS Location Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GPS Field Coordinates', style: TextStyle(fontSize: 12, color: context.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            _isLocating
                                ? 'Acquiring GPS fix...'
                                : 'Lat: ${_latitude?.toStringAsFixed(4)}, Lon: ${_longitude?.toStringAsFixed(4)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location_rounded, color: AppTheme.primaryGreen, size: 20),
                      onPressed: _fetchLocation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Severity Selector
              Text(
                'Infestation Severity Level',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: _severities.map((s) {
                  final isSelected = _selectedSeverity == s;
                  Color color = s == 'Critical'
                      ? AppTheme.dangerRed
                      : (s == 'High' ? AppTheme.warningAmber : AppTheme.primaryGreen);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _selectedSeverity = s),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? color : context.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? color : context.cardBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedWeather,
                dropdownColor: context.surfaceCard,
                style: TextStyle(color: context.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Microclimate & Ambient Weather',
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
                style: TextStyle(color: context.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Observed Foliar Symptoms',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.coronavirus_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(color: context.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Agronomic Field Interventions & Notes',
                  alignLabelWithHint: true,
                  hintText: 'e.g. Row 12 trimmed. Straw mulch applied. Drip line cleared.',
                  prefixIcon: Icon(Icons.notes_rounded),
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
                    : const Text('Save Observation to SQLite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

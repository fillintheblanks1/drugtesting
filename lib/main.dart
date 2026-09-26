import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';

List<CameraDescription> _availableWebCameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    _availableWebCameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera detection warning: $e');
  }
  runApp(const FieldDrugTestApp());
}



// <-------------- Everything Starts from here ------------------->
class FieldDrugTestApp extends StatelessWidget {
  const FieldDrugTestApp({super.key});

// <------------- UI DATA ----------->
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sih drug fiekd tester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MainDashboard(),
    );
  }
}

// 
class TestRecord {
  final String id;
  final String timestamp;
  final String location;
  final String operatorId;
  final String classification;
  final String imageHash;
  final Color statusColor;

  TestRecord({
    required this.id,
    required this.timestamp,
    required this.location,
    required this.operatorId,
    required this.classification,
    required this.imageHash,
    required this.statusColor,
  });
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  final List<TestRecord> _logs = [];

  void _addRecord(TestRecord record) {
    setState(() {
      _logs.insert(0, record);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CameraScannerScreen(onRecordGenerated: _addRecord),
      AuditLogScreen(logs: _logs),
    ];

// <------------------- Warning Bar --------------> 

    return Scaffold(
      appBar: AppBar(
        title: const Text('test 0.0.1'),
        elevation: 2,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, size: 14, color: Colors.greenAccent), 
                SizedBox(width: 6),
                Text('fake safe security warning', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
              ],
            ),
          )
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.indigoAccent,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu),
            label: 'logs go here',
          ),
        ],
      ),
    );
  }
}

class CameraScannerScreen extends StatefulWidget {
  final Function(TestRecord) onRecordGenerated;
  const CameraScannerScreen({super.key, required this.onRecordGenerated});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String _operatorId = "officer laadu singh";
  TestRecord? _lastRecord;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (_availableWebCameras.isEmpty) {
      try {
        _availableWebCameras = await availableCameras();
      } catch (e) {
        debugPrint('Camera fetch error: $e');
      }
    }

    if (_availableWebCameras.isNotEmpty) {
      _controller = CameraController(
        _availableWebCameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        await _controller!.initialize();
      } catch (e) {
        debugPrint('Camera controller init error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();

      // SHA-256 Cryptographic Hash Generation
      final digest = sha256.convert(bytes);
      final String imageHash = digest.toString();

      // Simulated Colorimetric Classification Engine
      final Random random = Random();
      final List<String> outcomes = [
        "POSITIVE (Opiates / Heroin)",
        "POSITIVE (Cocaine / Alkaloids)",
        "NEGATIVE",
        "INCONCLUSIVE (Lighting Error)"
      ];
      final String result = outcomes[random.nextInt(outcomes.length)];

      Color statusColor = Colors.orangeAccent;
      if (result.startsWith("POSITIVE")) statusColor = Colors.redAccent;
      if (result.startsWith("NEGATIVE")) statusColor = Colors.greenAccent;

      final record = TestRecord(
        id: "NCB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
        timestamp: DateTime.now().toUtc().toIso8601String(),
        location: "28.6139° N, 77.2090° E (Geo-Stamped)",
        operatorId: _operatorId,
        classification: result,
        imageHash: imageHash,
        statusColor: statusColor,
      );

      widget.onRecordGenerated(record);

      setState(() {
        _lastRecord = record;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Detecting web camera peripherals..."),
          ],
        ),
      );
    }

    if (_availableWebCameras.isEmpty || _controller == null || !_controller!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('camera nhi hai, please try again.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('allow camera permissions.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initCamera,
              child: const Text('Re-detect Camera'),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Camera Viewfinder & Alignment Target
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CameraPreview(_controller!),
                
                // Color Card Alignment Overlay
                Container(
                  width: 340,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.center_focus_strong, size: 14, color: Colors.cyanAccent),
                            SizedBox(width: 6),
                            Text(
                              "text for aligning color card or something", //align color card search
                              style: TextStyle(color: Colors.white  , fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCalibSquare(Colors.white, "W-CAL"),
                          _buildCalibSquare(Colors.black, "K-CAL"),
                          _buildCalibSquare(Colors.red, "R-CAL"),
                          _buildCalibSquare(Colors.green, "G-CAL"),
                          _buildCalibSquare(Colors.blue, "B-CAL"),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 24,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureAndAnalyze,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isProcessing 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera),
                    label: Text(_isProcessing ? 'Processing Image Hash...' : 'Capture & Classify Kit'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Record Generation Sidebar
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1E1E1E),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Operator Metadata", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Operator Identification",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: TextEditingController(text: _operatorId),
                    onChanged: (val) => _operatorId = val,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text("Digital Record Output", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_lastRecord == null)
                    const Text("Capture an alignment frame to generate signed test record.", style: TextStyle(color: Colors.grey))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          color: _lastRecord!.statusColor.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: _lastRecord!.statusColor, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("RESULT CLASSIFICATION", style: TextStyle(color: _lastRecord!.statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_lastRecord!.classification, style: TextStyle(color: _lastRecord!.statusColor, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow("Record ID", _lastRecord!.id),
                        _buildDetailRow("UTC Timestamp", _lastRecord!.timestamp),
                        _buildDetailRow("GPS Geo-Tag", _lastRecord!.location),
                        _buildDetailRow("Operator", _lastRecord!.operatorId),
                        const SizedBox(height: 12),
                        const Text("Cryptographic SHA-256 Hash:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 4),
                        SelectableText(
                          _lastRecord!.imageHash,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.cyanAccent),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalibSquare(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: color, border: Border.all(color: Colors.white54)),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.white70)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }
}

class AuditLogScreen extends StatefulWidget {
  final List<TestRecord> logs;
  const AuditLogScreen({super.key, required this.logs});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredLogs = widget.logs.where((log) {
      final query = _searchQuery.toLowerCase();
      return log.id.toLowerCase().contains(query) ||
             log.classification.toLowerCase().contains(query) ||
             log.operatorId.toLowerCase().contains(query) ||
             log.imageHash.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search logs by Record ID, Operator, Classification, or SHA-256...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),
              Chip(
                label: Text('${filteredLogs.length} Records In Ledger'),
                backgroundColor: Colors.indigo,
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(child: Text("No verifiable digital test records logged yet."))
                : ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final item = filteredLogs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.statusColor.withValues(alpha: 0.2),
                            child: Icon(Icons.verified, color: item.statusColor),
                          ),
                          title: Text("${item.id} — ${item.classification}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Timestamp: ${item.timestamp} | Geo: ${item.location} | Op: ${item.operatorId}"),
                              const SizedBox(height: 2),
                              Text("Hash: ${item.imageHash}", style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.cyan)),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
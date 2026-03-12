export 'history.dart';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'auto_test.dart' as auto;
import 'dart:math';
//import 'cameras.dart' as cameras;

/// History timeline page for incidents.
///
/// - Shows a color-coded, vertical timeline of incidents.
/// - Supports filtering by severity and a detail sheet per item.
/// - Uses mock data that can be replaced with API results.
enum IncidentSeverity { low, medium, high, critical }

//global vars
List<Incident> listIncidents = [];
List<String> accessUrls = [];

class Incident {
  final String id;
  final String hidden_id;
  /// When the incident occurred.
  final DateTime timestamp;
  final String cameraName;
  IncidentSeverity severity;
  final String description;
  //String URL = '';

  /// True when staff has reviewed the incident.
  bool reviewed;

  Incident({
    required this.id,
    required this.hidden_id,
    required this.timestamp,
    required this.cameraName,
    required this.severity,
    required this.description,
    this.reviewed = false,
  });

  /// UI color for severity badges and timeline dots.
  Color get severityColor {
    switch (severity) {
      case IncidentSeverity.low:
        return Colors.green;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.high:
        return Colors.deepOrange;
      case IncidentSeverity.critical:
        return Colors.red;
    }
  }

  /// Human-friendly severity label.
  String get severityLabel {
    switch (severity) {
      case IncidentSeverity.low:
        return 'Low';
      case IncidentSeverity.medium:
        return 'Medium';
      case IncidentSeverity.high:
        return 'High';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>  {
  
  // Mock data - replace with actual API calls later.
  //listIncidents.add();
  VideoPlayerController? _controller;
  bool playingVideo = false;

  /*
  final List<Incident> listIncidents = [
    Incident(
      id: '001',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      cameraName: 'Entrance Camera',
      severity: IncidentSeverity.critical,
      description: 'Suspected concealment detected near checkout area',
      reviewed: false,
    ),
    Incident(
      id: '002',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      cameraName: 'Aisle 3 Camera',
      severity: IncidentSeverity.high,
      description: 'Unusual behavior pattern detected',
      reviewed: true,
    ),
    Incident(
      id: '003',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      cameraName: 'Electronics Section',
      severity: IncidentSeverity.medium,
      description: 'Person lingering near high-value items',
      reviewed: true,
    ),
    Incident(
      id: '004',
      timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 45)),
      cameraName: 'Back Storage',
      severity: IncidentSeverity.low,
      description: 'Motion detected after hours - staff confirmed',
      reviewed: true,
    ),
    Incident(
      id: '005',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      cameraName: 'Freezer Aisle',
      severity: IncidentSeverity.high,
      description: 'Group behavior flagged as suspicious',
      reviewed: false,
    ),
    Incident(
      id: '006',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      cameraName: 'Entrance Camera',
      severity: IncidentSeverity.critical,
      description: 'Confirmed shoplifting incident',
      reviewed: true,
    ),
  ];
  */
  //final listIncidents = await auto.callApi();
  Incident? currentlyReviewing;

  final Set<IncidentSeverity> _severityFilter = {};
  final Set<String> _cameraFilter = {};
  late RangeValues _timeRange;

  @override
  void initState() {
    super.initState();
    _timeRange = const RangeValues(0, 24);
    loadIncidents();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> loadIncidents() async {
    try {
      final urls = await auto.callApi();
      final incidentCamName = 'Main Lobby Camera';
      final descriptions = [
        'Suspected Shoplifting At $incidentCamName',
        'Suspicious Activity At $incidentCamName',
        '$incidentCamName Sent Out An Alert',
        'Unusual Behavior Detected',
        'Potential Concealment Detected Near $incidentCamName',
        'This Camera Needs Attention',
        'Behaviour Flagged As Suspicious',
        '$incidentCamName Flagged Recent Activity As Suspicious'
      ];

      var rng = Random();

      setState(() {
        listIncidents.clear(); // optional, if you don’t want duplicates

        int addTime = 0;
        int randTime = 100;

        for (String url in urls) {
          addTime = rng.nextInt(3) + 3;
          randTime -= addTime;
          int descSelector = Random().nextInt(descriptions.length);
          listIncidents.add(
            Incident(
              id: listIncidents.length.toString(),
              hidden_id: url,
              timestamp: DateTime.now().subtract(Duration(minutes: randTime)),
              cameraName: 'Main Lobby Camera',
              severity: IncidentSeverity.high,
              description: descriptions[descSelector],
              reviewed: false,
            ),
          );
        }
        listIncidents = listIncidents.reversed.toList();
      });

      //debug
      print('debug #00a: $urls');

    } catch(e) {
      print(e);
    }
  }

  /// Converts a timestamp into a floating-hour value (e.g., 13.5 == 13:30).
  double _timeOfDayHours(DateTime dt) {
    return dt.hour + (dt.minute / 60.0);
  }

  /// Formats floating-hour values into a 24h time string.
  String _formatTimeOfDay(double value) {
    final totalMinutes = (value * 60).round().clamp(0, 1440);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Returns incidents filtered by severity, camera, and time-of-day range.
  List<Incident> get filteredIncidents {
    return listIncidents.where((i) {
      // Multiple filters combine as an AND clause.
      if (_severityFilter.isNotEmpty && !_severityFilter.contains(i.severity)) {
        return false;
      }
      if (_cameraFilter.isNotEmpty && !_cameraFilter.contains(i.cameraName)) {
        return false;
      }
      final timeOfDay = _timeOfDayHours(i.timestamp);
      if (timeOfDay < _timeRange.start || timeOfDay > _timeRange.end) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Formats a timestamp as a short relative time label.
  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Formats a timestamp into a full date/time string.
  String _formatFullDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  /// Builds the timeline view with a filter drawer.
  Widget build(BuildContext context) {
    
    return Scaffold(
      endDrawer: Drawer(child: _buildFilterDrawer()),
      body: !playingVideo ? Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Refresh Incidents',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState((){}),
                  ),
                ),
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Open filters',
                    icon: const Icon(Icons.tune),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ],
            ),
          ),
          // Incident count summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredIncidents.length} incidents',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '${listIncidents.where((i) => !i.reviewed).length} unreviewed',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ],
            ),
          ),
          // Timeline list
          Expanded(
            child: filteredIncidents.isEmpty
                ? const Center(child: Text('No incidents found'))
                : ListView.builder(
                    itemCount: filteredIncidents.length,
                    itemBuilder: (context, index) {
                      return _buildTimelineItem(
                        filteredIncidents[index],
                        index,
                      );
                    },
                  ),
          ),
        ],
      ) : ListView(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.65,
            child:
              _controller!.value.isInitialized ? AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!), ) : CircularProgressIndicator(),
          ),

          SizedBox(height:MediaQuery.of(context).size.height * 0.01),
        
          Row(
            children:[
              SizedBox(width:MediaQuery.of(context).size.width * 0.05),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.425,
                child:
                  OutlinedButton.icon(
                    icon: Icon(Icons.check),
                    label: Text("Mark As Shoplifting"),
                    onPressed: () async {
                              currentlyReviewing!.reviewed = true;
                              currentlyReviewing!.severity = IncidentSeverity.critical;
                              await _controller!.dispose();
                              setState(() {playingVideo = false;});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.redAccent),
                    ),
                  ),
              ),
              SizedBox(width:MediaQuery.of(context).size.width * 0.05),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.425,
                child:
                  OutlinedButton.icon(
                    icon: Icon(Icons.no_accounts),
                    label: Text("Mark As False Alarm"),
                    onPressed: () async {
                              currentlyReviewing!.reviewed = true;
                              currentlyReviewing!.severity = IncidentSeverity.low;
                              await _controller!.dispose();
                              setState(() {playingVideo = false;});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.greenAccent),
                    ),
                  ),
              ),
              SizedBox(width:MediaQuery.of(context).size.width * 0.05),
            ]
          ),
        
          SizedBox(height:MediaQuery.of(context).size.height * 0.01),

          Row(
            children:[
              SizedBox(width:MediaQuery.of(context).size.width * 0.05),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.425,
                child:
                  OutlinedButton.icon(
                    icon: Icon(Icons.exit_to_app_sharp),
                    label: Text("Close Footage"),
                    onPressed: () async {
                              currentlyReviewing!.reviewed = true;
                              currentlyReviewing!.severity = IncidentSeverity.medium;
                              await _controller!.dispose();
                              setState(() {playingVideo = false;});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.black),
                    ),
                  ),
              ),
              SizedBox(width:MediaQuery.of(context).size.width * 0.05),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.425,
                child:
                  OutlinedButton.icon(
                    icon: Icon(Icons.replay),
                    label: Text("Watch Again"),
                    onPressed: () async {
                              _controller!.seekTo(Duration.zero);
                              _controller!.play();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.black),
                    ),
                  ),
              ),
              SizedBox(width:MediaQuery.of(context).size.width * 0.05),
            ]
          ),
        
        ]
      ),
      
    );
    
  }

  /// Filter chip for a specific severity level (multi-select).
  Widget _buildSeverityChip(String label, IncidentSeverity severity) {
    final isSelected = _severityFilter.contains(severity);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        selectedColor: [
          Colors.green,
          Colors.orange,
          Colors.deepOrange,
          Colors.red,
        ][severity.index],
        backgroundColor: Colors.white,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _severityFilter.add(severity);
            } else {
              _severityFilter.remove(severity);
            }
          });
        },
      ),
    );
  }

  /// Right-side drawer containing all filter controls.
  Widget _buildFilterDrawer() {
    final cameras = listIncidents.map((i) => i.cameraName).toSet().toList()
      ..sort();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Severity', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _severityFilter.isEmpty,
                onSelected: (_) {
                  setState(() {
                    _severityFilter.clear();
                  });
                },
              ),
              _buildSeverityChip('Critical', IncidentSeverity.critical),
              _buildSeverityChip('High', IncidentSeverity.high),
              _buildSeverityChip('Medium', IncidentSeverity.medium),
              _buildSeverityChip('Low', IncidentSeverity.low),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Time Range (time of day)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            min: 0,
            max: 24,
            divisions: 96,
            values: _timeRange,
            labels: RangeLabels(
              _formatTimeOfDay(_timeRange.start),
              _formatTimeOfDay(_timeRange.end),
            ),
            onChanged: (values) {
              setState(() {
                _timeRange = values;
              });
            },
          ),
          Text(
            'From ${_formatTimeOfDay(_timeRange.start)} to ${_formatTimeOfDay(_timeRange.end)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text('Cameras', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: cameras.map((name) {
              final selected = _cameraFilter.contains(name);
              return FilterChip(
                label: Text(name),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _cameraFilter.add(name);
                    } else {
                      _cameraFilter.remove(name);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _severityFilter.clear();
                _cameraFilter.clear();
                _timeRange = const RangeValues(0, 24);
              });
            },
            child: const Text('Reset filters'),
          ),
        ],
      ),
    );
  }

  /// Builds a single timeline row with dot, line, and incident card.
  Widget _buildTimelineItem(Incident incident, int index) {
    return InkWell(
      onTap: () => _showIncidentDetails(incident),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline line and dot
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // Top line (hidden for first item)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: index == 0
                            ? Colors.transparent
                            : Colors.grey[300],
                      ),
                    ),
                    // Dot
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: incident.severityColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: incident.severityColor.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    // Bottom line (hidden for last item)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: index == filteredIncidents.length - 1
                            ? Colors.transparent
                            : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
              // Incident card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: incident.reviewed
                          ? Colors.grey[300]!
                          : incident.severityColor,
                      width: incident.reviewed ? 1 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Severity badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: incident.severityColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              incident.severityLabel,
                              style: TextStyle(
                                color: incident.severityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          // Timestamp
                          Text(
                            _formatTimestamp(incident.timestamp),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Camera name
                      Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            incident.cameraName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (!incident.reviewed) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        incident.description,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet for full incident details and actions.
  Future<void> _showIncidentDetails(Incident incident) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: incident.severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: incident.severityColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incident #${incident.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${incident.severityLabel} Severity',
                        style: TextStyle(
                          color: incident.severityColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Details
            _buildDetailRow(Icons.videocam, 'Camera', incident.cameraName),
            _buildDetailRow(
              Icons.access_time,
              'Time',
              _formatFullDate(incident.timestamp),
            ),
            _buildDetailRow(
              Icons.description,
              'Description',
              incident.description,
            ),
            _buildDetailRow(
              Icons.check_circle,
              'Status',
              incident.reviewed ? 'Reviewed' : 'Pending Review',
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                /// working with this
                /// 
                /// 
                Expanded(
                  child: OutlinedButton.icon(
                    //onPressed: () => Navigator.pop(context),
                    onPressed: () async {
                      currentlyReviewing = incident; 
                      Navigator.pop(context);
                      await setupVideoController(incident.hidden_id);
                      setState(() {playingVideo = true;});
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('View Footage'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        incident.reviewed = true;
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Reviewed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: incident.severityColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Labeled value row used inside the detail sheet.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> setupVideoController(String videoURL) async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoURL));
    
      await _controller!.initialize();
    
      setState(() {});

      await _controller!.play();
    } catch (e) {
      print(e);
    }
  }
}

import 'package:flutter/material.dart';
import 'history.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const sectionTitleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

    // First 3 incidents from history
    final incidents = [
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
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text('Review', style: sectionTitleStyle),
            const SizedBox(height: 12),
            ...incidents.map((incident) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _IncidentCard(incident: incident),
            )),
            const SizedBox(height: 8),
            const Text('Dashboard', style: sectionTitleStyle),
            const SizedBox(height: 12),
            const Text(
              'You have no cameras set up, why not start now?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});

  final Incident incident;

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

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
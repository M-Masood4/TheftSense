import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'cameras.dart';
import 'history.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VideoPlayerController? _controller;
  bool playingVideo = false;
  CameraController? _dashboardCameraController;
  bool viewingDashboardCamera = false;
  int selectedDashboardCameraIndex = 0;

  final List<Incident> _incidents = [
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

  @override
  void dispose() {
    _controller?.dispose();
    _dashboardCameraController?.dispose();
    super.dispose();
  }

  Future<void> _disposeDashboardCamera() async {
    if (_dashboardCameraController != null) {
      await _dashboardCameraController!.dispose();
      _dashboardCameraController = null;
    }
  }

  Future<void> _openDashboardCamera(int index) async {
    final available = await availableCameras();
    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No device cameras available.')),
      );
      return;
    }

    selectedDashboardCameraIndex = index;
    final cameraIndex = index % available.length;

    await _disposeDashboardCamera();

    _dashboardCameraController = CameraController(
      available[cameraIndex],
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _dashboardCameraController!.initialize();

    if (!mounted) return;
    setState(() {
      viewingDashboardCamera = true;
    });
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

  String _formatFullDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await setupVideoController('https://t13-users-videos.s3.eu-west-1.amazonaws.com/test_clip.mp4?response-content-disposition=inline&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEP3%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCWV1LXdlc3QtMSJIMEYCIQD5XQu%2FOUNfTv8XS47I9Fj4%2Bz%2BDjVsidgm6zu1sEjWjTgIhAMlnQWxbcQ4ex7twZ9zcSoO%2FJDrIRqAHG8rvv%2Fq9PSWcKsIDCMb%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEQABoMMjA0MDEyOTAxODU0IgxSwDe9Nv29utOn4TEqlgOeuKUehoihjw3vVnm8%2FPkoDiD27bA%2BGvRaE%2B6mjZeXlG4A%2B%2Bqk9L%2FrSBUk3LlKFRTsWNcdsPLF3RMtQAU3302JCkX5kWL%2B567SroGrHKHGmHBMo%2Bn8O4wuLlY6TIQba6xzsW8OVdnFC7I%2BTx3%2Fz8Zmk3XPWF33VQuSOMKOP5HnACSmvZMoRiGWqE1F%2BWm%2B0yTtoViapcNDCmFkatxyLwkr9LLm2Aw%2FJXI5VloJnrqDnMv0fEqrHD7NcYoxgdERIHev1L%2Bg0gw6QPfzZciYyzuyF1DvSaHubROO%2Bj9bV94vEXfOAIs2dGP8GKK1COKyYhZg3Pf6QURpUp%2BUaRqov241yDdG57H3WuFyvsCv6zfYR7Vy5WhXhMy5bE1RjmbKDkUdG5vHBn3R6k57TPUTsvnBtjRXvm3oRSWGbcF%2F17j97vhtM6nzcb9kUI0pQ5Lk2mX5gGCCLNzJKOqAH0RisUvIXudwYzPfVUuWpuSU09%2BsXpVAywhaK2VmHCRyg%2BIhKHXnWc%2FZKVRUY%2FSdWHDFzoXK0C1XeKcKMMHO68wGOt0C5zf8ENClLozLRHTlorbFevbmsnsgEhJhd4i9k829qFSxg%2BeAx1H0i%2BT1JCcpgp5M%2BA9ZN13JDQnkUdMZqBHGhK0dF%2FhugabzpJPU0fDoWlSXrxN6gZhXiQEqewQya2nzMBIyJ%2Fs%2BiFJNJK9y7oRHPaPEsMJ5%2BBshx4BO7Dp6CDGTisLXyQPEHEM1E6P0vcqoikAFAA%2FblaHNTSAEK4btE9z%2FKyvUYJrTFTpNdD5n57kFZ8EqN5pNcFpcV1dZB5c9kyZTR2qh4MLE76UXPUTxNXItUG30nAd58QLab6Py8E3tsleNwmNiEga5JcYO52y59a8oDLw%2BYRqBaObjR5VU5Ri30T4DtScg%2FXh4Ib0Zot0WBOwVJMAA9N5lByxdws1PmcgkEsJDxIfu1481MN1YOVYEoe6%2B%2B2v83si85jGtm9juEhldsUOL0sh5tuEacHtJf1ggBfbX2uRaOZGLFg%3D%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAS7AA52XPH7JGQEAM%2F20260222%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Date=20260222T122601Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=5d2798af9c13baf63ad619664cd25bdd31632df4f8727c7872bd6c9e5cbd4dc1');
                      setState(() {
                        playingVideo = true;
                      });
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

  @override
  Widget build(BuildContext context) {
    const sectionTitleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: viewingDashboardCamera
          ? ListView(
              scrollDirection: Axis.vertical,
              children: [
                if (_dashboardCameraController == null ||
                    _dashboardCameraController?.value.isInitialized == false)
                  const Center(child: CircularProgressIndicator())
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(50, 5, 50, 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 10),
                          ),
                          width: MediaQuery.of(context).size.width * 0.80,
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: AspectRatio(
                            aspectRatio:
                                _dashboardCameraController!.value.aspectRatio,
                            child: CameraPreview(_dashboardCameraController!),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(50, 5, 5, 5),
                  child: Row(
                    children: [
                      Icon(Icons.videocam, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 10),
                      Text(
                        selectedDashboardCameraIndex < cameraNames.length
                            ? cameraNames[selectedDashboardCameraIndex]
                            : '',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(50, 5, 5, 5),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 10),
                      Text(
                        selectedDashboardCameraIndex < cameraDetails.length
                            ? cameraDetails[selectedDashboardCameraIndex]
                            : '',
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.exit_to_app_outlined),
                        label: const Text('Cancel'),
                        onPressed: () async {
                          await _disposeDashboardCamera();
                          if (!mounted) return;
                          setState(() {
                            viewingDashboardCamera = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  ],
                ),
              ],
            )
          : !playingVideo
              ? SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const Text('Review', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  ..._incidents.map(
                    (incident) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _IncidentCard(
                        incident: incident,
                        onTap: () => _showIncidentDetails(incident),
                      ),
                    ),
                ),
                  const SizedBox(height: 8),
                  const Text('Dashboard', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<int>(
                    valueListenable: camerasVersion,
                    builder: (context, _, __) {
                      if (cameraNames.isEmpty) {
                        return const Text(
                          'You have no cameras set up, why not start now?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${cameraNames.length} cameras active',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.circle, color: Colors.grey, size: 5),
                              const SizedBox(width: 10),
                              const Text(
                                '0 problems',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (int i = 0; i < cameraNames.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openDashboardCamera(i),
                                child: Container(
                                  width: double.infinity,
                                  height: 75,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 196, 191, 191),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.green, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 25),
                                      SizedBox(
                                        height: 40,
                                        width: 55,
                                        child: i < thumbnails.length
                                            ? Image.network(
                                                thumbnails[i].path,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[350],
                                                    child: const Icon(Icons.image_not_supported),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Colors.grey[350],
                                                child: const Icon(
                                                  Icons.videocam,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 25),
                                      const Icon(
                                        Icons.menu_book_sharp,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        cameraNames[i],
                                        style: const TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(width: 50),
                                      Text(
                                        i < cameraDetails.length ? cameraDetails[i] : '',
                                        style: const TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            )
              : ListView(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: _controller!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : const CircularProgressIndicator(),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Row(
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.425,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Mark As Shoplifting'),
                        onPressed: () async {
                          await _controller!.dispose();
                          setState(() {
                            playingVideo = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.425,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.no_accounts),
                        label: const Text('Mark As False Alarm'),
                        onPressed: () async {
                          await _controller!.dispose();
                          setState(() {
                            playingVideo = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.greenAccent),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Row(
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.425,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.exit_to_app_sharp),
                        label: const Text('Close Footage'),
                        onPressed: () async {
                          await _controller!.dispose();
                          setState(() {
                            playingVideo = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.425,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.replay),
                        label: const Text('Watch Again'),
                        onPressed: () async {
                          _controller!.seekTo(Duration.zero);
                          _controller!.play();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  ],
                ),
              ],
            ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: incident.reviewed ? Colors.grey[300]! : incident.severityColor,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
            Text(
              incident.description,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
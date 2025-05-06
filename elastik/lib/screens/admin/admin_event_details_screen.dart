import 'package:elastik/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminEventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const AdminEventDetailsScreen({super.key, required this.event});

  @override
  State<AdminEventDetailsScreen> createState() =>
      _AdminEventDetailsScreenState();
}

class _AdminEventDetailsScreenState extends State<AdminEventDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  Map<String, dynamic>? _expandedParticipant;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final participantsRes = await _apiService.getEventParticipants(
        widget.event['eventId'],
      );
      final commentsRes = await _apiService.getEventComments(
        widget.event['eventId'],
      );

      List<Map<String, dynamic>> enrichedParticipants = [];

      for (var participant in (participantsRes.data as List)) {
        final userId = participant['userId'];
        List<Map<String, dynamic>> answers = [];

        for (var field in widget.event['eventCustomFields']) {
          final eventCustomFieldId = field['eventCustomFieldId'];
          final registrationRes = await _apiService.getUserRegistrationForEvent(
            userId: userId,
            eventCustomFieldId: eventCustomFieldId,
          );
          final registrations = registrationRes.data as List;
          for (var reg in registrations) {
            if (reg['answers'] != null) {
              answers.addAll(
                (reg['answers'] as List).cast<Map<String, dynamic>>(),
              );
            }
          }
        }
        enrichedParticipants.add({...participant, 'answers': answers});
      }

      setState(() {
        _participants = enrichedParticipants;
        _comments = (commentsRes.data as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleParticipantExpansion(Map<String, dynamic> participant) {
    setState(() {
      _expandedParticipant =
          _expandedParticipant == participant ? null : participant;
    });
  }

  Widget _buildAvailabilityChart() {
    final availableCount =
        _participants.where((p) => p['isAvailable'] == true).length;
    final unavailableCount = _participants.length - availableCount;

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: availableCount.toDouble(),
              color: Colors.green,
              title: '$availableCount',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: unavailableCount.toDouble(),
              color: Colors.red,
              title: '$unavailableCount',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          startDegreeOffset: 180,
        ),
      ),
    );
  }

  Widget _buildParticipantDetails(Map<String, dynamic> participant) {
    final participantComments =
        _comments.where((c) => c['userId'] == participant['userId']).toList();
    final surveyAnswers = participant['answers'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),

        // Custom Field Answers section
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Custom Field Answers:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Show custom field answers or no data message
        if (surveyAnswers.isNotEmpty)
          ...surveyAnswers.map((answer) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    answer['questionText'] ?? 'Question',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    answer['value']?.toString() ?? 'No answer',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          })
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No custom field data entered',
              style: TextStyle(color: Colors.grey),
            ),
          ),

        // Comments section
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Comments:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Show comments or no comments message
        if (participantComments.isNotEmpty)
          ...participantComments.map(
            (comment) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment['content']),
                  Text(
                    DateTime.parse(comment['createdAt']).toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No comments', style: TextStyle(color: Colors.grey)),
          ),

        const Divider(),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(title: Text(event['title'] ?? 'Event Details')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.people)),
                        Tab(icon: Icon(Icons.insights)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Participants Tab
                          _participants.isEmpty
                              ? const Center(child: Text('No participants yet'))
                              : ListView.builder(
                                itemCount: _participants.length,
                                itemBuilder: (context, index) {
                                  final p = _participants[index];
                                  return Column(
                                    children: [
                                      ListTile(
                                        title: Text(p['name'] ?? 'Unknown'),
                                        subtitle: Text(
                                          p['email'] ?? 'No Email',
                                        ),
                                        trailing: Icon(
                                          p['isAvailable'] == true
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color:
                                              p['isAvailable'] == true
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                        onTap:
                                            () =>
                                                _toggleParticipantExpansion(p),
                                      ),
                                      if (_expandedParticipant == p)
                                        _buildParticipantDetails(p),
                                    ],
                                  );
                                },
                              ),
                          // Insights Tab
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Availability Overview',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                _buildAvailabilityChart(),
                                // Add legend below the chart
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLegendItem(
                                        Colors.green,
                                        'Available',
                                      ),
                                      const SizedBox(width: 24),
                                      _buildLegendItem(
                                        Colors.red,
                                        'Not Available',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

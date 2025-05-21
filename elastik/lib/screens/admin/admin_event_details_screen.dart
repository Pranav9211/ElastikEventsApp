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
  List<Map<String, dynamic>> _aggregatedCustomFields = [];
  bool _isLoadingCustomFields = false;
  Map<String, String> _userNames = {}; // Maps userId to userName
  bool _isLoadingComments = false;
  bool _showComments = false;
  bool _showCustomFields = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load existing data (participants and comments)
      final participantsRes = await _apiService.getEventParticipants(
        widget.event['eventId'],
      );
      final commentsRes = await _apiService.getEventComments(
        widget.event['eventId'],
      );

      // Store basic data
      setState(() {
        _participants =
            (participantsRes.data as List).cast<Map<String, dynamic>>();
        _comments = (commentsRes.data as List).cast<Map<String, dynamic>>();
      });

      // Load user names for comments
      await _loadCommentUserNames();

      // Load custom fields data
      await _loadCustomFieldsData();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCommentUserNames() async {
    setState(() => _isLoadingComments = true);

    try {
      final Map<String, String> userNames = {};

      // Get unique user IDs from comments
      final userIds = _comments.map((c) => c['userId'].toString()).toSet();

      // Fetch each user's name
      for (var userId in userIds) {
        try {
          final response = await _apiService.getUserById(userId);
          if (response.data != null && response.data is Map) {
            final user = response.data as Map<String, dynamic>;
            userNames[userId] = user['name'] ?? 'Anonymous';
          } else {
            userNames[userId] = 'Anonymous';
          }
        } catch (e) {
          userNames[userId] = 'Anonymous';
        }
      }

      if (mounted) {
        setState(() {
          _userNames = userNames;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _loadCustomFieldsData() async {
    if (!mounted) return;

    setState(() => _isLoadingCustomFields = true);

    try {
      List<Map<String, dynamic>> aggregatedData = [];

      // Get all custom fields for this event
      final customFields = widget.event['eventCustomFields'] as List? ?? [];

      // For each custom field, get all responses
      for (var field in customFields) {
        final fieldId = field['eventCustomFieldId'];
        final fieldName = field['fieldName'] ?? 'Custom Field';

        // Get all participants' responses for this field
        for (var participant in _participants) {
          final userId = participant['userId'];
          final response = await _apiService.getUserRegistrationForEvent(
            userId: userId,
            eventCustomFieldId: fieldId,
          );

          if (response.data != null && response.data is List) {
            final registrations =
                (response.data as List).cast<Map<String, dynamic>>();
            for (var reg in registrations) {
              if (reg['answers'] != null && reg['answers'] is List) {
                final answers =
                    (reg['answers'] as List).cast<Map<String, dynamic>>();
                for (var answer in answers) {
                  aggregatedData.add({
                    'fieldName': fieldName,
                    'questionText': answer['questionText'] ?? 'Question',
                    'participantName': participant['name'] ?? 'Unknown',
                    'value': answer['value']?.toString() ?? 'No answer',
                  });
                }
              }
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _aggregatedCustomFields = aggregatedData;
        _isLoadingCustomFields = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCustomFields = false);
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
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Custom Field Answers:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Comments:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildCommentsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _comments.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                _showComments ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _showComments = !_showComments;
                });
              },
            ),
          ],
        ),
      ),
      if (!_showComments)
        const SizedBox()
      else if (_isLoadingComments)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_comments.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '   Sorry! No comments yet. ',
            style: TextStyle(color: Colors.grey),
          ),
        )
      else
        ..._comments.map(
          (comment) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _userNames[comment['userId']] ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(comment['createdAt']),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment['content'],
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

Widget _buildCustomFieldsSection() {
  if (_isLoadingCustomFields) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  if (_aggregatedCustomFields.isEmpty) {
    return const SizedBox();
  }

  final Map<String, List<Map<String, dynamic>>> groupedAnswers = {};
  for (var answer in _aggregatedCustomFields) {
    final question = answer['questionText'];
    if (!groupedAnswers.containsKey(question)) {
      groupedAnswers[question] = [];
    }
    groupedAnswers[question]!.add(answer);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Custom Fields',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            IconButton(
              icon: Icon(
                _showCustomFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _showCustomFields = !_showCustomFields;
                });
              },
            ),
          ],
        ),
      ),
      if (!_showCustomFields)
        const SizedBox()
      else
        ...groupedAnswers.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map((answer) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              answer['participantName'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              answer['value'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
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
                          // Participants Tab - Keep exactly as it was
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
                          // Insights Tab - Add new sections
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
                                _buildCommentsSection(),
                                _buildCustomFieldsSection(),
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

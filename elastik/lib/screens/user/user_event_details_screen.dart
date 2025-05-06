import 'package:dio/dio.dart';
import 'package:elastik/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _event;
  List<dynamic> _participants = [];
  List<dynamic> _comments = [];
  List<dynamic> _eventCustomFields = [];
  bool _isAvailable = false;
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isSubmittingRegistration = false;
  String? _userId;
  String? _participantId;
  String? _userName;

  Map<String, dynamic> _registrationAnswers = {};
  Map<String, dynamic>? _userRegistration;

  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _availabilityCommentController =
      TextEditingController();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await _fetchUserData();
      await _fetchEventDetails();
    } catch (e) {
      debugPrint("Initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUserResponse = await _apiService.getCurrentUserId();
      final userResponse = await _apiService.getUserById(currentUserResponse);

      if (mounted) {
        setState(() {
          _userId = currentUserResponse;
          _userName = userResponse.data['name'] ?? 'User';
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _userName = 'User';
        });
      }
      throw Exception('Failed to load user data');
    }
  }

  Future<void> _fetchEventDetails() async {
    try {
      final responses = await Future.wait([
        _apiService.getEventById(widget.eventId),
        _apiService.getEventParticipants(widget.eventId),
        _apiService.getEventComments(widget.eventId),
      ]);

      if (mounted) {
        setState(() {
          _event = responses[0].data;
          _participants = responses[1].data ?? [];
          _comments = responses[2].data ?? [];
          _eventCustomFields = _event?['eventCustomFields'] ?? [];
        });
        _setUserAvailability();
        await _fetchEventRegistration();
      }
    } catch (e) {
      debugPrint("Error fetching event details: $e");
      throw Exception('Failed to load event details');
    }
  }

  Future<void> _fetchEventRegistration() async {
    if (_userId == null) return;

    try {
      for (var field in _eventCustomFields) {
        final response = await _apiService.getUserRegistrationForEvent(
          userId: _userId!,
          eventCustomFieldId: field['eventCustomFieldId'],
        );

        if (response.data != null && response.data.isNotEmpty) {
          setState(() {
            _userRegistration = response.data;
          });
          break;
        }
      }
    } catch (e) {
      debugPrint("Error fetching registration: $e");
    }
  }

  void _setUserAvailability() {
    if (_userId == null) return;

    try {
      final currentParticipant = _participants.firstWhere(
        (p) => p['userId'] == _userId,
        orElse: () => null,
      );

      if (currentParticipant != null && mounted) {
        setState(() {
          _isAvailable = currentParticipant['isAvailable'] == true;
          _participantId = currentParticipant['participantId'];
        });
      }
    } catch (e) {
      debugPrint("Error setting user availability: $e");
    }
  }

  Future<void> _updateAvailability() async {
    if (_participantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to update availability')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final content = _availabilityCommentController.text.trim();

      // Show loading indicator
      final loadingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Updating availability...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

      // First update availability
      final updateResponse = await _apiService.updateParticipantAvailability(
        participantId: _participantId!,
        isAvailable: _isAvailable,
      );

      // Only proceed if the update was successful
      if (updateResponse.statusCode == 200 ||
          updateResponse.statusCode == 204) {
        // Add comment if available
        if (content.isNotEmpty) {
          await _apiService.addComment(
            userId: _userId!,
            eventId: widget.eventId,
            content: content,
          );
          _availabilityCommentController.clear();
        }

        // Hide loading indicator
        loadingSnackbar.close();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Availability updated successfully')),
          );
        }

        // Refresh data
        await _fetchEventDetails();
      } else {
        loadingSnackbar.close();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${updateResponse.data}')),
        );
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.response?.data ?? e.message}')),
      );
      debugPrint("Full error details: $e");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
      debugPrint("Unexpected error: $e");
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _addComment() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add comments')),
      );
      return;
    }

    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a comment')));
      return;
    }

    try {
      // Show loading indicator
      final loadingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Posting comment...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

      final response = await _apiService.addComment(
        userId: _userId!,
        eventId: widget.eventId,
        content: content,
      );

      // Hide loading indicator
      loadingSnackbar.close();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _commentController.clear();
        await _fetchEventDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: ${response.data}')),
        );
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.response?.data ?? e.message}')),
      );
      debugPrint("Full error details: $e");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
      debugPrint("Unexpected error: $e");
    }
  }

  Future<void> _submitRegistration() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit registration')),
      );
      return;
    }

    setState(() => _isSubmittingRegistration = true);

    try {
      for (var eventField in _eventCustomFields) {
        final eventCustomFieldId = eventField['eventCustomFieldId'];
        final questions = eventField['customField']['questions'];

        // Extract answers related to this eventCustomFieldId
        List<Map<String, dynamic>> answers = [];

        for (var question in questions) {
          final questionText = question['questionText'].toString();
          final key = '${eventCustomFieldId}_$questionText';
          if (_registrationAnswers.containsKey(key)) {
            answers.add({
              'QuestionText': questionText,
              'QuestionType': question['questionType'],
              'Value': _registrationAnswers[key],
              'Options': question['options'] ?? [],
              'IsRequired': question['isRequired'] ?? false,
            });
          }
        }

        // Only submit if there is at least one answer
        if (answers.isNotEmpty) {
          final response = await _apiService.submitRegistration(
            eventCustomFieldId: eventCustomFieldId,
            answers: answers,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            debugPrint('Submitted for $eventCustomFieldId');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed for $eventCustomFieldId: ${response.data}',
                ),
              ),
            );
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration submitted successfully')),
      );
      await _fetchEventRegistration();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      debugPrint("Registration error: $e");
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRegistration = false);
      }
    }
  }

  void _updateAnswer(String fieldId, String questionText, dynamic value) {
    setState(() {
      _registrationAnswers['${fieldId}_$questionText'] = value;
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('Failed to load event details')),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_event!['title'] ?? 'Event Details'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Participants"),
              Tab(icon: Icon(Icons.calendar_today), text: "Availability"),
              Tab(icon: Icon(Icons.comment), text: "Comments"),
              Tab(icon: Icon(Icons.assignment), text: "Registration"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildParticipantsTab(),
            _buildAvailabilityTab(),
            _buildCommentsTab(),
            _buildRegistrationTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsTab() {
    return RefreshIndicator(
      onRefresh: _fetchEventDetails,
      child:
          _participants.isEmpty
              ? const Center(child: Text('No participants yet'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final participant = _participants[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(participant['name']?[0] ?? '?'),
                      ),
                      title: Text(participant['name'] ?? 'Unknown'),
                      subtitle: Text(participant['email'] ?? ''),
                      trailing: Chip(
                        backgroundColor:
                            participant['isAvailable'] == true
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                        label: Text(
                          participant['isAvailable'] == true
                              ? 'Available'
                              : 'Unavailable',
                          style: TextStyle(
                            color:
                                participant['isAvailable'] == true
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildAvailabilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Availability Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      _isAvailable
                          ? 'You are available'
                          : 'You are not available',
                    ),
                    value: _isAvailable,
                    onChanged: (value) {
                      // Only update local state
                      setState(() => _isAvailable = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add a note (optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _availabilityCommentController,
                    decoration: const InputDecoration(
                      hintText: 'Explain your availability...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isUpdating ? null : _updateAvailability,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child:
                        _isUpdating
                            ? const CircularProgressIndicator()
                            : const Text('UPDATE AVAILABILITY'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchEventDetails,
            child:
                _comments.isEmpty
                    ? const Center(child: Text('No comments yet'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getUserNameById(comment['userId']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(comment['content'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(comment['createdAt']),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationTab() {
    if (_eventCustomFields.isEmpty) {
      return const Center(child: Text('No registration fields available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_userRegistration != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Registration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._userRegistration!['answers'].map<Widget>((answer) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              answer['questionText'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(answer['value'].toString()),
                            const Divider(),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            )
          else
            ..._eventCustomFields.map<Widget>((field) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field['customField']['fieldName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...field['customField']['questions'].map<Widget>((question) {
                        return _buildQuestionInput(
                          field['eventCustomFieldId'],
                          question,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }).toList(),
          if (_userRegistration == null && _eventCustomFields.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed:
                    _isSubmittingRegistration ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmittingRegistration
                    ? const CircularProgressIndicator()
                    : const Text('SUBMIT REGISTRATION'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(String fieldId, Map<String, dynamic> question) {
  final String questionText = question['questionText'];
  final String questionType = question['questionType'];
  final List<dynamic> options = question['options'] ?? [];
  final bool isRequired = question['isRequired'] ?? false;
  final String? defaultValue = question['defaultValue'];

  final key = '${fieldId}_$questionText';

  switch (questionType) {
    case 'text':
      // Use persistent controller
      if (!_controllers.containsKey(key)) {
        _controllers[key] = TextEditingController(
          text: _registrationAnswers[key] ?? defaultValue ?? '',
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          decoration: InputDecoration(
            labelText: questionText,
            border: const OutlineInputBorder(),
            suffix: isRequired ? const Text('*') : null,
          ),
          controller: _controllers[key],
          onChanged: (value) => _updateAnswer(fieldId, questionText, value),
        ),
      );

    case 'mcq':
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: questionText,
            border: const OutlineInputBorder(),
            suffix: isRequired ? const Text('*') : null,
          ),
          value: _registrationAnswers[key] ?? defaultValue,
          items: options.map<DropdownMenuItem<String>>((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) => _updateAnswer(fieldId, questionText, value),
        ),
      );

    case 'color':
      final currentColor = _registrationAnswers[key];
      Color pickerColor = _parseColor(currentColor ?? '#ffffff');

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$questionText${isRequired ? ' *' : ''}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map<Widget>((color) {
                final colorValue =
                    color is Map ? color['value'] ?? color['color'] : color;
                return GestureDetector(
                  onTap: () {
                    _updateAnswer(fieldId, questionText, colorValue);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(colorValue),
                      shape: BoxShape.circle,
                      border: currentColor == colorValue
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Pick a color'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color color) {
                          pickerColor = color;
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton(
                        child: const Text('Select'),
                        onPressed: () {
                          final selectedHex =
                              '#${pickerColor.value.toRadixString(16).substring(2)}';
                          _updateAnswer(fieldId, questionText, selectedHex);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Pick Custom Color'),
            ),
            if (currentColor != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected: $currentColor',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      );

    case 'image':
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$questionText${isRequired ? ' *' : ''}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildImageSelector(fieldId, questionText, options),
          ],
        ),
      );

    default:
      return Text('Unsupported question type: $questionType');
  }
}

  Widget _buildImageSelector(
    String fieldId,
    String questionText,
    List<dynamic> options,
  ) {
    final selectedValue = _registrationAnswers['${fieldId}_$questionText'];

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return GestureDetector(
                onTap:
                    () => _updateAnswer(fieldId, questionText, option['value']),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    border:
                        selectedValue == option['value']
                            ? Border.all(color: Colors.blue, width: 3)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      if (option['imageUrl'] != null)
                        Image.network(
                          option['imageUrl'],
                          width: 100,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          width: 100,
                          height: 80,
                          color: Colors.grey,
                          child: const Icon(Icons.image),
                        ),
                      Text(option['label'] ?? option['value']),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      // Handle hex colors
      if (colorString.startsWith('#')) {
        String hexColor = colorString.replaceAll('#', '');
        if (hexColor.length == 6) {
          hexColor = 'FF$hexColor'; // Add opacity if missing
        }
        return Color(int.parse(hexColor, radix: 16));
      }

      switch (colorString.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'yellow':
          return Colors.yellow;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        case 'pink':
          return Colors.pink;
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        default:
          return Colors.grey;
      }
    } catch (e) {
      debugPrint('Error parsing color: $colorString');
      return Colors.grey;
    }
  }

  String _getUserNameById(String userId) {
    try {
      final user = _participants.firstWhere(
        (p) => p['userId'] == userId,
        orElse: () => null,
      );
      return user?['name'] ?? 'User $userId';
    } catch (e) {
      return 'User $userId';
    }
  }
}

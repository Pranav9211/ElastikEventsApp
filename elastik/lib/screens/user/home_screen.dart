import 'package:elastik/screens/auth/login_screen.dart';
import 'package:elastik/screens/user/user_event_details_screen.dart';
import 'package:elastik/services/api_services.dart';
import 'package:elastik/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _enrichedEvents = [];
  bool _isLoading = true;
  String _userName = 'User'; // Default name

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchEvents();
  }

  Future<void> _fetchUserData() async {
    try {
      // First get the current user's ID from JWT
      final currentUserResponse = await _apiService.getCurrentUserId();

      // Then fetch the user details to get the name
      final userResponse = await _apiService.getUserById(currentUserResponse);
      setState(() {
        _userName = userResponse.data['name'] ?? 'User';
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _userName = 'User';
      });
    }
  }

  Future<void> _fetchEvents() async {
    try {
      final eventResponse = await _apiService.getAllEventsForParticipants();
      final List events = eventResponse.data;

      List<Map<String, dynamic>> enrichedList = [];

      for (var event in events) {
        final eventId = event['eventId'];
        final creatorId = event['createBy'];
        final createdAt = event['createdAt'];

        // Convert and format date
        DateTime dateTime = DateTime.parse(createdAt);
        String formattedDate = DateFormat('MMMM dd, yyyy').format(dateTime);

        // Fetch organizer name
        String organizerName = 'Unknown Organizer';
        try {
          final organizerResponse = await _apiService.getUserById(creatorId);
          organizerName = organizerResponse.data['name'] ?? 'Unknown Organizer';
        } catch (e) {
          print('Error fetching organizer name: $e');
        }

        // Fetch participants and count available ones
        int participantCount = 0;
        List<String> participantNames = [];
        try {
          final participantRes = await _apiService.getEventParticipants(eventId);
          final participants = participantRes.data as List;
          
          // Process each participant to get their name and availability
          for (var participant in participants) {
            if (participant['isAvailable'] == true) {
              participantCount++;
              try {
                // Get participant user details to fetch their name
                final userResponse = await _apiService.getUserById(participant['userId']);
                participantNames.add(userResponse.data['name'] ?? 'Unknown Participant');
              } catch (e) {
                print('Error fetching participant name: $e');
                participantNames.add('Unknown Participant');
              }
            }
          }
        } catch (e) {
          print('Error fetching participants: $e');
        }

        enrichedList.add({
          'id': eventId,
          'title': event['title'] ?? 'No Title',
          'date': formattedDate,
          'location': event['location'] ?? 'Location not specified',
          'organizer': organizerName,
          'participantCount': participantCount,
        });
      }

      setState(() {
        _enrichedEvents = enrichedList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    try {
      await _apiService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to logout')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $_userName'),
        backgroundColor: const Color.fromARGB(145, 0, 192, 96),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _enrichedEvents.isEmpty
              ? const Center(child: Text('No events available'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _enrichedEvents.length,
                itemBuilder: (context, index) {
                  final event = _enrichedEvents[index];
                  return EventCard(
                    title: event['title'],
                    location: event['location'],
                    organizer: event['organizer'],
                    date: event['date'],
                    participantCount: event['participantCount'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  EventDetailScreen(eventId: event['id']),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}

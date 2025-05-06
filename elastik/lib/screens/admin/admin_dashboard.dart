import 'package:elastik/screens/admin/create_event_screen.dart';
import 'package:elastik/screens/admin/admin_event_details_screen.dart';
import 'package:elastik/screens/auth/login_screen.dart';
import 'package:elastik/services/api_services.dart';
import 'package:elastik/widgets/event_table.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAllAdminEvents();
      setState(() => _events = List<Map<String, dynamic>>.from(response.data ?? []));
    } catch (e) {
      debugPrint('Error fetching events: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to logout')),
        );
      }
    }
  }

  void _navigateToCreateEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
    ).then((_) => _fetchEvents());
  }

  void _navigateToEventDetails(String eventId) {
    final event = _events.firstWhere((e) => e['eventId'] == eventId, orElse: () => {});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEventDetailsScreen(event: event),
      ),
    ).then((_) => _fetchEvents());
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _apiService.deleteEvent(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
        _fetchEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete event')),
        );
      }
    }
  }

  void _confirmDelete(String eventId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteEvent(eventId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Event',
            onPressed: _navigateToCreateEvent,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _fetchEvents,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No events found'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _navigateToCreateEvent,
                            child: const Text('Create First Event'),
                          ),
                        ],
                      ),
                    )
                  : EventTable(
                      events: _events,
                      onEventTap: _navigateToEventDetails,
                      onDelete: _confirmDelete,
                      isAdmin: true,
                    ),
        ),
      ),
    );
  }
}
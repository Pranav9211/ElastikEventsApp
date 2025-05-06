import 'package:flutter/material.dart';

class EventTable extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Function(String) onEventTap;
  final Function(String) onDelete;
  final bool isAdmin;

  const EventTable({
    super.key,
    required this.events,
    required this.onEventTap,
    required this.onDelete,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Debug print to check event IDs
    debugPrint('Events in table: ${events.map((e) => e['eventId']).toList()}');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (context, index) => Divider(
        color: colorScheme.outline.withOpacity(0.2),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final event = events[index];
        final eventId = event['eventId']?.toString(); // Convert to string if not null

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                event['title']?[0] ?? 'E',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          title: Text(
            event['title'] ?? 'No Title',
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            event['location'] ?? 'No Location',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          trailing: isAdmin
              ? IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                  ),
                  onPressed: () {
                    if (eventId != null && eventId.isNotEmpty) {
                      onDelete(eventId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot delete - invalid event ID'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      debugPrint('Attempted to delete event with null/empty ID at index $index');
                    }
                  },
                )
              : null,
          onTap: () {
            if (eventId != null && eventId.isNotEmpty) {
              onEventTap(eventId);
            }
          },
        );
      },
    );
  }
}
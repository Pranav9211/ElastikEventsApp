import 'package:flutter/material.dart';
import 'package:elastik/services/api_services.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _prebuiltFields = [];
  List<String> _selectedPrebuiltFieldIds = [];

  final List<Map<String, dynamic>> _customFields = [];
  int _activeCustomFieldIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchPrebuiltFields();
  }

  Future<void> _fetchPrebuiltFields() async {
    try {
      final response = await _apiService.getAllCustomFields();
      if (response.data != null) {
        setState(() {
          _prebuiltFields = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      _showError('Failed to load prebuilt fields: ${e.toString()}');
    }
  }

  void _addCustomField(String type) {
    setState(() {
      _customFields.add({
        'fieldName': '',
        'fieldType': type.toLowerCase(),
        'isRequired': false,
        'questions': [
          {
            'questionText': '',
            'questionType': type.toLowerCase(),
            'options': type == 'MCQ' ? [''] : [],
            'defaultValue': type == 'Color' ? '#000000' : null,
            'isRequired': false,
          },
        ],
      });
      _activeCustomFieldIndex = _customFields.length - 1;
    });
  }

  Widget _buildFieldTypeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildFieldTypeChip('Text'),
        _buildFieldTypeChip('MCQ'),
        _buildFieldTypeChip('Color'),
        _buildFieldTypeChip('Image'),
      ],
    );
  }

  Widget _buildFieldTypeChip(String type) {
    return ChoiceChip(
      label: Text(type),
      selected: false,
      onSelected: (_) => _addCustomField(type),
    );
  }

  Widget _buildCustomFieldEditor() {
    if (_activeCustomFieldIndex == -1 || _customFields.isEmpty) {
      return const SizedBox();
    }

    final field = _customFields[_activeCustomFieldIndex];
    final question = field['questions'][0];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Field Name *',
                      border: const OutlineInputBorder(),
                      suffixText: '(${field['fieldType']})',
                    ),
                    onChanged: (value) => field['fieldName'] = value,
                  ),
                ),
                Checkbox(
                  value: field['isRequired'],
                  onChanged: (value) {
                    setState(() {
                      field['isRequired'] = value ?? false;
                      question['isRequired'] = value ?? false;
                    });
                  },
                ),
                const Text('Required'),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuestionEditor(question, field['fieldType']),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _removeCustomField(_activeCustomFieldIndex),
                  child: const Text(
                    'Remove Field',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _activeCustomFieldIndex = -1),
                  child: const Text('Save Field'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionEditor(Map<String, dynamic> question, String fieldType) {
    switch (fieldType) {
      case 'text':
        return _buildTextQuestionEditor(question);
      case 'mcq':
        return _buildMCQQuestionEditor(question);
      case 'color':
        return _buildColorQuestionEditor(question);
      case 'image':
        return _buildImageQuestionEditor(question);
      default:
        return const SizedBox();
    }
  }

  Widget _buildTextQuestionEditor(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Question Text *',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => question['questionText'] = value,
        ),
      ],
    );
  }

  Widget _buildMCQQuestionEditor(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Question Text *',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => question['questionText'] = value,
        ),
        const SizedBox(height: 16),
        const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...List<Widget>.generate(question['options'].length, (index) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Option ${index + 1} *',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => question['options'][index] = value,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _removeOption(index),
              ),
            ],
          );
        }),
        TextButton.icon(
          onPressed: _addOption,
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
        ),
      ],
    );
  }

  Widget _buildColorQuestionEditor(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Question Text *',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => question['questionText'] = value,
        ),
        const SizedBox(height: 16),
        const Text('Default Color:'),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Hex Color Code',
                  border: OutlineInputBorder(),
                  prefixText: '#',
                ),
                onChanged: (value) => question['defaultValue'] = '#$value',
                controller: TextEditingController(
                  text: question['defaultValue'].toString().replaceFirst(
                    '#',
                    '',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(
                  int.parse(
                    question['defaultValue'].toString().replaceFirst(
                      '#',
                      '0xFF',
                    ),
                  ),
                ),
                border: Border.all(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageQuestionEditor(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Question Text *',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => question['questionText'] = value,
        ),
        const SizedBox(height: 16),
        const Text(
          'Image Options:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...List<Widget>.generate(question['options'].length, (index) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Image URL ${index + 1} *',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => question['options'][index] = value,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _removeOption(index),
              ),
            ],
          );
        }),
        TextButton.icon(
          onPressed: _addOption,
          icon: const Icon(Icons.add),
          label: const Text('Add Image URL'),
        ),
      ],
    );
  }

  void _addOption() {
    setState(() {
      final question = _customFields[_activeCustomFieldIndex]['questions'][0];
      question['options'].add('');
    });
  }

  void _removeOption(int index) {
    setState(() {
      final question = _customFields[_activeCustomFieldIndex]['questions'][0];
      question['options'].removeAt(index);
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields.removeAt(index);
      _activeCustomFieldIndex = -1;
    });
  }

  Widget _buildPrebuiltFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prebuilt Fields',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Select from existing fields:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _prebuiltFields.map((field) {
                final isSelected = _selectedPrebuiltFieldIds.contains(
                  field['fieldId'],
                );
                return FilterChip(
                  label: Text(field['fieldName']),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPrebuiltFieldIds.add(field['fieldId']);
                      } else {
                        _selectedPrebuiltFieldIds.remove(field['fieldId']);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Fields',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildFieldTypeSelector(),
        const SizedBox(height: 16),
        _buildCustomFieldEditor(),
        const SizedBox(height: 8),
        ..._customFields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          return ListTile(
            title: Text('${field['fieldName']} (${field['fieldType']})'),
            subtitle: Text(field['questions'][0]['questionText']),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _activeCustomFieldIndex = index),
            ),
            onTap: () => setState(() => _activeCustomFieldIndex = index),
          );
        }),
      ],
    );
  }

  Future<void> _submitEvent() async {
    // Validate basic event info
    if (_titleController.text.isEmpty) {
      _showError('Event title is required');
      return;
    }

    if (_locationController.text.isEmpty) {
      _showError('Event location is required');
      return;
    }

    // Validate custom fields
    for (final field in _customFields) {
      if (field['fieldName'].toString().isEmpty) {
        _showError('Custom field name is required');
        return;
      }

      final question = field['questions'][0];
      if (question['questionText'].toString().isEmpty) {
        _showError('Question text is required for all fields');
        return;
      }

      if (field['fieldType'] == 'mcq' || field['fieldType'] == 'image') {
        for (final option in question['options']) {
          if (option.toString().isEmpty) {
            _showError('All options must be filled');
            return;
          }
        }
      }
    }

    try {
      // Create custom fields first
      final List<String> createdFieldIds = [];
      for (final field in _customFields) {
        final response = await _apiService.createCustomField(
          fieldName: field['fieldName'],
          fieldType: field['fieldType'],
          questions: field['questions'],
          isRequired: field['isRequired'],
        );

        if (response.data != null && response.data['fieldId'] != null) {
          createdFieldIds.add(response.data['fieldId']);
        }
      }

      // Combine prebuilt and newly created field IDs
      final allFieldIds = [..._selectedPrebuiltFieldIds, ...createdFieldIds];

      // Create the event with all field IDs
      final response = await _apiService.createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        customFieldIds: allFieldIds.isNotEmpty ? allFieldIds : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Event created successfully!');
        _resetForm();
      } else {
        _showError('Failed to create event: ${response.statusMessage}');
      }
    } catch (e) {
      _showError('Error creating event: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _customFields.clear();
      _selectedPrebuiltFieldIds.clear();
      _activeCustomFieldIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _submitEvent),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Event Info Section
            const Text(
              'Event Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Prebuilt Fields Section
            _buildPrebuiltFieldsSection(),

            // Custom Fields Section
            _buildCustomFieldsSection(),

            // Submit Button
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _submitEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Create Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

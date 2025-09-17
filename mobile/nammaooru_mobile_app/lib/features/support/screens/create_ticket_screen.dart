import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../services/support_service.dart';
import '../models/support_ticket_model.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final SupportService _supportService = SupportService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  SupportCategory _selectedCategory = SupportCategory.general;
  SupportPriority _selectedPriority = SupportPriority.medium;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final ticket = await _supportService.createSupportTicket(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
      );

      if (ticket != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Support ticket created successfully!'),
              backgroundColor: VillageTheme.successGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        _showErrorSnackBar('Failed to create support ticket. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: VillageTheme.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Create Support Ticket',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: VillageTheme.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: VillageTheme.cardDecoration,
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 48,
                      color: VillageTheme.primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: VillageTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe your issue and our support team will get back to you within 24 hours.',
                      style: TextStyle(
                        color: VillageTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form Fields
              Container(
                padding: const EdgeInsets.all(20),
                decoration: VillageTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ticket Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: VillageTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Category Selection
                    const Text(
                      'Category *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: VillageTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SupportCategory>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: SupportCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Priority Selection
                    const Text(
                      'Priority *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: VillageTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SupportPriority>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: SupportPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(priority),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(priority.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPriority = value!);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Title Field
                    const Text(
                      'Title *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: VillageTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Brief summary of your issue',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 5) {
                          return 'Title must be at least 5 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Description Field
                    const Text(
                      'Description *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: VillageTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Provide detailed information about your issue...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 20) {
                          return 'Description must be at least 20 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VillageTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Creating Ticket...'),
                                ],
                              )
                            : const Text(
                                'Create Support Ticket',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tips Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: VillageTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: VillageTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: VillageTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tips for Better Support',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Provide specific details about the issue\n'
                      '• Include order ID if order-related\n'
                      '• Mention steps to reproduce the problem\n'
                      '• Screenshot if applicable (can be shared in chat)',
                      style: TextStyle(
                        color: VillageTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(SupportPriority priority) {
    switch (priority) {
      case SupportPriority.low:
        return Colors.green;
      case SupportPriority.medium:
        return Colors.orange;
      case SupportPriority.high:
        return Colors.red;
      case SupportPriority.urgent:
        return Colors.deepOrange;
    }
  }
}
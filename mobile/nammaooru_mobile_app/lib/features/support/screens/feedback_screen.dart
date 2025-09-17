import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../services/support_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final SupportService _supportService = SupportService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  FeedbackType _selectedType = FeedbackType.general;
  int _rating = 0;
  bool _isSubmitting = false;
  bool _allowContact = true;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate() || _rating == 0) {
      if (_rating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a rating'),
            backgroundColor: VillageTheme.errorRed,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final feedback = await _supportService.submitFeedback(
        type: _selectedType,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        rating: _rating,
        allowContact: _allowContact,
      );

      if (feedback != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback!'),
              backgroundColor: VillageTheme.successGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        _showErrorSnackBar('Failed to submit feedback. Please try again.');
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
          'Send Feedback',
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
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: VillageTheme.cardDecoration,
                child: Column(
                  children: [
                    Icon(
                      Icons.feedback,
                      size: 48,
                      color: VillageTheme.primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'We Value Your Feedback',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: VillageTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your feedback helps us improve our services and provide better experience.',
                      style: TextStyle(
                        color: VillageTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Rating Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: VillageTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Rating *',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: VillageTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'How would you rate your experience with NammaOoru?',
                      style: TextStyle(
                        color: VillageTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRatingStars(),
                    const SizedBox(height: 8),
                    if (_rating > 0)
                      Text(
                        _getRatingText(_rating),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _getRatingColor(_rating),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Feedback Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: VillageTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feedback Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: VillageTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Feedback Type
                    const Text(
                      'Feedback Type *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: VillageTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<FeedbackType>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: FeedbackType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                _getFeedbackTypeIcon(type),
                                size: 20,
                                color: VillageTheme.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(type.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
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
                        hintText: 'Brief summary of your feedback',
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

                    // Message Field
                    const Text(
                      'Feedback Message *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: VillageTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Please share your detailed feedback...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your feedback message';
                        }
                        if (value.trim().length < 10) {
                          return 'Message must be at least 10 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Allow Contact Switch
                    Row(
                      children: [
                        Switch(
                          value: _allowContact,
                          onChanged: (value) {
                            setState(() => _allowContact = value);
                          },
                          activeColor: VillageTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Allow us to contact you regarding this feedback',
                            style: TextStyle(
                              color: VillageTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
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
                                  Text('Submitting Feedback...'),
                                ],
                              )
                            : const Text(
                                'Submit Feedback',
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
                  color: VillageTheme.infoBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: VillageTheme.infoBlue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: VillageTheme.infoBlue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Feedback Guidelines',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: VillageTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Be specific about what you liked or disliked\n'
                      '• Include suggestions for improvement\n'
                      '• Mention any bugs or issues you encountered\n'
                      '• Share ideas for new features or services',
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

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _rating = starIndex);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              _rating >= starIndex ? Icons.star : Icons.star_border,
              size: 40,
              color: _rating >= starIndex
                  ? _getRatingColor(starIndex)
                  : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - Needs significant improvement';
      case 2:
        return 'Fair - Below expectations';
      case 3:
        return 'Good - Meets expectations';
      case 4:
        return 'Very Good - Exceeds expectations';
      case 5:
        return 'Excellent - Outstanding experience';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) {
      return Colors.red;
    } else if (rating == 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  IconData _getFeedbackTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.general:
        return Icons.feedback;
      case FeedbackType.appUsability:
        return Icons.phone_android;
      case FeedbackType.deliveryExperience:
        return Icons.delivery_dining;
      case FeedbackType.productQuality:
        return Icons.star;
      case FeedbackType.customerService:
        return Icons.support_agent;
      case FeedbackType.suggestion:
        return Icons.lightbulb_outline;
      case FeedbackType.complaint:
        return Icons.report_problem;
      case FeedbackType.compliment:
        return Icons.thumb_up;
    }
  }
}

enum FeedbackType {
  general,
  appUsability,
  deliveryExperience,
  productQuality,
  customerService,
  suggestion,
  complaint,
  compliment;

  String get displayName {
    switch (this) {
      case FeedbackType.general:
        return 'General Feedback';
      case FeedbackType.appUsability:
        return 'App Usability';
      case FeedbackType.deliveryExperience:
        return 'Delivery Experience';
      case FeedbackType.productQuality:
        return 'Product Quality';
      case FeedbackType.customerService:
        return 'Customer Service';
      case FeedbackType.suggestion:
        return 'Suggestion';
      case FeedbackType.complaint:
        return 'Complaint';
      case FeedbackType.compliment:
        return 'Compliment';
    }
  }
}
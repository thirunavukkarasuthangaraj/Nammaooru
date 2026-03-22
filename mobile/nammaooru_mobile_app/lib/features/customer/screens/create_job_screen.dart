import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/image_compressor.dart';
import '../services/job_service.dart';
import '../widgets/voice_input_button.dart';
import '../../../shared/widgets/location_autocomplete_field.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _vacanciesController = TextEditingController();
  final JobService _jobService = JobService();

  String _selectedCategory = 'SHOP_WORKER';
  String _selectedJobType = 'FULL_TIME';
  String _selectedSalaryType = 'MONTHLY';
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  double? _latitude;
  double? _longitude;

  static const Color _jobGreen = Color(0xFF2E7D32);

  // Jobs = employment/salary positions (Shop, Office, Service sector)
  // Skilled trades (Electrician, Plumber, Carpenter etc.) → use Labour module
  static const Map<String, String> _categories = {
    'SHOP_WORKER': '🏪 Shop Worker / கடை ஊழியர்',
    'WOMEN_SHOP_WORKER': '👩 Women for Shop / பெண் கடை ஊழியர்',
    'SALES_PERSON': '💼 Sales Person / விற்பனையாளர்',
    'DELIVERY_BOY': '🚴 Delivery / டெலிவரி',
    'CASHIER': '💰 Cashier / கேஷியர்',
    'RECEPTIONIST': '📋 Receptionist / ரிசெப்ஷனிஸ்ட்',
    'ACCOUNTANT': '📊 Accountant / கணக்காளர்',
    'DRIVER': '🚗 Driver / டிரைவர்',
    'AUTO_DRIVER': '🛺 Auto Driver / ஆட்டோ டிரைவர்',
    'COOK': '👨‍🍳 Cook / சமையல்காரர்',
    'HELPER': '🤝 Helper / உதவியாளர்',
    'TEACHER': '📚 Teacher / ஆசிரியர்',
    'NURSE': '🏥 Nurse / செவிலியர்',
    'BEAUTICIAN': '💄 Beautician / அழகுக்கலை',
    'TAILOR': '✂️ Tailor / தையல்காரர்',
    'WATCHMAN': '👁️ Watchman / காவலன்',
    'COMPUTER_OPERATOR': '💻 Computer Operator / கம்ப்யூட்டர்',
    'PEON': '📦 Peon / சாய்பல்',
    'MANAGER': '👔 Manager / மேலாளர்',
    'OTHER': '🔩 Other / பிற',
  };

  static const Map<String, String> _jobTypes = {
    'FULL_TIME': '⏰ Full Time / முழு நேரம்',
    'PART_TIME': '🕐 Part Time / பகுதி நேரம்',
    'CONTRACT': '📄 Contract / ஒப்பந்தம்',
    'DAILY_WAGE': '📅 Daily Wage / நாள் கூலி',
    'INTERNSHIP': '🎓 Internship / பயிற்சி',
  };

  static const Map<String, String> _salaryTypes = {
    'MONTHLY': 'Monthly / மாதம்',
    'WEEKLY': 'Weekly / வாரம்',
    'DAILY': 'Daily / நாள்',
    'HOURLY': 'Hourly / மணி',
    'NEGOTIABLE': 'Negotiable / பேசலாம்',
  };

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  void _fetchLocation() async {
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _companyController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _vacanciesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 images allowed')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      final compressed = await ImageCompressor.compressXFile(picked);
      setState(() => _selectedImages.add(compressed));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await _jobService.createPost(
        companyName: _companyController.text.trim(),
        phone: _phoneController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        category: _selectedCategory,
        salary: _salaryController.text.trim(),
        salaryType: _selectedSalaryType,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        requirements: _requirementsController.text.trim(),
        jobType: _selectedJobType,
        vacancies: int.tryParse(_vacanciesController.text.trim()),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Job posted! Awaiting approval.'),
            backgroundColor: _jobGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to post job'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          lang.getText('Post a Job', 'வேலை பதிவிடு'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _jobGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_jobGreen, _jobGreen.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('💼', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.getText('Hire the right person', 'சரியான ஆளை தேர்வு செய்யுங்கள்'),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          lang.getText('Post your job & get applicants', 'வேலை போட்டு விண்ணப்பதாரர்களை பெறுங்கள்'),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Company Info
            _sectionHeader('🏢 ${lang.getText("Company", "நிறுவனம்")}'),
            const SizedBox(height: 8),
            _buildField(
              controller: _companyController,
              label: lang.getText('Company / Shop Name *', 'நிறுவன / கடை பெயர் *'),
              hint: lang.getText('e.g. Sri Supermarket', 'எ.கா. ஸ்ரீ சூப்பர்மார்க்கெட்'),
              icon: Icons.business,
              validator: (v) => v == null || v.trim().isEmpty ? lang.getText('Company name required', 'நிறுவன பெயர் தேவை') : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildField(
                    controller: _phoneController,
                    label: lang.getText('Contact Phone *', 'தொடர்பு எண் *'),
                    hint: '9XXXXXXXXX',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    validator: (v) => v == null || v.trim().length < 10 ? lang.getText('Valid phone required', 'சரியான எண் தேவை') : null,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: VoiceInputButton(controller: _phoneController),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Job Details
            _sectionHeader('💼 ${lang.getText("Job Details", "வேலை விவரங்கள்")}'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildField(
                    controller: _jobTitleController,
                    label: lang.getText('Job Title *', 'வேலை தலைப்பு *'),
                    hint: lang.getText('e.g. Supermarket Employee', 'எ.கா. கடை ஊழியர்'),
                    icon: Icons.work,
                    validator: (v) => v == null || v.trim().isEmpty ? lang.getText('Job title required', 'வேலை தலைப்பு தேவை') : null,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: VoiceInputButton(controller: _jobTitleController),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: lang.getText('Job Category *', 'வேலை வகை *'),
              icon: Icons.category,
              value: _selectedCategory,
              items: _categories,
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: lang.getText('Job Type', 'வேலை வகை'),
              icon: Icons.access_time,
              value: _selectedJobType,
              items: _jobTypes,
              onChanged: (v) => setState(() => _selectedJobType = v!),
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _vacanciesController,
              label: lang.getText('Number of Vacancies', 'காலியிடங்கள் எண்ணிக்கை'),
              hint: '1',
              icon: Icons.people,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),

            // Salary
            _sectionHeader('💰 ${lang.getText("Salary", "சம்பளம்")}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    controller: _salaryController,
                    label: lang.getText('Salary Amount', 'சம்பள தொகை'),
                    hint: 'e.g. 12000',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: lang.getText('Type', 'வகை'),
                    icon: Icons.schedule,
                    value: _selectedSalaryType,
                    items: _salaryTypes,
                    onChanged: (v) => setState(() => _selectedSalaryType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Location & Description
            _sectionHeader('📍 ${lang.getText("Location & Details", "இடம் & விவரங்கள்")}'),
            const SizedBox(height: 8),
            Text(lang.getText('Work Location *', 'பணி இடம் *'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 6),
            LocationAutocompleteField(
              controller: _locationController,
              hintText: lang.getText('e.g. Anna Nagar, Chennai', 'எ.கா. அண்ணா நகர், சென்னை'),
              accentColor: const Color(0xFF2E7D32),
              validator: (v) => v == null || v.trim().isEmpty ? lang.getText('Location required', 'இடம் தேவை') : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildField(
                    controller: _descriptionController,
                    label: lang.getText('Job Description', 'வேலை விவரம்'),
                    hint: lang.getText('Describe the role, duties...', 'வேலை பணி, கடமைகள்...'),
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: VoiceInputButton(controller: _descriptionController),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildField(
                    controller: _requirementsController,
                    label: lang.getText('Requirements / தகுதிகள்', 'தகுதிகள்'),
                    hint: lang.getText('e.g. 12th pass, Tamil speaking...', 'எ.கா. 12வது பாஸ், தமிழ் பேசத்தெரியும்...'),
                    icon: Icons.checklist,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: VoiceInputButton(controller: _requirementsController),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Images
            _sectionHeader('📸 ${lang.getText("Photos (Optional)", "படங்கள் (விருப்பம்)")}'),
            const SizedBox(height: 8),
            _buildImagePicker(),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(
                  _isSubmitting
                      ? lang.getText('Posting...', 'பதிவிடுகிறோம்...')
                      : lang.getText('✅ Post Job', '✅ வேலை பதிவிடு'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _jobGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: _jobGreen, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _jobGreen, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._selectedImages.asMap().entries.map((entry) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(entry.value.path),
                    width: 90, height: 90, fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImages.removeAt(entry.key)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )),
        if (_selectedImages.length < 3)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: _jobGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _jobGreen.withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, color: _jobGreen, size: 28),
                  const SizedBox(height: 4),
                  Text('Add Photo', style: TextStyle(fontSize: 10, color: _jobGreen)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

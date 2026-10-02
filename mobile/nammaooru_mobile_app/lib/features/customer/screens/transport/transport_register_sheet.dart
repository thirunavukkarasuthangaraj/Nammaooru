import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/language_provider.dart';
import '../../services/transport_service.dart';

/// Bottom sheet: register (or edit) as a transporter / fleet owner.
class TransportRegisterSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const TransportRegisterSheet({super.key, this.existing});

  @override
  State<TransportRegisterSheet> createState() => _TransportRegisterSheetState();
}

class _TransportRegisterSheetState extends State<TransportRegisterSheet> {
  static const _accent = Color(0xFF1565C0);
  final _form = GlobalKey<FormState>();
  late final _company = TextEditingController(text: widget.existing?['companyName']?.toString() ?? '');
  late final _owner = TextEditingController(text: widget.existing?['ownerName']?.toString() ?? '');
  late final _phone = TextEditingController(text: widget.existing?['phone']?.toString() ?? '');
  bool _busy = false;

  String _t(String en, String ta) => Provider.of<LanguageProvider>(context, listen: false).getText(en, ta);

  @override
  void dispose() {
    _company.dispose(); _owner.dispose(); _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final r = await TransportService.instance.register(
      companyName: _company.text.trim(), ownerName: _owner.text.trim(), phone: _phone.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']?.toString() ?? '')));
    if (r['success'] == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 14),
              Text(editing ? _t('Transporter profile', 'உரிமையாளர் விவரம்') : _t('Register as bus / lorry owner', 'பஸ் / லாரி உரிமையாளராக பதிவு'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_t('After admin approval you can add vehicles, drivers and routes, and track them live.', 'நிர்வாக ஒப்புதலுக்குப் பிறகு வாகனங்கள், ஓட்டுநர்கள், வழிகளை சேர்த்து நேரலையில் கண்காணிக்கலாம்.'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _company,
                decoration: InputDecoration(labelText: _t('Company / fleet name *', 'நிறுவனம் / ஃப்ளீட் பெயர் *'), border: const OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? _t('Required', 'தேவை') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _owner,
                decoration: InputDecoration(labelText: _t('Owner name', 'உரிமையாளர் பெயர்'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: _t('Contact number (10 digits)', 'தொடர்பு எண் (10 இலக்கம்)'), border: const OutlineInputBorder()),
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (d.isEmpty) return null; // falls back to account number
                  return d.length == 10 || (d.length == 12 && d.startsWith('91')) ? null : _t('Enter 10 digits', '10 இலக்கங்கள்');
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(editing ? _t('Save', 'சேமி') : _t('Submit for approval', 'ஒப்புதலுக்கு அனுப்பு'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

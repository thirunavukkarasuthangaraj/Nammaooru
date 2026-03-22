import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/services/location_service.dart';

/// A TextFormField with Google Places Autocomplete suggestions,
/// biased to the user's current GPS location.
class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final Color accentColor;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.accentColor = const Color(0xFF4CAF50),
  });

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  static const _apiKey = 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U';

  List<_PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  bool _showDropdown = false;
  Timer? _debounce;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideDropdown();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hideDropdown();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.length < 2) {
      _hideDropdown();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(value));
  }

  Future<void> _fetchSuggestions(String input) async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final lat = LocationService.cachedLatitude ?? 12.4966;
      final lng = LocationService.cachedLongitude ?? 78.5729;

      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&location=$lat,$lng'
        '&radius=50000'
        '&components=country:in'
        '&types=geocode'
        '&key=$_apiKey',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = (data['predictions'] as List? ?? []);
        setState(() {
          _suggestions = predictions
              .take(5)
              .map((p) => _PlaceSuggestion(
                    mainText: p['structured_formatting']?['main_text'] ?? p['description'],
                    fullText: p['description'] ?? '',
                  ))
              .toList();
          _loading = false;
        });
        if (_suggestions.isNotEmpty) _showSuggestions();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuggestions() {
    _hideDropdown();
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showDropdown = true);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _showDropdown = false);
  }

  void _selectSuggestion(_PlaceSuggestion s) {
    widget.controller.text = s.mainText;
    _hideDropdown();
    _focusNode.unfocus();
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (_) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 2),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final s = _suggestions[i];
                  return InkWell(
                    onTap: () => _selectSuggestion(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: widget.accentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.mainText,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                if (s.fullText != s.mainText)
                                  Text(s.fullText,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                              ],
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText ?? 'Enter location',
          prefixIcon: Icon(Icons.location_on, size: 20, color: widget.accentColor),
          suffixIcon: _loading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: widget.accentColor),
                  ),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: widget.accentColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

class _PlaceSuggestion {
  final String mainText;
  final String fullText;
  const _PlaceSuggestion({required this.mainText, required this.fullText});
}

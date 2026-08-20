import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../services/shop_api_service.dart';

/// Panel that lets the customer search any village/town in India and use it
/// as the "deliver to" location (e.g. ordering groceries for parents in
/// their native village while living in Bangalore/Chennai).
///
/// Opens from the top of the screen (not a bottom sheet) so it sits right
/// under the app bar where the "deliver to" control lives.
///
/// Pops with `{'name': ..., 'latitude': ..., 'longitude': ...}` for a picked
/// place, `{'useCurrentLocation': true}` for the near-me option, or null when
/// dismissed.
class LocationSearchSheet extends StatefulWidget {
  const LocationSearchSheet({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const Align(
          alignment: Alignment.topCenter,
          child: LocationSearchSheet(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    // A trailing/leading space reaching the geocoder changes match quality
    // (e.g. "mittur " returns a bare village name with no address context,
    // while "mittur" returns the full "Mittur, Mogilivaripalle, ..." result) -
    // trim before it ever reaches the search, not just the length check above.
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    final languageCode =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    // Own shop localities (finds villages like Mittur straight from shop
    // data) and the geocoders run IN PARALLEL, each isolated so one failing
    // or hanging can never blank the other's results.
    final lookups = await Future.wait<List<Map<String, dynamic>>>([
      ShopApiService()
          .searchShopLocations(query)
          .timeout(const Duration(seconds: 3), onTimeout: () => <Map<String, dynamic>>[])
          .catchError((_) => <Map<String, dynamic>>[]),
      LocationService.instance
          .searchPlaces(query, languageCode: languageCode)
          .catchError((_) => <Map<String, dynamic>>[]),
    ]);
    final shopLocations = lookups[0];
    final geoResults = lookups[1];

    // Merge: own localities first, then geocoder results not duplicating them
    final seen = shopLocations
        .map((l) => (l['name'] as String).toLowerCase())
        .toSet();
    final results = [
      ...shopLocations,
      ...geoResults.where((g) =>
          !seen.contains((g['name'] as String).toLowerCase().split(',').first.trim())),
    ];
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
      _hasSearched = true;
    });
  }

  void _select(Map<String, dynamic> result) {
    // Clear the list before popping so the closing animation carries an
    // empty panel off-screen instead of the full suggestion list.
    setState(() {
      _results = [];
      _hasSearched = false;
    });
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                context.loc?.translate('deliver_to_which_place') ?? 'Deliver to which place?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onQueryChanged,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: context.loc?.translate('search_village_town') ?? 'Search village or town...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              title: Text(
                context.loc?.translate('use_current_location') ?? 'Use my current location',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              onTap: () => _select({'useCurrentLocation': true}),
            ),
            if (_results.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final place = _results[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFF9800),
                      ),
                      title: Text(
                        place['name'] as String,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _select(place),
                    );
                  },
                ),
              )
            else if (_hasSearched && !_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Text(
                  context.loc?.translate('place_not_found') ?? 'Place not found. Try a different name.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }
}

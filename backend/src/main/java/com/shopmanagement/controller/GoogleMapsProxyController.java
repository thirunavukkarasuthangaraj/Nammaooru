package com.shopmanagement.controller;

import com.shopmanagement.service.GoogleMapsProxyService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public proxy for Google Maps Platform address search, used by the
 * customer app's location picker/autocomplete before the user is
 * necessarily logged in. See GoogleMapsProxyService for why this exists.
 */
@RestController
@RequestMapping("/api/places")
@RequiredArgsConstructor
@Slf4j
public class GoogleMapsProxyController {

    private final GoogleMapsProxyService googleMapsProxyService;

    @GetMapping(value = "/autocomplete", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> autocomplete(
            @RequestParam String input,
            @RequestParam(defaultValue = "en") String language,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) String sessionToken) {
        try {
            return ResponseEntity.ok(googleMapsProxyService.autocomplete(input, language, lat, lng, sessionToken));
        } catch (Exception e) {
            log.error("Places autocomplete proxy failed", e);
            return ResponseEntity.ok("{\"status\":\"UNKNOWN_ERROR\",\"predictions\":[]}");
        }
    }

    @GetMapping(value = "/details", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> details(
            @RequestParam String placeId,
            @RequestParam(required = false) String sessionToken) {
        try {
            return ResponseEntity.ok(googleMapsProxyService.placeDetails(placeId, sessionToken));
        } catch (Exception e) {
            log.error("Place details proxy failed", e);
            return ResponseEntity.ok("{\"status\":\"UNKNOWN_ERROR\"}");
        }
    }

    @GetMapping(value = "/geocode", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> geocode(
            @RequestParam String address,
            @RequestParam(defaultValue = "en") String language) {
        try {
            return ResponseEntity.ok(googleMapsProxyService.geocodeAddress(address, language));
        } catch (Exception e) {
            log.error("Geocode proxy failed", e);
            return ResponseEntity.ok("{\"status\":\"UNKNOWN_ERROR\",\"results\":[]}");
        }
    }

    @GetMapping(value = "/reverse-geocode", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> reverseGeocode(
            @RequestParam double lat,
            @RequestParam double lng) {
        try {
            return ResponseEntity.ok(googleMapsProxyService.reverseGeocode(lat, lng));
        } catch (Exception e) {
            log.error("Reverse geocode proxy failed", e);
            return ResponseEntity.ok("{\"status\":\"UNKNOWN_ERROR\",\"results\":[]}");
        }
    }
}

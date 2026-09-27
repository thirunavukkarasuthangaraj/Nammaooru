package com.shopmanagement.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

/**
 * Server-side proxy for the Google Maps Platform REST APIs (Places,
 * Geocoding). The customer app calls these endpoints instead of Google
 * directly, so the Google Maps API key lives only on this server and never
 * ships inside the app/APK - it can then be IP-restricted in Google Cloud
 * Console to just this server, instead of being unrestricted (the only
 * option for a key embedded in client code).
 *
 * URLs are built by hand rather than with UriComponentsBuilder#encode():
 * that percent-encodes structural characters like the "|" in result_type
 * (e.g. "route|locality") into %7C, which Google's Geocoding API then
 * rejects with "Invalid 'result_type' parameter" - only true free-text
 * values (address/input/placeId) need encoding here.
 */
@Service
@Slf4j
public class GoogleMapsProxyService {

    private final RestTemplate restTemplate;

    @Value("${google.maps.api-key:}")
    private String apiKey;

    public GoogleMapsProxyService(RestTemplateBuilder restTemplateBuilder) {
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(5))
                .setReadTimeout(Duration.ofSeconds(8))
                .build();
    }

    public String autocomplete(String input, String languageCode, Double biasLat, Double biasLng, String sessionToken) {
        StringBuilder url = new StringBuilder("https://maps.googleapis.com/maps/api/place/autocomplete/json?")
                .append("input=").append(encode(input))
                .append("&components=country:in")
                .append("&language=").append(encode(languageCode))
                .append("&key=").append(apiKey);
        if (biasLat != null && biasLng != null) {
            url.append("&locationbias=circle:50000@").append(biasLat).append(',').append(biasLng);
        }
        if (sessionToken != null && !sessionToken.isBlank()) {
            url.append("&sessiontoken=").append(encode(sessionToken));
        }
        return get(url.toString());
    }

    public String placeDetails(String placeId, String sessionToken) {
        StringBuilder url = new StringBuilder("https://maps.googleapis.com/maps/api/place/details/json?")
                .append("place_id=").append(encode(placeId))
                .append("&fields=geometry,formatted_address,name")
                .append("&key=").append(apiKey);
        if (sessionToken != null && !sessionToken.isBlank()) {
            url.append("&sessiontoken=").append(encode(sessionToken));
        }
        return get(url.toString());
    }

    public String geocodeAddress(String address, String languageCode) {
        String url = "https://maps.googleapis.com/maps/api/geocode/json?"
                + "address=" + encode(address)
                + "&components=country:IN"
                + "&language=" + encode(languageCode)
                + "&key=" + apiKey;
        return get(url);
    }

    public String nearbyPlaces(double lat, double lng, int radiusMeters) {
        String url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
                + "location=" + lat + "," + lng
                + "&radius=" + radiusMeters
                + "&key=" + apiKey;
        return get(url);
    }

    public String reverseGeocode(double lat, double lng) {
        // No result_type filter: the client (LocationService.getAddressFromCoordinates)
        // already walks every result looking for the best available component
        // (premise/neighborhood/sublocality_level_2/3/locality, in that
        // preference order) - restricting result_type here to only
        // street_address/route/neighborhood/locality/sublocality was starving
        // it of exactly the finer entries (premise, sublocality_level_2/3)
        // it's designed to prefer, which is common for rural points with no
        // formal street data, showing only the broad locality name instead
        // of the most specific one Google actually has.
        String url = "https://maps.googleapis.com/maps/api/geocode/json?"
                + "latlng=" + lat + "," + lng
                + "&key=" + apiKey;
        return get(url);
    }

    private static String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private String get(String url) {
        // build(true) = "the string is already correctly encoded" - skips
        // Spring's automatic re-encoding pass, which is what was turning the
        // literal "|" in result_type into "%7C" (Google rejects that form).
        URI uri = UriComponentsBuilder.fromHttpUrl(url).build(true).toUri();
        return restTemplate.getForObject(uri, String.class);
    }
}

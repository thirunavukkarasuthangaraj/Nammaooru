package com.shopmanagement.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.nio.charset.StandardCharsets;
import java.time.Duration;

/**
 * Server-side proxy for the Google Maps Platform REST APIs (Places,
 * Geocoding). The customer app calls these endpoints instead of Google
 * directly, so the Google Maps API key lives only on this server and never
 * ships inside the app/APK - it can then be IP-restricted in Google Cloud
 * Console to just this server, instead of being unrestricted (the only
 * option for a key embedded in client code).
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
        UriComponentsBuilder builder = UriComponentsBuilder
                .fromHttpUrl("https://maps.googleapis.com/maps/api/place/autocomplete/json")
                .queryParam("input", input)
                .queryParam("components", "country:in")
                .queryParam("language", languageCode)
                .queryParam("key", apiKey);
        if (biasLat != null && biasLng != null) {
            builder.queryParam("locationbias", "circle:50000@" + biasLat + "," + biasLng);
        }
        if (sessionToken != null && !sessionToken.isBlank()) {
            builder.queryParam("sessiontoken", sessionToken);
        }
        return get(builder);
    }

    public String placeDetails(String placeId, String sessionToken) {
        UriComponentsBuilder builder = UriComponentsBuilder
                .fromHttpUrl("https://maps.googleapis.com/maps/api/place/details/json")
                .queryParam("place_id", placeId)
                .queryParam("fields", "geometry,formatted_address,name")
                .queryParam("key", apiKey);
        if (sessionToken != null && !sessionToken.isBlank()) {
            builder.queryParam("sessiontoken", sessionToken);
        }
        return get(builder);
    }

    public String geocodeAddress(String address, String languageCode) {
        UriComponentsBuilder builder = UriComponentsBuilder
                .fromHttpUrl("https://maps.googleapis.com/maps/api/geocode/json")
                .queryParam("address", address)
                .queryParam("components", "country:IN")
                .queryParam("language", languageCode)
                .queryParam("key", apiKey);
        return get(builder);
    }

    public String reverseGeocode(double lat, double lng) {
        UriComponentsBuilder builder = UriComponentsBuilder
                .fromHttpUrl("https://maps.googleapis.com/maps/api/geocode/json")
                .queryParam("latlng", lat + "," + lng)
                .queryParam("result_type", "street_address|route|neighborhood|locality|sublocality")
                .queryParam("key", apiKey);
        return get(builder);
    }

    private String get(UriComponentsBuilder builder) {
        String url = builder.build().encode(StandardCharsets.UTF_8).toUriString();
        return restTemplate.getForObject(url, String.class);
    }
}

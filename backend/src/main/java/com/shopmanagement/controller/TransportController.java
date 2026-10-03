package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.transport.*;
import com.shopmanagement.service.TransportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Transport / fleet tracking.
 *
 *  /api/transport/public/**   anyone            Where-is-Bus feed
 *  /api/transport/me          logged in         which transport roles this user has
 *  /api/transport/register    logged in         apply as a transporter
 *  /api/transport/owner/**    active transporter fleet management + live map
 *  /api/transport/driver/**   assigned driver   trips + GPS sends
 *  /api/transport/admin/**    ADMIN             approve transporters
 */
@RestController
@RequestMapping("/api/transport")
@RequiredArgsConstructor
@Slf4j
public class TransportController {

    private final TransportService transportService;

    private String username() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        return a == null ? null : a.getName();
    }

    /* ---------------- public ---------------- */

    @GetMapping("/public/buses")
    public ResponseEntity<ApiResponse<Map<String, Object>>> publicBuses() {
        try { return ResponseUtil.success(transportService.publicBuses()); }
        catch (Exception e) { log.error("publicBuses", e); return ResponseUtil.error(e.getMessage()); }
    }

    @GetMapping("/public/positions")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> publicPositions(@RequestParam("ids") List<Long> ids) {
        try { return ResponseUtil.success(transportService.publicPositions(ids)); }
        catch (Exception e) { return ResponseUtil.error(e.getMessage()); }
    }

    /**
     * Maps key for the website. Only answered for requests whose Origin/Referer
     * is this site (or localhost for development); other callers get an empty key.
     */
    @GetMapping("/public/maps-key")
    public ResponseEntity<ApiResponse<Map<String, Object>>> mapsKey(
            @RequestHeader(value = "Origin", required = false) String origin,
            @RequestHeader(value = "Referer", required = false) String referer) {
        try {
            String src = (origin != null && !origin.isBlank()) ? origin : (referer == null ? "" : referer);
            boolean allowed = src.contains("nammaoorudelivary.in") || src.contains("localhost") || src.contains("127.0.0.1");
            if (!allowed) {
                Map<String, Object> empty = new java.util.LinkedHashMap<>();
                empty.put("key", ""); empty.put("libraries", "places,geometry");
                return ResponseUtil.success(empty);
            }
            return ResponseUtil.success(transportService.mapsBrowserKey());
        } catch (Exception e) { return ResponseUtil.error(e.getMessage()); }
    }

    /* ---------------- identity ---------------- */

    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> me() {
        try { return ResponseUtil.success(transportService.me(username())); }
        catch (Exception e) { return ResponseUtil.error(e.getMessage()); }
    }

    @PostMapping("/register")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Transporter>> register(@RequestBody Map<String, Object> body) {
        try {
            Transporter t = transportService.registerTransporter(username(),
                    s(body.get("companyName")), s(body.get("ownerName")), s(body.get("phone")));
            return ResponseUtil.created(t, t.getStatus() == Transporter.Status.ACTIVE
                    ? "Transporter profile updated" : "Registered. Waiting for admin approval.");
        } catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    /* ---------------- owner ---------------- */

    @GetMapping("/owner/bootstrap")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> ownerBootstrap() {
        try { return ResponseUtil.success(transportService.ownerBootstrap(username())); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @GetMapping("/owner/live")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> ownerLive() {
        try { return ResponseUtil.success(transportService.ownerLive(username())); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @PostMapping("/owner/vehicles")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<TransportVehicle>> saveVehicle(@RequestBody Map<String, Object> body) {
        try { return ResponseUtil.success(transportService.saveVehicle(username(), body), "Vehicle saved"); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @DeleteMapping("/owner/vehicles/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> deleteVehicle(@PathVariable Long id) {
        try { transportService.deleteVehicle(username(), id); return ResponseUtil.success(null, "Vehicle removed"); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @PostMapping("/owner/drivers")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<TransportDriver>> saveDriver(@RequestBody Map<String, Object> body) {
        try { return ResponseUtil.success(transportService.saveDriver(username(), body), "Driver saved"); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @DeleteMapping("/owner/drivers/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> deleteDriver(@PathVariable Long id) {
        try { transportService.deleteDriver(username(), id); return ResponseUtil.success(null, "Driver removed"); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @PostMapping("/owner/routes")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> saveRoute(@RequestBody Map<String, Object> body) {
        try { return ResponseUtil.success(transportService.saveRoute(username(), body), "Route saved"); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @DeleteMapping("/owner/routes/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> deleteRoute(@PathVariable Long id) {
        try { transportService.deleteRoute(username(), id); return ResponseUtil.success(null, "Route removed"); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @GetMapping("/owner/trips")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> ownerTrips(
            @RequestParam(required = false) Long vehicleId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "30") int size) {
        try { return ResponseUtil.paginated(transportService.ownerTrips(username(), vehicleId, PageRequest.of(page, size))); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @GetMapping("/owner/trips/{id}/trail")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> ownerTripTrail(@PathVariable Long id) {
        try { return ResponseUtil.success(transportService.ownerTripTrail(username(), id)); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    /* ---------------- driver ---------------- */

    @GetMapping("/driver/context")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> driverContext() {
        try { return ResponseUtil.success(transportService.driverContext(username())); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @PostMapping("/driver/trips/start")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> startTrip(@RequestBody Map<String, Object> body) {
        try { return ResponseUtil.success(transportService.startTrip(username(), Long.valueOf(s(body.get("vehicleId")))), "Trip started"); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @PostMapping("/driver/trips/{id}/end")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<TransportTrip>> endTrip(@PathVariable Long id, @RequestBody(required = false) Map<String, Object> body) {
        try {
            Double km = null;
            if (body != null && body.get("distanceKm") != null) { try { km = Double.valueOf(s(body.get("distanceKm"))); } catch (Exception ignored) {} }
            return ResponseUtil.success(transportService.endTrip(username(), id, km), "Trip ended");
        } catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    /**
     * Body: { tripId, points: [{lat,lng,speedKmh,heading,accuracyM,ts}] }
     * or a single point: { tripId, lat, lng, speedKmh, heading, accuracyM, ts }
     */
    @PostMapping("/driver/positions")
    @PreAuthorize("isAuthenticated()")
    @SuppressWarnings("unchecked")
    public ResponseEntity<ApiResponse<Map<String, Object>>> positions(@RequestBody Map<String, Object> body) {
        try {
            Long tripId = Long.valueOf(s(body.get("tripId")));
            List<Map<String, Object>> points;
            if (body.get("points") instanceof List<?> l) points = (List<Map<String, Object>>) l;
            else points = List.of(body);
            return ResponseUtil.success(transportService.reportPositions(username(), tripId, points));
        } catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    /* ---------------- admin ---------------- */

    @GetMapping("/admin/transporters")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> adminTransporters(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try { return ResponseUtil.success(transportService.adminTransporters(status, PageRequest.of(page, size))); }
        catch (Exception e) { return ResponseUtil.error(e.getMessage()); }
    }

    /** Body: { phone, companyName, ownerName } */
    @PostMapping("/admin/transporters")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> adminCreate(@RequestBody Map<String, Object> body) {
        try {
            Map<String, Object> r = transportService.adminCreateTransporter(s(body.get("phone")), s(body.get("companyName")), s(body.get("ownerName")));
            return ResponseUtil.created(r, Boolean.TRUE.equals(r.get("createdUser"))
                    ? "Transporter created. A new app account was made for this number; they can log in with OTP."
                    : "Transporter approved on the existing account for this number.");
        } catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    @PutMapping("/admin/transporters/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Transporter>> adminSetStatus(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try { return ResponseUtil.success(transportService.adminSetStatus(id, s(body.get("status"))), "Status updated"); }
        catch (Exception e) { return ResponseUtil.badRequest(e.getMessage()); }
    }

    private static String s(Object o) { return o == null ? "" : String.valueOf(o).trim(); }
}

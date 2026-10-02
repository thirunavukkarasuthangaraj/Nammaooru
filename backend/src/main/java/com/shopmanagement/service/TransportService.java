package com.shopmanagement.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.transport.*;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.repository.transport.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Transport / fleet tracking.
 *
 * Roles are derived, not stored on the user:
 *  - Owner  : the user has a row in transporters (status ACTIVE)
 *  - Driver : the user's mobile number matches an ACTIVE transport_drivers row
 *  - Public : anyone; sees vehicles with is_public = true (buses only)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TransportService {

    private final TransporterRepository transporterRepository;
    private final TransportRouteRepository routeRepository;
    private final TransportDriverRepository driverRepository;
    private final TransportVehicleRepository vehicleRepository;
    private final TransportTripRepository tripRepository;
    private final TransportVehiclePositionRepository positionRepository;
    private final TransportPositionHistoryRepository historyRepository;
    private final UserRepository userRepository;
    private final SettingService settingService;
    private final ObjectMapper objectMapper;
    private final ObjectProvider<SimpMessagingTemplate> messagingTemplate;
    private final PasswordEncoder passwordEncoder;

    /* ===================== settings ===================== */

    public Map<String, Object> publicSettings() {
        Map<String, Object> s = new LinkedHashMap<>();
        s.put("staleAfterSec", intSetting("transport.stale_after_sec", 120));
        s.put("gpsIntervalBusSec", intSetting("transport.gps_interval_bus_sec", 5));
        s.put("gpsIntervalDefaultSec", intSetting("transport.gps_interval_default_sec", 10));
        s.put("publicTracking", !"false".equalsIgnoreCase(settingService.getSettingValue("transport.public_tracking", "true")));
        return s;
    }

    private int intSetting(String key, int def) {
        try { return Integer.parseInt(settingService.getSettingValue(key, String.valueOf(def)).trim()); }
        catch (Exception e) { return def; }
    }

    private int gpsIntervalFor(TransportVehicle.VehicleType type) {
        String key = "transport.gps_interval_" + type.name().toLowerCase() + "_sec";
        String v = settingService.getSettingValue(key, null);
        if (v != null && !v.isBlank()) { try { return Integer.parseInt(v.trim()); } catch (Exception ignored) {} }
        return intSetting("transport.gps_interval_default_sec", 10);
    }

    /* ===================== identity ===================== */

    private User user(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private static String normPhone(String p) {
        if (p == null) return "";
        String d = p.replaceAll("\\D", "");
        if (d.length() > 10 && d.startsWith("91")) d = d.substring(d.length() - 10);
        return d;
    }

    /** Everything the app needs to decide which transport screens to show. */
    @Transactional(readOnly = true)
    public Map<String, Object> me(String username) {
        User u = user(username);
        Map<String, Object> out = new LinkedHashMap<>();
        Optional<Transporter> t = transporterRepository.findByUserId(u.getId());
        out.put("transporter", t.orElse(null));
        out.put("isOwner", t.isPresent() && t.get().getStatus() == Transporter.Status.ACTIVE);
        List<TransportDriver> drivers = driverRepository.findByPhoneAndStatus(normPhone(u.getMobileNumber()), TransportDriver.Status.ACTIVE);
        out.put("isDriver", !drivers.isEmpty());
        out.put("settings", publicSettings());
        return out;
    }

    @Transactional
    public Transporter registerTransporter(String username, String companyName, String ownerName, String phone) {
        User u = user(username);
        if (companyName == null || companyName.isBlank()) throw new RuntimeException("Company / fleet name is required");
        String ph = normPhone(phone != null && !phone.isBlank() ? phone : u.getMobileNumber());
        if (ph.length() != 10) throw new RuntimeException("Enter a 10-digit mobile number");
        Transporter t = transporterRepository.findByUserId(u.getId()).orElse(
                Transporter.builder().userId(u.getId()).build());
        if (t.getId() != null && t.getStatus() == Transporter.Status.BLOCKED)
            throw new RuntimeException("This transporter account is blocked. Contact support.");
        t.setCompanyName(companyName.trim());
        t.setOwnerName(ownerName == null || ownerName.isBlank() ? companyName.trim() : ownerName.trim());
        t.setPhone(ph);
        if (t.getId() == null) t.setStatus(Transporter.Status.PENDING);
        Transporter saved = transporterRepository.save(t);
        log.info("Transporter registered/updated: id={}, user={}, status={}", saved.getId(), username, saved.getStatus());
        return saved;
    }

    private Transporter owner(String username) {
        User u = user(username);
        Transporter t = transporterRepository.findByUserId(u.getId())
                .orElseThrow(() -> new RuntimeException("You are not registered as a transporter"));
        if (t.getStatus() == Transporter.Status.PENDING) throw new RuntimeException("Your transporter account is waiting for approval");
        if (t.getStatus() != Transporter.Status.ACTIVE) throw new RuntimeException("Transporter account is " + t.getStatus().name().toLowerCase());
        return t;
    }

    /* ===================== owner: bootstrap ===================== */

    @Transactional(readOnly = true)
    public Map<String, Object> ownerBootstrap(String username) {
        Transporter t = owner(username);
        List<TransportVehicle> vehicles = vehicleRepository.findByTransporterIdAndStatusNotOrderByNameAsc(t.getId(), TransportVehicle.Status.DELETED);
        List<TransportDriver> drivers = driverRepository.findByTransporterIdAndStatusOrderByNameAsc(t.getId(), TransportDriver.Status.ACTIVE);
        List<TransportRoute> routes = routeRepository.findByTransporterIdOrderByNameAsc(t.getId());
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("transporter", t);
        out.put("vehicles", vehicles.stream().map(v -> vehicleView(v, drivers, routes)).collect(Collectors.toList()));
        out.put("drivers", drivers);
        out.put("routes", routes.stream().map(this::routeView).collect(Collectors.toList()));
        out.put("positions", livePositions(vehicles.stream().map(TransportVehicle::getId).collect(Collectors.toList())));
        out.put("settings", publicSettings());
        return out;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> ownerLive(String username) {
        Transporter t = owner(username);
        List<TransportVehicle> vehicles = vehicleRepository.findByTransporterIdAndStatusNotOrderByNameAsc(t.getId(), TransportVehicle.Status.DELETED);
        return livePositions(vehicles.stream().map(TransportVehicle::getId).collect(Collectors.toList()));
    }

    private List<Map<String, Object>> livePositions(Collection<Long> vehicleIds) {
        if (vehicleIds.isEmpty()) return List.of();
        int stale = intSetting("transport.stale_after_sec", 120);
        return positionRepository.findByVehicleIdIn(vehicleIds).stream()
                .map(p -> positionView(p, stale)).collect(Collectors.toList());
    }

    private Map<String, Object> positionView(TransportVehiclePosition p, int staleSec) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("vehicleId", p.getVehicleId());
        m.put("tripId", p.getTripId());
        m.put("lat", p.getLatitude());
        m.put("lng", p.getLongitude());
        m.put("speedKmh", p.getSpeedKmh());
        m.put("heading", p.getHeading());
        m.put("accuracyM", p.getAccuracyM());
        m.put("recordedAt", p.getRecordedAt());
        long ageSec = java.time.Duration.between(p.getRecordedAt(), LocalDateTime.now()).getSeconds();
        m.put("ageSec", ageSec);
        String state = ageSec > staleSec ? "OFFLINE"
                : (p.getSpeedKmh() != null && p.getSpeedKmh().doubleValue() > 3 ? "MOVING" : "STOPPED");
        m.put("state", state);
        return m;
    }

    private Map<String, Object> vehicleView(TransportVehicle v, List<TransportDriver> drivers, List<TransportRoute> routes) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", v.getId());
        m.put("vehicleType", v.getVehicleType());
        m.put("regNo", v.getRegNo());
        m.put("name", v.getName());
        m.put("routeId", v.getRouteId());
        m.put("driverId", v.getDriverId());
        m.put("isPublic", v.getIsPublic());
        m.put("status", v.getStatus());
        m.put("createdAt", v.getCreatedAt());
        m.put("driverName", drivers.stream().filter(d -> d.getId().equals(v.getDriverId())).map(TransportDriver::getName).findFirst().orElse(null));
        m.put("routeName", routes.stream().filter(r -> r.getId().equals(v.getRouteId())).map(TransportRoute::getName).findFirst().orElse(null));
        return m;
    }

    private Map<String, Object> routeView(TransportRoute r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId());
        m.put("name", r.getName());
        m.put("source", r.getSource());
        m.put("destination", r.getDestination());
        m.put("stops", parseStops(r.getStopsJson()));
        return m;
    }

    private List<Map<String, Object>> parseStops(String json) {
        if (json == null || json.isBlank()) return List.of();
        try { return objectMapper.readValue(json, new TypeReference<List<Map<String, Object>>>() {}); }
        catch (Exception e) { return List.of(); }
    }

    /* ===================== owner: vehicles ===================== */

    @Transactional
    public TransportVehicle saveVehicle(String username, Map<String, Object> body) {
        Transporter t = owner(username);
        Long id = asLong(body.get("id"));
        TransportVehicle v = id == null ? TransportVehicle.builder().transporterId(t.getId()).build() : ownedVehicle(t, id);
        String regNo = str(body.get("regNo")).toUpperCase().replaceAll("\\s+", "");
        if (regNo.isEmpty()) throw new RuntimeException("Registration number is required");
        TransportVehicle.VehicleType type = TransportVehicle.VehicleType.BUS;
        try { type = TransportVehicle.VehicleType.valueOf(str(body.get("vehicleType")).toUpperCase()); } catch (Exception ignored) {}
        v.setVehicleType(type);
        v.setRegNo(regNo);
        String name = str(body.get("name"));
        v.setName(name.isEmpty() ? regNo : name);
        Long routeId = asLong(body.get("routeId"));
        if (routeId != null) ownedRoute(t, routeId);
        v.setRouteId(routeId);
        Long driverId = asLong(body.get("driverId"));
        if (driverId != null) ownedDriver(t, driverId);
        v.setDriverId(driverId);
        boolean pub = Boolean.TRUE.equals(body.get("isPublic")) || "true".equalsIgnoreCase(str(body.get("isPublic")));
        v.setIsPublic(type == TransportVehicle.VehicleType.BUS && pub);
        if (body.get("status") != null) {
            try { v.setStatus(TransportVehicle.Status.valueOf(str(body.get("status")).toUpperCase())); } catch (Exception ignored) {}
            if (v.getStatus() == TransportVehicle.Status.DELETED) v.setStatus(TransportVehicle.Status.ACTIVE);
        }
        return vehicleRepository.save(v);
    }

    @Transactional
    public void deleteVehicle(String username, Long id) {
        Transporter t = owner(username);
        TransportVehicle v = ownedVehicle(t, id);
        v.setStatus(TransportVehicle.Status.DELETED);
        v.setIsPublic(false);
        vehicleRepository.save(v);
        positionRepository.deleteById(id);
    }

    private TransportVehicle ownedVehicle(Transporter t, Long id) {
        TransportVehicle v = vehicleRepository.findById(id).orElseThrow(() -> new RuntimeException("Vehicle not found"));
        if (!v.getTransporterId().equals(t.getId()) || v.getStatus() == TransportVehicle.Status.DELETED) throw new RuntimeException("Vehicle not found");
        return v;
    }

    /* ===================== owner: drivers ===================== */

    @Transactional
    public TransportDriver saveDriver(String username, Map<String, Object> body) {
        Transporter t = owner(username);
        String name = str(body.get("name"));
        String phone = normPhone(str(body.get("phone")));
        if (name.isEmpty()) throw new RuntimeException("Driver name is required");
        if (phone.length() != 10) throw new RuntimeException("Enter the driver's 10-digit mobile number");
        Long id = asLong(body.get("id"));
        Optional<TransportDriver> dup = driverRepository.findFirstByTransporterIdAndPhoneAndStatus(t.getId(), phone, TransportDriver.Status.ACTIVE);
        if (dup.isPresent() && !dup.get().getId().equals(id)) throw new RuntimeException("A driver with this number already exists");
        TransportDriver d = id == null ? TransportDriver.builder().transporterId(t.getId()).build() : ownedDriver(t, id);
        d.setName(name);
        d.setPhone(phone);
        return driverRepository.save(d);
    }

    @Transactional
    public void deleteDriver(String username, Long id) {
        Transporter t = owner(username);
        TransportDriver d = ownedDriver(t, id);
        d.setStatus(TransportDriver.Status.DELETED);
        driverRepository.save(d);
        // unassign from vehicles
        vehicleRepository.findByDriverIdInAndStatus(List.of(id), TransportVehicle.Status.ACTIVE).forEach(v -> {
            v.setDriverId(null); vehicleRepository.save(v);
        });
    }

    private TransportDriver ownedDriver(Transporter t, Long id) {
        TransportDriver d = driverRepository.findById(id).orElseThrow(() -> new RuntimeException("Driver not found"));
        if (!d.getTransporterId().equals(t.getId()) || d.getStatus() != TransportDriver.Status.ACTIVE) throw new RuntimeException("Driver not found");
        return d;
    }

    /* ===================== owner: routes ===================== */

    @Transactional
    public Map<String, Object> saveRoute(String username, Map<String, Object> body) {
        Transporter t = owner(username);
        String source = str(body.get("source")), destination = str(body.get("destination"));
        if (source.isEmpty() || destination.isEmpty()) throw new RuntimeException("Source and destination are required");
        Long id = asLong(body.get("id"));
        TransportRoute r = id == null ? TransportRoute.builder().transporterId(t.getId()).build() : ownedRoute(t, id);
        String name = str(body.get("name"));
        r.setName(name.isEmpty() ? source + " - " + destination : name);
        r.setSource(source);
        r.setDestination(destination);
        List<Map<String, Object>> stops = new ArrayList<>();
        Object raw = body.get("stops");
        if (raw instanceof List<?> list) {
            for (Object o : list) {
                if (!(o instanceof Map<?, ?> m)) continue;
                String sname = str(m.get("name"));
                if (sname.isEmpty()) continue;
                Map<String, Object> s = new LinkedHashMap<>();
                s.put("name", sname);
                s.put("lat", asDouble(m.get("lat")));
                s.put("lng", asDouble(m.get("lng")));
                stops.add(s);
            }
        }
        try { r.setStopsJson(objectMapper.writeValueAsString(stops)); } catch (Exception e) { r.setStopsJson("[]"); }
        return routeView(routeRepository.save(r));
    }

    @Transactional
    public void deleteRoute(String username, Long id) {
        Transporter t = owner(username);
        ownedRoute(t, id);
        vehicleRepository.findByTransporterIdAndStatusNotOrderByNameAsc(t.getId(), TransportVehicle.Status.DELETED).stream()
                .filter(v -> id.equals(v.getRouteId()))
                .forEach(v -> { v.setRouteId(null); vehicleRepository.save(v); });
        routeRepository.deleteById(id);
    }

    private TransportRoute ownedRoute(Transporter t, Long id) {
        TransportRoute r = routeRepository.findById(id).orElseThrow(() -> new RuntimeException("Route not found"));
        if (!r.getTransporterId().equals(t.getId())) throw new RuntimeException("Route not found");
        return r;
    }

    /* ===================== owner: trips ===================== */

    @Transactional(readOnly = true)
    public Page<TransportTrip> ownerTrips(String username, Long vehicleId, Pageable pageable) {
        Transporter t = owner(username);
        if (vehicleId != null) return tripRepository.findByTransporterIdAndVehicleIdOrderByStartedAtDesc(t.getId(), vehicleId, pageable);
        return tripRepository.findByTransporterIdOrderByStartedAtDesc(t.getId(), pageable);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> ownerTripTrail(String username, Long tripId) {
        Transporter t = owner(username);
        TransportTrip trip = tripRepository.findById(tripId).orElseThrow(() -> new RuntimeException("Trip not found"));
        if (!trip.getTransporterId().equals(t.getId())) throw new RuntimeException("Trip not found");
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("trip", trip);
        out.put("points", historyRepository.findByTripIdOrderByRecordedAtAsc(tripId).stream().map(h -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("lat", h.getLatitude()); m.put("lng", h.getLongitude());
            m.put("speedKmh", h.getSpeedKmh()); m.put("recordedAt", h.getRecordedAt());
            return m;
        }).collect(Collectors.toList()));
        return out;
    }

    /* ===================== driver ===================== */

    private List<TransportDriver> driverRows(String username) {
        User u = user(username);
        List<TransportDriver> rows = driverRepository.findByPhoneAndStatus(normPhone(u.getMobileNumber()), TransportDriver.Status.ACTIVE);
        if (rows.isEmpty()) throw new RuntimeException("Your number is not registered as a driver by any transporter");
        return rows;
    }

    /** Vehicles assigned to this driver (across all transporters that added this phone), plus any running trip. */
    @Transactional(readOnly = true)
    public Map<String, Object> driverContext(String username) {
        List<TransportDriver> drivers = driverRows(username);
        List<Long> driverIds = drivers.stream().map(TransportDriver::getId).collect(Collectors.toList());
        List<TransportVehicle> vehicles = vehicleRepository.findByDriverIdInAndStatus(driverIds, TransportVehicle.Status.ACTIVE);
        Set<Long> routeIds = vehicles.stream().map(TransportVehicle::getRouteId).filter(Objects::nonNull).collect(Collectors.toSet());
        Map<Long, TransportRoute> routes = routeIds.isEmpty() ? Map.of()
                : routeRepository.findByIdIn(routeIds).stream().collect(Collectors.toMap(TransportRoute::getId, r -> r));
        Map<Long, Transporter> owners = transporterRepository.findAllById(
                vehicles.stream().map(TransportVehicle::getTransporterId).collect(Collectors.toSet()))
                .stream().collect(Collectors.toMap(Transporter::getId, t -> t));
        TransportTrip open = null;
        for (Long did : driverIds) {
            List<TransportTrip> running = tripRepository.findByDriverIdAndStatus(did, TransportTrip.Status.RUNNING);
            if (!running.isEmpty()) { open = running.get(running.size() - 1); break; }
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("driverName", drivers.get(0).getName());
        out.put("vehicles", vehicles.stream().map(v -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", v.getId()); m.put("name", v.getName()); m.put("regNo", v.getRegNo());
            m.put("vehicleType", v.getVehicleType()); m.put("isPublic", v.getIsPublic());
            Transporter o = owners.get(v.getTransporterId());
            m.put("ownerName", o == null ? null : o.getCompanyName());
            TransportRoute r = routes.get(v.getRouteId());
            m.put("route", r == null ? null : routeView(r));
            m.put("gpsIntervalSec", gpsIntervalFor(v.getVehicleType()));
            return m;
        }).collect(Collectors.toList()));
        out.put("openTrip", open);
        out.put("settings", publicSettings());
        return out;
    }

    @Transactional
    public Map<String, Object> startTrip(String username, Long vehicleId) {
        List<TransportDriver> drivers = driverRows(username);
        TransportVehicle v = vehicleRepository.findById(vehicleId).orElseThrow(() -> new RuntimeException("Vehicle not found"));
        TransportDriver me = drivers.stream().filter(d -> d.getId().equals(v.getDriverId())).findFirst()
                .orElseThrow(() -> new RuntimeException("This vehicle is not assigned to you"));
        if (v.getStatus() != TransportVehicle.Status.ACTIVE) throw new RuntimeException("Vehicle is not active");
        // close anything left running by this driver or on this vehicle
        LocalDateTime now = LocalDateTime.now();
        for (TransportDriver d : drivers)
            tripRepository.findByDriverIdAndStatus(d.getId(), TransportTrip.Status.RUNNING).forEach(tr -> endTripRow(tr, now, null));
        tripRepository.findByVehicleIdAndStatus(vehicleId, TransportTrip.Status.RUNNING).forEach(tr -> endTripRow(tr, now, null));
        TransportTrip trip = tripRepository.save(TransportTrip.builder()
                .transporterId(v.getTransporterId()).vehicleId(vehicleId).driverId(me.getId())
                .routeId(v.getRouteId()).startedAt(now).status(TransportTrip.Status.RUNNING).build());
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("trip", trip);
        out.put("gpsIntervalSec", gpsIntervalFor(v.getVehicleType()));
        log.info("Transport trip started: trip={}, vehicle={}, driver={}", trip.getId(), vehicleId, me.getId());
        return out;
    }

    @Transactional
    public TransportTrip endTrip(String username, Long tripId, Double distanceKm) {
        List<TransportDriver> drivers = driverRows(username);
        TransportTrip trip = tripRepository.findById(tripId).orElseThrow(() -> new RuntimeException("Trip not found"));
        if (drivers.stream().noneMatch(d -> d.getId().equals(trip.getDriverId()))) throw new RuntimeException("Trip not found");
        if (trip.getStatus() == TransportTrip.Status.ENDED) return trip;
        endTripRow(trip, LocalDateTime.now(), distanceKm);
        // Keep the last position but mark that the trip ended so public view shows it as stopped soon
        log.info("Transport trip ended: trip={}, km={}", tripId, distanceKm);
        return trip;
    }

    private void endTripRow(TransportTrip trip, LocalDateTime when, Double distanceKm) {
        trip.setStatus(TransportTrip.Status.ENDED);
        trip.setEndedAt(when);
        if (distanceKm != null) trip.setDistanceKm(BigDecimal.valueOf(distanceKm).setScale(2, RoundingMode.HALF_UP));
        else if (trip.getDistanceKm() == null) trip.setDistanceKm(BigDecimal.valueOf(pathKm(historyRepository.findByTripIdOrderByRecordedAtAsc(trip.getId()))).setScale(2, RoundingMode.HALF_UP));
        tripRepository.save(trip);
    }

    /**
     * GPS send from the driver app. Accepts one point or a batch (points[]) for
     * buffered offline sends. Upserts the live row and appends to history.
     */
    @Transactional
    public Map<String, Object> reportPositions(String username, Long tripId, List<Map<String, Object>> points) {
        List<TransportDriver> drivers = driverRows(username);
        TransportTrip trip = tripRepository.findById(tripId).orElseThrow(() -> new RuntimeException("Trip not found"));
        if (drivers.stream().noneMatch(d -> d.getId().equals(trip.getDriverId()))) throw new RuntimeException("Trip not found");
        Map<String, Object> out = new LinkedHashMap<>();
        if (trip.getStatus() != TransportTrip.Status.RUNNING) {
            out.put("accepted", 0); out.put("tripEnded", true);
            return out;
        }
        if (points == null || points.isEmpty()) { out.put("accepted", 0); return out; }
        TransportPositionHistory last = null;
        int accepted = 0;
        for (Map<String, Object> p : points) {
            Double lat = asDouble(p.get("lat")), lng = asDouble(p.get("lng"));
            if (lat == null || lng == null || Math.abs(lat) > 90 || Math.abs(lng) > 180) continue;
            LocalDateTime ts = LocalDateTime.now();
            Object tsRaw = p.get("ts");
            if (tsRaw instanceof Number n) {
                try { ts = LocalDateTime.ofInstant(java.time.Instant.ofEpochMilli(n.longValue()), java.time.ZoneId.systemDefault()); } catch (Exception ignored) {}
            }
            TransportPositionHistory h = TransportPositionHistory.builder()
                    .vehicleId(trip.getVehicleId()).tripId(tripId)
                    .latitude(BigDecimal.valueOf(lat).setScale(7, RoundingMode.HALF_UP))
                    .longitude(BigDecimal.valueOf(lng).setScale(7, RoundingMode.HALF_UP))
                    .speedKmh(dec(asDouble(p.get("speedKmh")), 1))
                    .recordedAt(ts).build();
            historyRepository.save(h);
            if (last == null || !ts.isBefore(last.getRecordedAt())) { last = h; }
            accepted++;
        }
        if (last != null) {
            Map<String, Object> lp = points.get(points.size() - 1);
            TransportVehiclePosition live = TransportVehiclePosition.builder()
                    .vehicleId(trip.getVehicleId()).tripId(tripId).driverId(trip.getDriverId())
                    .latitude(last.getLatitude()).longitude(last.getLongitude())
                    .speedKmh(last.getSpeedKmh())
                    .heading(dec(asDouble(lp.get("heading")), 1))
                    .accuracyM(dec(asDouble(lp.get("accuracyM")), 1))
                    .recordedAt(last.getRecordedAt()).build();
            positionRepository.save(live);
            broadcast(live);
        }
        out.put("accepted", accepted);
        out.put("tripEnded", false);
        return out;
    }

    private void broadcast(TransportVehiclePosition live) {
        SimpMessagingTemplate tpl = messagingTemplate.getIfAvailable();
        if (tpl == null) return;
        try {
            Map<String, Object> view = positionView(live, intSetting("transport.stale_after_sec", 120));
            tpl.convertAndSend("/topic/transport/vehicle/" + live.getVehicleId(), view);
        } catch (Exception e) {
            log.debug("Transport broadcast failed: {}", e.getMessage());
        }
    }

    /* ===================== public ===================== */

    @Transactional(readOnly = true)
    public Map<String, Object> publicBuses() {
        Map<String, Object> out = new LinkedHashMap<>();
        Map<String, Object> settings = publicSettings();
        out.put("settings", settings);
        if (Boolean.FALSE.equals(settings.get("publicTracking"))) { out.put("buses", List.of()); out.put("positions", List.of()); return out; }
        List<TransportVehicle> buses = vehicleRepository.findByIsPublicTrueAndStatusAndVehicleType(TransportVehicle.Status.ACTIVE, TransportVehicle.VehicleType.BUS);
        Map<Long, Transporter> owners = transporterRepository.findAllById(
                buses.stream().map(TransportVehicle::getTransporterId).collect(Collectors.toSet()))
                .stream().filter(t -> t.getStatus() == Transporter.Status.ACTIVE)
                .collect(Collectors.toMap(Transporter::getId, t -> t));
        buses = buses.stream().filter(b -> owners.containsKey(b.getTransporterId())).collect(Collectors.toList());
        Set<Long> routeIds = buses.stream().map(TransportVehicle::getRouteId).filter(Objects::nonNull).collect(Collectors.toSet());
        Map<Long, TransportRoute> routes = routeIds.isEmpty() ? Map.of()
                : routeRepository.findByIdIn(routeIds).stream().collect(Collectors.toMap(TransportRoute::getId, r -> r));
        out.put("buses", buses.stream().map(b -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", b.getId()); m.put("name", b.getName()); m.put("regNo", b.getRegNo());
            m.put("operator", owners.get(b.getTransporterId()).getCompanyName());
            TransportRoute r = routes.get(b.getRouteId());
            m.put("route", r == null ? null : routeView(r));
            return m;
        }).collect(Collectors.toList()));
        out.put("positions", livePositions(buses.stream().map(TransportVehicle::getId).collect(Collectors.toList())));
        return out;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> publicPositions(List<Long> ids) {
        if (ids == null || ids.isEmpty()) return List.of();
        Set<Long> allowed = vehicleRepository.findByIsPublicTrueAndStatusAndVehicleType(TransportVehicle.Status.ACTIVE, TransportVehicle.VehicleType.BUS)
                .stream().map(TransportVehicle::getId).collect(Collectors.toSet());
        return livePositions(ids.stream().filter(allowed::contains).collect(Collectors.toList()));
    }

    /* ===================== admin ===================== */

    @Transactional(readOnly = true)
    public Map<String, Object> adminTransporters(String status, Pageable pageable) {
        Page<Transporter> page;
        if (status != null && !status.isBlank()) page = transporterRepository.findByStatusOrderByCreatedAtDesc(Transporter.Status.valueOf(status.toUpperCase()), pageable);
        else page = transporterRepository.findAllByOrderByCreatedAtDesc(pageable);
        List<Map<String, Object>> rows = page.getContent().stream().map(t -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", t.getId()); m.put("userId", t.getUserId()); m.put("companyName", t.getCompanyName());
            m.put("ownerName", t.getOwnerName()); m.put("phone", t.getPhone()); m.put("status", t.getStatus());
            m.put("createdAt", t.getCreatedAt());
            m.put("vehicleCount", vehicleRepository.countByTransporterIdAndStatus(t.getId(), TransportVehicle.Status.ACTIVE));
            return m;
        }).collect(Collectors.toList());
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("content", rows);
        out.put("totalElements", page.getTotalElements());
        out.put("totalPages", page.getTotalPages());
        out.put("page", page.getNumber());
        out.put("pendingCount", transporterRepository.countByStatus(Transporter.Status.PENDING));
        return out;
    }

    /**
     * Admin creates an approved transporter from the website. Finds the customer
     * account by mobile number, or creates one so the owner can log into the app
     * with OTP on that number straight away.
     */
    @Transactional
    public Map<String, Object> adminCreateTransporter(String phone, String companyName, String ownerName) {
        String ph = normPhone(phone);
        if (ph.length() != 10) throw new RuntimeException("Enter a 10-digit mobile number");
        if (companyName == null || companyName.isBlank()) throw new RuntimeException("Company / fleet name is required");
        boolean createdUser = false;
        User u = userRepository.findByMobileNumber(ph).orElse(null);
        if (u == null) u = userRepository.findByMobileNumber("+91" + ph).orElse(null);
        if (u == null) {
            String base = "transporter_" + ph.substring(6);
            String username = base;
            int n = 1;
            while (userRepository.existsByUsername(username)) username = base + "_" + (n++);
            String name = (ownerName == null || ownerName.isBlank()) ? companyName.trim() : ownerName.trim();
            u = userRepository.save(User.builder()
                    .username(username)
                    .email(null)
                    .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                    .firstName(name).lastName(name)
                    .mobileNumber(ph)
                    .role(User.UserRole.USER)
                    .status(User.UserStatus.ACTIVE)
                    .emailVerified(false)
                    .mobileVerified(true)
                    .build());
            createdUser = true;
        }
        Transporter t = transporterRepository.findByUserId(u.getId()).orElse(Transporter.builder().userId(u.getId()).build());
        t.setCompanyName(companyName.trim());
        t.setOwnerName((ownerName == null || ownerName.isBlank()) ? companyName.trim() : ownerName.trim());
        t.setPhone(ph);
        t.setStatus(Transporter.Status.ACTIVE);
        Transporter saved = transporterRepository.save(t);
        log.info("Admin created/approved transporter {} for user {} (newUser={})", saved.getId(), u.getId(), createdUser);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("transporter", saved);
        out.put("userId", u.getId());
        out.put("username", u.getUsername());
        out.put("createdUser", createdUser);
        return out;
    }

    @Transactional
    public Transporter adminSetStatus(Long id, String status) {
        Transporter t = transporterRepository.findById(id).orElseThrow(() -> new RuntimeException("Transporter not found"));
        t.setStatus(Transporter.Status.valueOf(status.toUpperCase()));
        Transporter saved = transporterRepository.save(t);
        if (saved.getStatus() != Transporter.Status.ACTIVE) {
            // hide this operator's buses from the public tracker immediately
            vehicleRepository.findByTransporterIdAndStatusNotOrderByNameAsc(id, TransportVehicle.Status.DELETED)
                    .forEach(v -> { if (Boolean.TRUE.equals(v.getIsPublic())) { v.setIsPublic(false); vehicleRepository.save(v); } });
        }
        log.info("Transporter {} status set to {}", id, saved.getStatus());
        return saved;
    }

    /** Trim trail history older than 30 days, nightly. */
    @Scheduled(cron = "0 30 3 * * *")
    @Transactional
    public void purgeOldHistory() {
        try {
            int n = historyRepository.deleteOlderThan(LocalDateTime.now().minusDays(30));
            if (n > 0) log.info("Transport history purge removed {} rows", n);
        } catch (Exception e) {
            log.warn("Transport history purge failed: {}", e.getMessage());
        }
    }

    /* ===================== helpers ===================== */

    private static double pathKm(List<TransportPositionHistory> pts) {
        double total = 0;
        for (int i = 1; i < pts.size(); i++) {
            total += haversine(pts.get(i - 1).getLatitude().doubleValue(), pts.get(i - 1).getLongitude().doubleValue(),
                    pts.get(i).getLatitude().doubleValue(), pts.get(i).getLongitude().doubleValue());
        }
        return total;
    }

    private static double haversine(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371, dLat = Math.toRadians(lat2 - lat1), dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return 2 * R * Math.asin(Math.sqrt(a));
    }

    private static String str(Object o) { return o == null ? "" : String.valueOf(o).trim(); }
    private static Long asLong(Object o) {
        if (o == null || String.valueOf(o).isBlank()) return null;
        try { return Long.valueOf(String.valueOf(o).trim()); } catch (Exception e) { return null; }
    }
    private static Double asDouble(Object o) {
        if (o == null || String.valueOf(o).isBlank()) return null;
        try { return Double.valueOf(String.valueOf(o).trim()); } catch (Exception e) { return null; }
    }
    private static BigDecimal dec(Double d, int scale) {
        return d == null ? null : BigDecimal.valueOf(d).setScale(scale, RoundingMode.HALF_UP);
    }
}

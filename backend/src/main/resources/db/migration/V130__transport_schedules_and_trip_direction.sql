-- Timetable: scheduled departures per vehicle (A->B or B->A), any number per day.
CREATE TABLE IF NOT EXISTS transport_schedules (
    id BIGSERIAL PRIMARY KEY,
    transporter_id BIGINT NOT NULL REFERENCES transporters(id),
    vehicle_id BIGINT NOT NULL REFERENCES transport_vehicles(id),
    route_id BIGINT REFERENCES transport_routes(id),
    direction VARCHAR(2) NOT NULL DEFAULT 'AB',          -- AB = From->To, BA = To->From
    depart_time VARCHAR(5) NOT NULL,                      -- HH:mm (24h)
    arrive_time VARCHAR(5) NOT NULL,                      -- HH:mm (24h)
    days VARCHAR(40) NOT NULL DEFAULT 'DAILY',            -- DAILY | MON,TUE,...
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_transport_schedules_vehicle ON transport_schedules(vehicle_id, depart_time);

-- A trip knows which way it is going.
ALTER TABLE transport_trips ADD COLUMN IF NOT EXISTS direction VARCHAR(2) NOT NULL DEFAULT 'AB';
ALTER TABLE transport_trips ADD COLUMN IF NOT EXISTS schedule_id BIGINT;

-- Sample timetable for the first bus (Tirupattur <-> Alangayam), editable in the portal.
INSERT INTO transport_schedules (transporter_id, vehicle_id, route_id, direction, depart_time, arrive_time, days, is_active, created_at)
SELECT v.transporter_id, v.id, v.route_id, s.direction, s.dep, s.arr, 'DAILY', TRUE, NOW()
  FROM transport_vehicles v
  JOIN (VALUES ('AB','06:00','07:00'), ('BA','07:20','08:20'), ('AB','10:00','11:00'), ('BA','11:20','12:20'),
               ('AB','14:00','15:00'), ('BA','15:20','16:20'), ('AB','18:00','19:00'), ('BA','19:20','20:20')) AS s(direction, dep, arr) ON TRUE
 WHERE v.reg_no = 'TN83TT0000' AND v.route_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM transport_schedules x WHERE x.vehicle_id = v.id);

package com.shopmanagement.entity.transport;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "transport_routes")
@Data @Builder @NoArgsConstructor @AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class TransportRoute {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "transporter_id", nullable = false)
    private Long transporterId;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(nullable = false, length = 200)
    private String source;

    @Column(nullable = false, length = 200)
    private String destination;

    @Column(name = "source_lat", precision = 10, scale = 7)
    private java.math.BigDecimal sourceLat;

    @Column(name = "source_lng", precision = 10, scale = 7)
    private java.math.BigDecimal sourceLng;

    @Column(name = "dest_lat", precision = 10, scale = 7)
    private java.math.BigDecimal destLat;

    @Column(name = "dest_lng", precision = 10, scale = 7)
    private java.math.BigDecimal destLng;

    /** JSON array: [{"name":"Stop","lat":12.5,"lng":78.5}] */
    @Column(name = "stops_json", columnDefinition = "TEXT")
    private String stopsJson;

    @CreatedDate @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}

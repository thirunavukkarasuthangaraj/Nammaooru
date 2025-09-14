-- Simple fix for delivery partner documents table
DROP TABLE IF EXISTS delivery_partner_documents;

CREATE TABLE delivery_partner_documents (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_type VARCHAR(100),
    file_size BIGINT NOT NULL,
    verification_status VARCHAR(20) DEFAULT 'PENDING',
    verification_notes TEXT,
    verified_by VARCHAR(100),
    verified_at TIMESTAMP,
    license_number VARCHAR(50),
    vehicle_number VARCHAR(20),
    expiry_date DATE,
    is_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add foreign key constraint
ALTER TABLE delivery_partner_documents
ADD CONSTRAINT fk_partner_documents_user
FOREIGN KEY (partner_id) REFERENCES users(id);

-- Test insert to verify table works
INSERT INTO delivery_partner_documents
(partner_id, document_type, document_name, file_path, original_filename, file_size)
VALUES
(37, 'DRIVER_PHOTO', 'Test Document', '/test/path', 'test.jpg', 1024);

-- If insert works, delete the test record
DELETE FROM delivery_partner_documents WHERE document_name = 'Test Document';
-- Create delivery_partner_documents table
CREATE TABLE IF NOT EXISTS delivery_partner_documents (
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
FOREIGN KEY (partner_id) REFERENCES users(id) ON DELETE CASCADE;

-- Add unique constraint
ALTER TABLE delivery_partner_documents
ADD CONSTRAINT uk_partner_doc_type
UNIQUE (partner_id, document_type);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_delivery_partner_docs_partner ON delivery_partner_documents(partner_id);
CREATE INDEX IF NOT EXISTS idx_delivery_partner_docs_type ON delivery_partner_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_delivery_partner_docs_status ON delivery_partner_documents(verification_status);
CREATE INDEX IF NOT EXISTS idx_delivery_partner_docs_created ON delivery_partner_documents(created_at);

-- Insert some sample data if needed
-- You can uncomment this if you want to test with sample data
/*
INSERT INTO delivery_partner_documents
(partner_id, document_type, document_name, file_path, original_filename, file_size, verification_status)
VALUES
(37, 'DRIVER_PHOTO', 'Driver Photo', '/uploads/documents/delivery-partners/37/driver_photo.jpg', 'driver_photo.jpg', 1024, 'PENDING')
ON CONFLICT (partner_id, document_type) DO NOTHING;
*/
-- Connect to your PostgreSQL database and run this script
-- This will create the shop_documents table

CREATE TABLE IF NOT EXISTS shop_documents (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_type VARCHAR(100),
    file_size BIGINT,
    verification_status VARCHAR(20) DEFAULT 'PENDING',
    verification_notes TEXT,
    verified_by VARCHAR(255),
    verified_at TIMESTAMP,
    is_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_shop_documents_shop 
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_shop_documents_shop_id ON shop_documents(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_documents_type ON shop_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_shop_documents_status ON shop_documents(verification_status);

-- Verify the table was created
SELECT 'shop_documents table created successfully' as result;
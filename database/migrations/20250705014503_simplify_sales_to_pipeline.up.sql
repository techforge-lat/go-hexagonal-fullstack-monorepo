-- Simplify Sales Schema to Single Pipeline Table
-- Consolidate opportunities and proposals into a unified sales.pipeline table

-- =============================================================================
-- 1. CREATE NEW sales.pipeline TABLE
-- =============================================================================

CREATE TABLE sales.pipeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES auth.organizations(id),
    customer_id UUID NOT NULL REFERENCES customers.customers(id), -- Only customers, no prospects
    pipeline_number VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    stage VARCHAR(50) NOT NULL, -- References catalog_options (LEAD, QUALIFIED, PROPOSAL, NEGOTIATION, CLOSED_WON, CLOSED_LOST)
    status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL, -- References catalog_options (ACTIVE, PAUSED, CANCELLED, COMPLETED)
    estimated_value NUMERIC(12,2) DEFAULT 0 NOT NULL,
    actual_value NUMERIC(12,2),
    probability NUMERIC(5,2) DEFAULT 0 CHECK (probability >= 0 AND probability <= 100),
    estimated_close_date DATE,
    actual_close_date DATE,
    currency_code VARCHAR(3) DEFAULT 'USD',
    assigned_sales_rep_id UUID REFERENCES auth.users(id),
    priority VARCHAR(20) DEFAULT 'MEDIUM', -- References catalog_options
    lead_source VARCHAR(50), -- References catalog_options
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    last_activity_date TIMESTAMP,
    next_follow_up_date DATE,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id)
);

-- =============================================================================
-- 2. CREATE NEW sales.interactions_new TABLE (UPDATED STRUCTURE)
-- =============================================================================

-- Create new interactions table without prospect_id and with pipeline_id
CREATE TABLE sales.interactions_new (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES auth.organizations(id),
    customer_id UUID REFERENCES customers.customers(id),
    pipeline_id UUID REFERENCES sales.pipeline(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    interaction_type VARCHAR(50) NOT NULL, -- References catalog_options (call, email, meeting, demo, proposal_sent, etc)
    subject VARCHAR(200),
    summary TEXT,
    interaction_date TIMESTAMP DEFAULT NOW() NOT NULL,
    duration_minutes INTEGER,
    outcome VARCHAR(50), -- References catalog_options
    next_action VARCHAR(200),
    next_action_date DATE,
    channel VARCHAR(50), -- References catalog_options (phone, email, in-person, video, etc)
    file_url VARCHAR(500), -- For proposal documents and attachments
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- =============================================================================
-- 3. MIGRATE DATA FROM OPPORTUNITIES TO PIPELINE
-- =============================================================================

-- Generate pipeline numbers for opportunities
INSERT INTO sales.pipeline (
    id, organization_id, customer_id, pipeline_number, name, description,
    stage, status, estimated_value, actual_value, probability,
    estimated_close_date, actual_close_date, assigned_sales_rep_id,
    priority, lead_source, notes, created_at, updated_at,
    last_activity_date, next_follow_up_date, created_by, updated_by
)
SELECT 
    o.id,
    o.organization_id,
    COALESCE(o.customer_id, (
        -- If opportunity references a prospect, try to find the related customer
        SELECT p.customer_id FROM customers.prospects p WHERE p.id = o.prospect_id
    )),
    'PIPE-' || EXTRACT(YEAR FROM o.created_at) || '-' || LPAD(ROW_NUMBER() OVER (ORDER BY o.created_at)::TEXT, 4, '0'),
    o.name,
    o.description,
    o.stage,
    o.status,
    o.estimated_value,
    o.actual_value,
    o.probability,
    o.estimated_close_date,
    o.actual_close_date,
    o.assigned_sales_rep_id,
    o.priority,
    o.lead_source,
    o.notes,
    o.created_at,
    o.updated_at,
    o.last_activity_date,
    o.next_follow_up_date,
    o.created_by,
    o.updated_by
FROM sales.opportunities o
WHERE COALESCE(o.customer_id, (
    SELECT p.customer_id FROM customers.prospects p WHERE p.id = o.prospect_id
)) IS NOT NULL;

-- =============================================================================
-- 4. MIGRATE DATA FROM PROPOSALS TO PIPELINE (AS PROPOSAL STAGE)
-- =============================================================================

-- Insert proposals as pipeline entries in PROPOSAL stage
INSERT INTO sales.pipeline (
    organization_id, customer_id, pipeline_number, name, description,
    stage, status, estimated_value, priority, notes,
    created_at, updated_at, created_by
)
SELECT 
    p.organization_id,
    COALESCE(p.customer_id, (
        -- If proposal references a prospect, try to find the related customer
        SELECT pr.customer_id FROM customers.prospects pr WHERE pr.id = p.prospect_id
    )),
    'PROP-' || EXTRACT(YEAR FROM p.created_at) || '-' || LPAD(ROW_NUMBER() OVER (ORDER BY p.created_at)::TEXT, 4, '0'),
    p.title,
    p.description,
    'PROPOSAL', -- Set stage as PROPOSAL
    CASE 
        WHEN p.status = 'DRAFT' THEN 'ACTIVE'
        WHEN p.status IN ('SENT', 'REVIEWED') THEN 'ACTIVE'
        WHEN p.status = 'APPROVED' THEN 'COMPLETED'
        WHEN p.status IN ('REJECTED', 'EXPIRED') THEN 'CANCELLED'
        ELSE 'ACTIVE'
    END,
    p.total_amount,
    'MEDIUM', -- Default priority
    COALESCE(p.notes, p.terms_and_conditions),
    p.created_at,
    p.updated_at,
    p.created_by
FROM sales.proposals p
WHERE COALESCE(p.customer_id, (
    SELECT pr.customer_id FROM customers.prospects pr WHERE pr.id = p.prospect_id
)) IS NOT NULL;

-- =============================================================================
-- 5. MIGRATE INTERACTIONS DATA
-- =============================================================================

-- Migrate interactions that reference opportunities
INSERT INTO sales.interactions_new (
    id, organization_id, customer_id, pipeline_id, user_id,
    interaction_type, subject, summary, interaction_date,
    duration_minutes, outcome, next_action, next_action_date,
    channel, created_at, updated_at
)
SELECT 
    i.id,
    i.organization_id,
    COALESCE(i.customer_id, (
        SELECT p.customer_id FROM customers.prospects p WHERE p.id = i.prospect_id
    )),
    i.opportunity_id, -- This becomes pipeline_id
    i.user_id,
    i.interaction_type,
    i.subject,
    i.summary,
    i.interaction_date,
    i.duration_minutes,
    i.outcome,
    i.next_action,
    i.next_action_date,
    i.channel,
    i.created_at,
    i.updated_at
FROM sales.interactions i
WHERE i.opportunity_id IS NOT NULL
AND COALESCE(i.customer_id, (
    SELECT p.customer_id FROM customers.prospects p WHERE p.id = i.prospect_id
)) IS NOT NULL;

-- Migrate interactions that only reference customers/prospects (no opportunity)
INSERT INTO sales.interactions_new (
    id, organization_id, customer_id, user_id,
    interaction_type, subject, summary, interaction_date,
    duration_minutes, outcome, next_action, next_action_date,
    channel, created_at, updated_at
)
SELECT 
    i.id,
    i.organization_id,
    COALESCE(i.customer_id, (
        SELECT p.customer_id FROM customers.prospects p WHERE p.id = i.prospect_id
    )),
    i.user_id,
    i.interaction_type,
    i.subject,
    i.summary,
    i.interaction_date,
    i.duration_minutes,
    i.outcome,
    i.next_action,
    i.next_action_date,
    i.channel,
    i.created_at,
    i.updated_at
FROM sales.interactions i
WHERE i.opportunity_id IS NULL
AND COALESCE(i.customer_id, (
    SELECT p.customer_id FROM customers.prospects p WHERE p.id = i.prospect_id
)) IS NOT NULL;

-- =============================================================================
-- 6. UPDATE sales.interaction_notes TO REFERENCE NEW INTERACTIONS
-- =============================================================================

-- interaction_notes will automatically reference the migrated interactions
-- No changes needed as the interaction IDs are preserved

-- =============================================================================
-- 7. DROP OLD TABLES
-- =============================================================================

DROP TABLE sales.opportunity_products CASCADE;
DROP TABLE sales.proposal_items CASCADE;
DROP TABLE sales.interactions CASCADE;
DROP TABLE sales.proposals CASCADE;
DROP TABLE sales.opportunities CASCADE;

-- =============================================================================
-- 8. RENAME NEW INTERACTIONS TABLE
-- =============================================================================

ALTER TABLE sales.interactions_new RENAME TO interactions;

-- =============================================================================
-- 9. CREATE INDEXES FOR PERFORMANCE
-- =============================================================================

-- Indexes for sales.pipeline
CREATE INDEX idx_pipeline_organization_id ON sales.pipeline(organization_id);
CREATE INDEX idx_pipeline_customer_id ON sales.pipeline(customer_id);
CREATE INDEX idx_pipeline_number ON sales.pipeline(pipeline_number);
CREATE INDEX idx_pipeline_stage ON sales.pipeline(stage);
CREATE INDEX idx_pipeline_status ON sales.pipeline(status);
CREATE INDEX idx_pipeline_assigned_sales_rep ON sales.pipeline(assigned_sales_rep_id);
CREATE INDEX idx_pipeline_close_date ON sales.pipeline(estimated_close_date);
CREATE INDEX idx_pipeline_priority ON sales.pipeline(priority);
CREATE INDEX idx_pipeline_last_activity ON sales.pipeline(last_activity_date);

-- Indexes for sales.interactions (new structure)
CREATE INDEX idx_interactions_organization_id ON sales.interactions(organization_id);
CREATE INDEX idx_interactions_customer_id ON sales.interactions(customer_id);
CREATE INDEX idx_interactions_pipeline_id ON sales.interactions(pipeline_id);
CREATE INDEX idx_interactions_user_id ON sales.interactions(user_id);
CREATE INDEX idx_interactions_date ON sales.interactions(interaction_date);
CREATE INDEX idx_interactions_type ON sales.interactions(interaction_type);

-- =============================================================================
-- 10. ADD COMMENTS FOR CLARITY
-- =============================================================================

COMMENT ON TABLE sales.pipeline IS 'Unified sales pipeline tracking from lead to closed deal, including proposals';
COMMENT ON COLUMN sales.pipeline.stage IS 'Sales stage: LEAD, QUALIFIED, PROPOSAL, NEGOTIATION, CLOSED_WON, CLOSED_LOST';
COMMENT ON COLUMN sales.pipeline.status IS 'Pipeline status: ACTIVE, PAUSED, CANCELLED, COMPLETED';
COMMENT ON TABLE sales.interactions IS 'All sales communications including proposals, tracked per pipeline or customer';
COMMENT ON COLUMN sales.interactions.interaction_type IS 'Type of interaction: call, email, meeting, demo, proposal_sent, proposal_revised, etc.';
COMMENT ON COLUMN sales.interactions.file_url IS 'URL to proposal documents or other attachments';
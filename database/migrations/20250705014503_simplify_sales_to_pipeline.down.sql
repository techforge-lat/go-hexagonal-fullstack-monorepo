-- Rollback Sales Schema Simplification
-- Restore original sales schema structure

-- =============================================================================
-- 1. CREATE OLD sales.opportunities TABLE
-- =============================================================================

CREATE TABLE sales.opportunities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    customer_id UUID REFERENCES customers.customers(id),
    prospect_id UUID REFERENCES customers.prospects(id),
    assigned_sales_rep_id UUID REFERENCES auth.users(id),
    stage VARCHAR(50) NOT NULL,
    probability NUMERIC(5,2) DEFAULT 0 CHECK (probability >= 0 AND probability <= 100),
    estimated_value NUMERIC(12,2) NOT NULL DEFAULT 0,
    actual_value NUMERIC(12,2),
    estimated_close_date DATE,
    actual_close_date DATE,
    lead_source VARCHAR(50),
    priority VARCHAR(20) DEFAULT 'MEDIUM',
    status VARCHAR(20) DEFAULT 'OPEN',
    lost_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    last_activity_date TIMESTAMP,
    next_follow_up_date DATE,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    organization_id UUID REFERENCES auth.organizations(id),
    CONSTRAINT opportunities_customer_or_prospect_check 
        CHECK ((customer_id IS NOT NULL) OR (prospect_id IS NOT NULL))
);

-- =============================================================================
-- 2. CREATE OLD sales.proposals TABLE
-- =============================================================================

CREATE TABLE sales.proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_number VARCHAR(50) UNIQUE NOT NULL,
    opportunity_id UUID REFERENCES sales.opportunities(id),
    customer_id UUID REFERENCES customers.customers(id),
    prospect_id UUID REFERENCES customers.prospects(id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    total_amount NUMERIC(12,4) NOT NULL DEFAULT 0,
    currency_id UUID REFERENCES billing.currencies(id),
    status VARCHAR(50) DEFAULT 'DRAFT',
    valid_until DATE,
    sent_date DATE,
    reviewed_date DATE,
    decision_date DATE,
    rejection_reason TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    parent_proposal_id UUID REFERENCES sales.proposals(id),
    created_by UUID REFERENCES auth.users(id),
    approved_by UUID REFERENCES auth.users(id),
    file_url VARCHAR(500),
    terms_and_conditions TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    organization_id UUID REFERENCES auth.organizations(id),
    CONSTRAINT proposals_customer_or_prospect_check 
        CHECK ((customer_id IS NOT NULL) OR (prospect_id IS NOT NULL))
);

-- =============================================================================
-- 3. CREATE OLD sales.opportunity_products TABLE
-- =============================================================================

CREATE TABLE sales.opportunity_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    opportunity_id UUID NOT NULL REFERENCES sales.opportunities(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products.products(id),
    quantity INTEGER DEFAULT 1 NOT NULL,
    unit_price NUMERIC(10,4) NOT NULL,
    total_price NUMERIC(12,4) NOT NULL,
    discount_percentage NUMERIC(5,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    organization_id UUID REFERENCES auth.organizations(id),
    customer_id UUID REFERENCES customers.customers(id)
);

-- =============================================================================
-- 4. CREATE OLD sales.proposal_items TABLE
-- =============================================================================

CREATE TABLE sales.proposal_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id UUID NOT NULL REFERENCES sales.proposals(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products.products(id),
    description VARCHAR(300) NOT NULL,
    quantity INTEGER DEFAULT 1 NOT NULL,
    unit_price NUMERIC(10,4) NOT NULL,
    total_price NUMERIC(12,4) NOT NULL,
    discount_percentage NUMERIC(5,2) DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    organization_id UUID REFERENCES auth.organizations(id),
    customer_id UUID REFERENCES customers.customers(id)
);

-- =============================================================================
-- 5. CREATE OLD sales.interactions TABLE (ORIGINAL STRUCTURE)
-- =============================================================================

CREATE TABLE sales.interactions_old (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers.customers(id),
    prospect_id UUID REFERENCES customers.prospects(id),
    opportunity_id UUID REFERENCES sales.opportunities(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    interaction_type VARCHAR(50) NOT NULL,
    subject VARCHAR(200),
    summary TEXT,
    interaction_date TIMESTAMP DEFAULT NOW() NOT NULL,
    duration_minutes INTEGER,
    outcome VARCHAR(50),
    next_action VARCHAR(200),
    next_action_date DATE,
    channel VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    organization_id UUID REFERENCES auth.organizations(id),
    CONSTRAINT interactions_contact_check 
        CHECK ((customer_id IS NOT NULL) OR (prospect_id IS NOT NULL))
);

-- =============================================================================
-- 6. MIGRATE DATA BACK FROM PIPELINE TO OPPORTUNITIES
-- =============================================================================

-- Migrate pipeline entries that originated from opportunities (start with PIPE-)
INSERT INTO sales.opportunities (
    id, name, description, customer_id, assigned_sales_rep_id,
    stage, probability, estimated_value, actual_value,
    estimated_close_date, actual_close_date, lead_source,
    priority, status, notes, created_at, updated_at,
    last_activity_date, next_follow_up_date, created_by, updated_by,
    organization_id
)
SELECT 
    p.id,
    p.name,
    p.description,
    p.customer_id,
    p.assigned_sales_rep_id,
    p.stage,
    p.probability,
    p.estimated_value,
    p.actual_value,
    p.estimated_close_date,
    p.actual_close_date,
    p.lead_source,
    p.priority,
    p.status,
    p.notes,
    p.created_at,
    p.updated_at,
    p.last_activity_date,
    p.next_follow_up_date,
    p.created_by,
    p.updated_by,
    p.organization_id
FROM sales.pipeline p
WHERE p.pipeline_number LIKE 'PIPE-%';

-- =============================================================================
-- 7. MIGRATE DATA BACK FROM PIPELINE TO PROPOSALS
-- =============================================================================

-- Migrate pipeline entries that originated from proposals (start with PROP-)
INSERT INTO sales.proposals (
    proposal_number, title, description, customer_id,
    total_amount, status, notes, created_at, updated_at,
    created_by, organization_id
)
SELECT 
    p.pipeline_number,
    p.name,
    p.description,
    p.customer_id,
    p.estimated_value,
    CASE 
        WHEN p.status = 'ACTIVE' AND p.stage = 'PROPOSAL' THEN 'SENT'
        WHEN p.status = 'COMPLETED' THEN 'APPROVED'
        WHEN p.status = 'CANCELLED' THEN 'REJECTED'
        ELSE 'DRAFT'
    END,
    p.notes,
    p.created_at,
    p.updated_at,
    p.created_by,
    p.organization_id
FROM sales.pipeline p
WHERE p.pipeline_number LIKE 'PROP-%';

-- =============================================================================
-- 8. MIGRATE INTERACTIONS BACK
-- =============================================================================

-- Migrate interactions data back to old structure
INSERT INTO sales.interactions_old (
    id, customer_id, opportunity_id, user_id,
    interaction_type, subject, summary, interaction_date,
    duration_minutes, outcome, next_action, next_action_date,
    channel, created_at, updated_at, organization_id
)
SELECT 
    i.id,
    i.customer_id,
    i.pipeline_id, -- This becomes opportunity_id for PIPE- entries
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
    i.updated_at,
    i.organization_id
FROM sales.interactions i;

-- =============================================================================
-- 9. DROP NEW TABLES
-- =============================================================================

DROP TABLE sales.interactions CASCADE;
DROP TABLE sales.pipeline CASCADE;

-- =============================================================================
-- 10. RENAME OLD INTERACTIONS TABLE
-- =============================================================================

ALTER TABLE sales.interactions_old RENAME TO interactions;

-- =============================================================================
-- 11. RECREATE OLD INDEXES
-- =============================================================================

-- Opportunities indexes
CREATE INDEX idx_opportunities_assigned_sales_rep ON sales.opportunities(assigned_sales_rep_id);
CREATE INDEX idx_opportunities_close_date ON sales.opportunities(estimated_close_date);
CREATE INDEX idx_opportunities_customer ON sales.opportunities(customer_id);
CREATE INDEX idx_opportunities_organization_id ON sales.opportunities(organization_id);
CREATE INDEX idx_opportunities_prospect ON sales.opportunities(prospect_id);
CREATE INDEX idx_opportunities_stage ON sales.opportunities(stage);
CREATE INDEX idx_opportunities_status ON sales.opportunities(status);

-- Proposals indexes
CREATE INDEX idx_proposals_number ON sales.proposals(proposal_number);
CREATE INDEX idx_proposals_opportunity ON sales.proposals(opportunity_id);
CREATE INDEX idx_proposals_organization_id ON sales.proposals(organization_id);
CREATE INDEX idx_proposals_status ON sales.proposals(status);
CREATE INDEX idx_proposals_valid_until ON sales.proposals(valid_until);

-- Opportunity products indexes
CREATE INDEX idx_opportunity_products_opportunity_id ON sales.opportunity_products(opportunity_id);
CREATE INDEX idx_opportunity_products_organization_id ON sales.opportunity_products(organization_id);
CREATE INDEX idx_opportunity_products_customer_id ON sales.opportunity_products(customer_id);

-- Proposal items indexes
CREATE INDEX idx_proposal_items_proposal_id ON sales.proposal_items(proposal_id);
CREATE INDEX idx_proposal_items_organization_id ON sales.proposal_items(organization_id);
CREATE INDEX idx_proposal_items_customer_id ON sales.proposal_items(customer_id);

-- Interactions indexes
CREATE INDEX idx_interactions_customer ON sales.interactions(customer_id);
CREATE INDEX idx_interactions_date ON sales.interactions(interaction_date);
CREATE INDEX idx_interactions_organization_id ON sales.interactions(organization_id);
CREATE INDEX idx_interactions_prospect ON sales.interactions(prospect_id);
CREATE INDEX idx_interactions_type ON sales.interactions(interaction_type);

-- =============================================================================
-- 12. REMOVE COMMENTS
-- =============================================================================

COMMENT ON TABLE sales.opportunities IS NULL;
COMMENT ON TABLE sales.proposals IS NULL;
COMMENT ON TABLE sales.interactions IS NULL;
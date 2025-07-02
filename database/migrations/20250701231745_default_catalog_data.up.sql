-- Default Catalog Configuration Data
-- This migration populates the catalog system with default configuration values

-- =============================================================================
-- 1. INSERT CATALOG TYPES
-- =============================================================================

INSERT INTO config.catalog_types (id, name, code, description, is_active) VALUES
-- Lead and Customer Management
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Fuentes de Leads', 'lead_sources', 'Fuentes de donde se originan los leads', true),
('b2c3d4e5-f6g7-8901-bcde-f12345678901', 'Tamaños de Empresa', 'company_sizes', 'Categorías de tamaño de empresa', true),
('c3d4e5f6-g7h8-9012-cdef-123456789012', 'Industrias', 'industries', 'Clasificaciones de industrias', true),
('d4e5f6g7-h8i9-0123-defa-234567890123', 'Estados de Prospectos', 'prospect_statuses', 'Opciones de estado para prospectos', true),

-- Sales Pipeline
('e5f6g7h8-i9j0-1234-efab-345678901234', 'Etapas de Oportunidad', 'opportunity_stages', 'Etapas del pipeline de oportunidades de venta', true),
('f6g7h8i9-j0k1-2345-fabc-456789012345', 'Estados de Propuesta', 'proposal_statuses', 'Opciones de estado para propuestas', true),
('g7h8i9j0-k1l2-3456-abcd-567890123456', 'Tipos de Interacción', 'interaction_types', 'Tipos de interacciones con clientes', true),
('h8i9j0k1-l2m3-4567-bcde-678901234567', 'Canales de Comunicación', 'communication_channels', 'Métodos de comunicación', true),

-- General Classifications
('i9j0k1l2-m3n4-5678-cdef-789012345678', 'Prioridades', 'priorities', 'Niveles de prioridad', true),
('j0k1l2m3-n4o5-6789-defa-890123456789', 'Tipos de Documento', 'document_types', 'Tipos de documentos', true),
('k1l2m3n4-o5p6-7890-efab-901234567890', 'Estados de Documento', 'document_statuses', 'Opciones de estado de documentos', true),
('l2m3n4o5-p6q7-8901-fabc-012345678901', 'Métodos de Firma', 'signature_methods', 'Métodos de firma de documentos', true),

-- Support and Services
('m3n4o5p6-q7r8-9012-abcd-123456789012', 'Tipos de Soporte', 'support_types', 'Tipos de servicios de soporte', true),
('n4o5p6q7-r8s9-0123-bcde-234567890123', 'Prioridades de Ticket', 'ticket_priorities', 'Niveles de prioridad de tickets de soporte', true),
('o5p6q7r8-s9t0-1234-cdef-345678901234', 'Severidades de Ticket', 'ticket_severities', 'Niveles de severidad de tickets de soporte', true),
('p6q7r8s9-t0u1-2345-defa-456789012345', 'Estados de Ticket', 'ticket_statuses', 'Opciones de estado de tickets de soporte', true),
('q7r8s9t0-u1v2-3456-efab-567890123456', 'Categorías de Ticket', 'ticket_categories', 'Categorías de tickets de soporte', true),

-- Renewal and Alerts
('r8s9t0u1-v2w3-4567-fabc-678901234567', 'Tipos de Alerta', 'alert_types', 'Tipos de alertas y notificaciones', true),
('s9t0u1v2-w3x4-5678-abcd-789012345678', 'Estados de Alerta', 'alert_statuses', 'Opciones de estado para alertas', true),
('t0u1v2w3-x4y5-6789-bcde-890123456789', 'Frecuencias de Facturación', 'billing_frequencies', 'Opciones de frecuencia para facturación', true);

-- =============================================================================
-- 2. INSERT CATALOG OPTIONS
-- =============================================================================

-- Fuentes de Leads
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Sitio Web', 'website', 'WEBSITE', '#3B82F6', 1, true),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Referencia', 'referral', 'REFERRAL', '#10B981', 2, true),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Llamada en Frío', 'cold_call', 'COLD_CALL', '#F59E0B', 3, true),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Redes Sociales', 'social_media', 'SOCIAL_MEDIA', '#8B5CF6', 4, true),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Feria Comercial', 'trade_show', 'TRADE_SHOW', '#EF4444', 5, true),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Socio', 'partner', 'PARTNER', '#06B6D4', 6, true),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Publicidad', 'advertisement', 'ADVERTISEMENT', '#84CC16', 7, true);

-- Tamaños de Empresa
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('b2c3d4e5-f6g7-8901-bcde-f12345678901', 'Startup (1-10)', 'startup', 'STARTUP', '#10B981', 1, true),
('b2c3d4e5-f6g7-8901-bcde-f12345678901', 'Pequeña (11-50)', 'small', 'SMALL', '#3B82F6', 2, true),
('b2c3d4e5-f6g7-8901-bcde-f12345678901', 'Mediana (51-200)', 'medium', 'MEDIUM', '#F59E0B', 3, true),
('b2c3d4e5-f6g7-8901-bcde-f12345678901', 'Grande (201-1000)', 'large', 'LARGE', '#8B5CF6', 4, true),
('b2c3d4e5-f6g7-8901-bcde-f12345678901', 'Empresa (1000+)', 'enterprise', 'ENTERPRISE', '#EF4444', 5, true);

-- Industrias
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('c3d4e5f6-g7h8-9012-cdef-123456789012', 'Tecnología', 'technology', 'TECHNOLOGY', '#3B82F6', 1, true),
('c3d4e5f6-g7h8-9012-cdef-123456789012', 'Salud', 'healthcare', 'HEALTHCARE', '#EF4444', 2, true),
('c3d4e5f6-g7h8-9012-cdef-123456789012', 'Finanzas', 'finance', 'FINANCE', '#10B981', 3, true),
('c3d4e5f6-g7h8-9012-cdef-123456789012', 'Educación', 'education', 'EDUCATION', '#F59E0B', 4, true),
('c3d4e5f6-g7h8-9012-cdef-123456789012', 'Manufactura', 'manufacturing', 'MANUFACTURING', '#8B5CF6', 5, true),
('c3d4e5f6-g7h8-9012-cdef-123456789012', 'Comercio', 'retail', 'RETAIL', '#06B6D4', 6, true),
('c3d4e5f6-g7h8-9012-cdef-123456789012', 'Gobierno', 'government', 'GOVERNMENT', '#84CC16', 7, true),
('c3d4e5f6-g7h8-9012-cdef-123456789012', 'Sin Fines de Lucro', 'non_profit', 'NON_PROFIT', '#F97316', 8, true);

-- Estados de Prospectos
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('d4e5f6g7-h8i9-0123-defa-234567890123', 'Nuevo Lead', 'new_lead', 'NEW_LEAD', '#6B7280', 1, true),
('d4e5f6g7-h8i9-0123-defa-234567890123', 'Contactado', 'contacted', 'CONTACTED', '#3B82F6', 2, true),
('d4e5f6g7-h8i9-0123-defa-234567890123', 'Calificado', 'qualified', 'QUALIFIED', '#10B981', 3, true),
('d4e5f6g7-h8i9-0123-defa-234567890123', 'Propuesta Enviada', 'proposal_sent', 'PROPOSAL_SENT', '#F59E0B', 4, true),
('d4e5f6g7-h8i9-0123-defa-234567890123', 'Negociación', 'negotiation', 'NEGOTIATION', '#8B5CF6', 5, true),
('d4e5f6g7-h8i9-0123-defa-234567890123', 'Convertido', 'converted', 'CONVERTED', '#10B981', 6, true),
('d4e5f6g7-h8i9-0123-defa-234567890123', 'Perdido', 'lost', 'LOST', '#EF4444', 7, true),
('d4e5f6g7-h8i9-0123-defa-234567890123', 'En Pausa', 'on_hold', 'ON_HOLD', '#F59E0B', 8, true);

-- Etapas de Oportunidad
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('e5f6g7h8-i9j0-1234-efab-345678901234', 'Prospección', 'prospecting', 'PROSPECTING', '#6B7280', 1, true),
('e5f6g7h8-i9j0-1234-efab-345678901234', 'Calificación', 'qualification', 'QUALIFICATION', '#3B82F6', 2, true),
('e5f6g7h8-i9j0-1234-efab-345678901234', 'Análisis de Necesidades', 'needs_analysis', 'NEEDS_ANALYSIS', '#06B6D4', 3, true),
('e5f6g7h8-i9j0-1234-efab-345678901234', 'Propuesta', 'proposal', 'PROPOSAL', '#F59E0B', 4, true),
('e5f6g7h8-i9j0-1234-efab-345678901234', 'Negociación', 'negotiation', 'NEGOTIATION', '#8B5CF6', 5, true),
('e5f6g7h8-i9j0-1234-efab-345678901234', 'Cierre', 'closing', 'CLOSING', '#84CC16', 6, true),
('e5f6g7h8-i9j0-1234-efab-345678901234', 'Ganado', 'won', 'WON', '#10B981', 7, true),
('e5f6g7h8-i9j0-1234-efab-345678901234', 'Perdido', 'lost', 'LOST', '#EF4444', 8, true);

-- Estados de Propuesta
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('f6g7h8i9-j0k1-2345-fabc-456789012345', 'Borrador', 'draft', 'DRAFT', '#6B7280', 1, true),
('f6g7h8i9-j0k1-2345-fabc-456789012345', 'Enviado', 'sent', 'SENT', '#3B82F6', 2, true),
('f6g7h8i9-j0k1-2345-fabc-456789012345', 'Revisado', 'reviewed', 'REVIEWED', '#F59E0B', 3, true),
('f6g7h8i9-j0k1-2345-fabc-456789012345', 'Aprobado', 'approved', 'APPROVED', '#10B981', 4, true),
('f6g7h8i9-j0k1-2345-fabc-456789012345', 'Rechazado', 'rejected', 'REJECTED', '#EF4444', 5, true),
('f6g7h8i9-j0k1-2345-fabc-456789012345', 'Expirado', 'expired', 'EXPIRED', '#9CA3AF', 6, true),
('f6g7h8i9-j0k1-2345-fabc-456789012345', 'Firmado', 'signed', 'SIGNED', '#059669', 7, true);

-- Tipos de Interacción
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('g7h8i9j0-k1l2-3456-abcd-567890123456', 'Llamada Telefónica', 'phone_call', 'PHONE_CALL', '#3B82F6', 1, true),
('g7h8i9j0-k1l2-3456-abcd-567890123456', 'Correo Electrónico', 'email', 'EMAIL', '#10B981', 2, true),
('g7h8i9j0-k1l2-3456-abcd-567890123456', 'Reunión', 'meeting', 'MEETING', '#F59E0B', 3, true),
('g7h8i9j0-k1l2-3456-abcd-567890123456', 'Videollamada', 'video_call', 'VIDEO_CALL', '#8B5CF6', 4, true),
('g7h8i9j0-k1l2-3456-abcd-567890123456', 'Demostración', 'demo', 'DEMO', '#06B6D4', 5, true),
('g7h8i9j0-k1l2-3456-abcd-567890123456', 'Presentación', 'presentation', 'PRESENTATION', '#84CC16', 6, true),
('g7h8i9j0-k1l2-3456-abcd-567890123456', 'Seguimiento', 'follow_up', 'FOLLOW_UP', '#F97316', 7, true),
('g7h8i9j0-k1l2-3456-abcd-567890123456', 'Soporte', 'support', 'SUPPORT', '#EF4444', 8, true);

-- Canales de Comunicación
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('h8i9j0k1-l2m3-4567-bcde-678901234567', 'Teléfono', 'phone', 'PHONE', '#3B82F6', 1, true),
('h8i9j0k1-l2m3-4567-bcde-678901234567', 'Correo Electrónico', 'email', 'EMAIL', '#10B981', 2, true),
('h8i9j0k1-l2m3-4567-bcde-678901234567', 'En Persona', 'in_person', 'IN_PERSON', '#F59E0B', 3, true),
('h8i9j0k1-l2m3-4567-bcde-678901234567', 'Videoconferencia', 'video_conference', 'VIDEO_CONFERENCE', '#8B5CF6', 4, true),
('h8i9j0k1-l2m3-4567-bcde-678901234567', 'Chat', 'chat', 'CHAT', '#06B6D4', 5, true),
('h8i9j0k1-l2m3-4567-bcde-678901234567', 'Redes Sociales', 'social_media', 'SOCIAL_MEDIA', '#84CC16', 6, true),
('h8i9j0k1-l2m3-4567-bcde-678901234567', 'WhatsApp', 'whatsapp', 'WHATSAPP', '#059669', 7, true);

-- Prioridades
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('i9j0k1l2-m3n4-5678-cdef-789012345678', 'Baja', 'low', 'LOW', '#10B981', 1, true),
('i9j0k1l2-m3n4-5678-cdef-789012345678', 'Media', 'medium', 'MEDIUM', '#F59E0B', 2, true),
('i9j0k1l2-m3n4-5678-cdef-789012345678', 'Alta', 'high', 'HIGH', '#EF4444', 3, true),
('i9j0k1l2-m3n4-5678-cdef-789012345678', 'Crítica', 'critical', 'CRITICAL', '#DC2626', 4, true);

-- Tipos de Documento
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('j0k1l2m3-n4o5-6789-defa-890123456789', 'Contrato', 'contract', 'CONTRACT', '#3B82F6', 1, true),
('j0k1l2m3-n4o5-6789-defa-890123456789', 'Propuesta', 'proposal', 'PROPOSAL', '#10B981', 2, true),
('j0k1l2m3-n4o5-6789-defa-890123456789', 'Acuerdo de Confidencialidad', 'nda', 'NDA', '#F59E0B', 3, true),
('j0k1l2m3-n4o5-6789-defa-890123456789', 'Enmienda', 'amendment', 'AMENDMENT', '#8B5CF6', 4, true),
('j0k1l2m3-n4o5-6789-defa-890123456789', 'Factura', 'invoice', 'INVOICE', '#06B6D4', 5, true),
('j0k1l2m3-n4o5-6789-defa-890123456789', 'Certificado', 'certificate', 'CERTIFICATE', '#84CC16', 6, true),
('j0k1l2m3-n4o5-6789-defa-890123456789', 'Orden de Compra', 'purchase_order', 'PURCHASE_ORDER', '#F97316', 7, true),
('j0k1l2m3-n4o5-6789-defa-890123456789', 'Acuerdo', 'agreement', 'AGREEMENT', '#EF4444', 8, true);

-- Estados de Documento
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('k1l2m3n4-o5p6-7890-efab-901234567890', 'Borrador', 'draft', 'DRAFT', '#6B7280', 1, true),
('k1l2m3n4-o5p6-7890-efab-901234567890', 'Pendiente de Revisión', 'pending_review', 'PENDING_REVIEW', '#F59E0B', 2, true),
('k1l2m3n4-o5p6-7890-efab-901234567890', 'Aprobado', 'approved', 'APPROVED', '#10B981', 3, true),
('k1l2m3n4-o5p6-7890-efab-901234567890', 'Firmado', 'signed', 'SIGNED', '#059669', 4, true),
('k1l2m3n4-o5p6-7890-efab-901234567890', 'Rechazado', 'rejected', 'REJECTED', '#EF4444', 5, true),
('k1l2m3n4-o5p6-7890-efab-901234567890', 'Expirado', 'expired', 'EXPIRED', '#9CA3AF', 6, true),
('k1l2m3n4-o5p6-7890-efab-901234567890', 'Cancelado', 'cancelled', 'CANCELLED', '#6B7280', 7, true);

-- Métodos de Firma
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('l2m3n4o5-p6q7-8901-fabc-012345678901', 'Firma Digital', 'digital', 'DIGITAL', '#3B82F6', 1, true),
('l2m3n4o5-p6q7-8901-fabc-012345678901', 'Firma Electrónica', 'electronic', 'ELECTRONIC', '#10B981', 2, true),
('l2m3n4o5-p6q7-8901-fabc-012345678901', 'Firma Física', 'physical', 'PHYSICAL', '#F59E0B', 3, true),
('l2m3n4o5-p6q7-8901-fabc-012345678901', 'DocuSign', 'docusign', 'DOCUSIGN', '#8B5CF6', 4, true),
('l2m3n4o5-p6q7-8901-fabc-012345678901', 'Adobe Sign', 'adobe_sign', 'ADOBE_SIGN', '#EF4444', 5, true);

-- Tipos de Soporte
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('m3n4o5p6-q7r8-9012-abcd-123456789012', 'Soporte Básico', 'basic', 'BASIC', '#10B981', 1, true),
('m3n4o5p6-q7r8-9012-abcd-123456789012', 'Soporte Premium', 'premium', 'PREMIUM', '#F59E0B', 2, true),
('m3n4o5p6-q7r8-9012-abcd-123456789012', 'Soporte Empresarial', 'enterprise', 'ENTERPRISE', '#EF4444', 3, true),
('m3n4o5p6-q7r8-9012-abcd-123456789012', 'Soporte 24/7', 'support_24_7', 'SUPPORT_24_7', '#8B5CF6', 4, true);

-- Prioridades de Ticket
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('n4o5p6q7-r8s9-0123-bcde-234567890123', 'Baja', 'low', 'LOW', '#10B981', 1, true),
('n4o5p6q7-r8s9-0123-bcde-234567890123', 'Media', 'medium', 'MEDIUM', '#F59E0B', 2, true),
('n4o5p6q7-r8s9-0123-bcde-234567890123', 'Alta', 'high', 'HIGH', '#EF4444', 3, true),
('n4o5p6q7-r8s9-0123-bcde-234567890123', 'Urgente', 'urgent', 'URGENT', '#DC2626', 4, true);

-- Severidades de Ticket
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('o5p6q7r8-s9t0-1234-cdef-345678901234', 'Baja', 'low', 'LOW', '#10B981', 1, true),
('o5p6q7r8-s9t0-1234-cdef-345678901234', 'Media', 'medium', 'MEDIUM', '#F59E0B', 2, true),
('o5p6q7r8-s9t0-1234-cdef-345678901234', 'Alta', 'high', 'HIGH', '#EF4444', 3, true),
('o5p6q7r8-s9t0-1234-cdef-345678901234', 'Crítica', 'critical', 'CRITICAL', '#DC2626', 4, true);

-- Estados de Ticket
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('p6q7r8s9-t0u1-2345-defa-456789012345', 'Abierto', 'open', 'OPEN', '#3B82F6', 1, true),
('p6q7r8s9-t0u1-2345-defa-456789012345', 'En Progreso', 'in_progress', 'IN_PROGRESS', '#F59E0B', 2, true),
('p6q7r8s9-t0u1-2345-defa-456789012345', 'Esperando al Cliente', 'waiting_customer', 'WAITING_CUSTOMER', '#8B5CF6', 3, true),
('p6q7r8s9-t0u1-2345-defa-456789012345', 'Resuelto', 'resolved', 'RESOLVED', '#10B981', 4, true),
('p6q7r8s9-t0u1-2345-defa-456789012345', 'Cerrado', 'closed', 'CLOSED', '#6B7280', 5, true),
('p6q7r8s9-t0u1-2345-defa-456789012345', 'Cancelado', 'cancelled', 'CANCELLED', '#EF4444', 6, true);

-- Categorías de Ticket
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('q7r8s9t0-u1v2-3456-efab-567890123456', 'Problema Técnico', 'technical_issue', 'TECHNICAL_ISSUE', '#EF4444', 1, true),
('q7r8s9t0-u1v2-3456-efab-567890123456', 'Reporte de Error', 'bug_report', 'BUG_REPORT', '#DC2626', 2, true),
('q7r8s9t0-u1v2-3456-efab-567890123456', 'Solicitud de Función', 'feature_request', 'FEATURE_REQUEST', '#10B981', 3, true),
('q7r8s9t0-u1v2-3456-efab-567890123456', 'Pregunta General', 'general_question', 'GENERAL_QUESTION', '#3B82F6', 4, true),
('q7r8s9t0-u1v2-3456-efab-567890123456', 'Problema de Cuenta', 'account_issue', 'ACCOUNT_ISSUE', '#F59E0B', 5, true),
('q7r8s9t0-u1v2-3456-efab-567890123456', 'Consulta de Facturación', 'billing_question', 'BILLING_QUESTION', '#8B5CF6', 6, true),
('q7r8s9t0-u1v2-3456-efab-567890123456', 'Solicitud de Capacitación', 'training_request', 'TRAINING_REQUEST', '#06B6D4', 7, true);

-- Tipos de Alerta
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('r8s9t0u1-v2w3-4567-fabc-678901234567', 'Alerta por Correo', 'email', 'EMAIL', '#3B82F6', 1, true),
('r8s9t0u1-v2w3-4567-fabc-678901234567', 'Alerta por SMS', 'sms', 'SMS', '#10B981', 2, true),
('r8s9t0u1-v2w3-4567-fabc-678901234567', 'Notificación Push', 'push', 'PUSH', '#F59E0B', 3, true),
('r8s9t0u1-v2w3-4567-fabc-678901234567', 'Alerta en Panel', 'dashboard', 'DASHBOARD', '#8B5CF6', 4, true),
('r8s9t0u1-v2w3-4567-fabc-678901234567', 'Notificación Slack', 'slack', 'SLACK', '#06B6D4', 5, true);

-- Estados de Alerta
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('s9t0u1v2-w3x4-5678-abcd-789012345678', 'Pendiente', 'pending', 'PENDING', '#F59E0B', 1, true),
('s9t0u1v2-w3x4-5678-abcd-789012345678', 'Enviado', 'sent', 'SENT', '#3B82F6', 2, true),
('s9t0u1v2-w3x4-5678-abcd-789012345678', 'Reconocido', 'acknowledged', 'ACKNOWLEDGED', '#10B981', 3, true),
('s9t0u1v2-w3x4-5678-abcd-789012345678', 'Completado', 'completed', 'COMPLETED', '#059669', 4, true),
('s9t0u1v2-w3x4-5678-abcd-789012345678', 'Cancelado', 'cancelled', 'CANCELLED', '#EF4444', 5, true),
('s9t0u1v2-w3x4-5678-abcd-789012345678', 'Falló', 'failed', 'FAILED', '#DC2626', 6, true);

-- Frecuencias de Facturación
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
('t0u1v2w3-x4y5-6789-bcde-890123456789', 'Mensual', 'monthly', 'MONTHLY', '#3B82F6', 1, true),
('t0u1v2w3-x4y5-6789-bcde-890123456789', 'Trimestral', 'quarterly', 'QUARTERLY', '#10B981', 2, true),
('t0u1v2w3-x4y5-6789-bcde-890123456789', 'Semestral', 'semi_annually', 'SEMI_ANNUALLY', '#F59E0B', 3, true),
('t0u1v2w3-x4y5-6789-bcde-890123456789', 'Anual', 'annually', 'ANNUALLY', '#8B5CF6', 4, true),
('t0u1v2w3-x4y5-6789-bcde-890123456789', 'Una Sola Vez', 'one_time', 'ONE_TIME', '#EF4444', 5, true);

-- =============================================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- =============================================================================

CREATE INDEX idx_catalog_options_catalog_type ON config.catalog_options(catalog_type_id);
CREATE INDEX idx_catalog_options_code ON config.catalog_options(code);
CREATE INDEX idx_catalog_options_active ON config.catalog_options(is_active);
CREATE INDEX idx_catalog_options_sort_order ON config.catalog_options(sort_order);

CREATE INDEX idx_catalog_types_code ON config.catalog_types(code);
CREATE INDEX idx_catalog_types_active ON config.catalog_types(is_active);

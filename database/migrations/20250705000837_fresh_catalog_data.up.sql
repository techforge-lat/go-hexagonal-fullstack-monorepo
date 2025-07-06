-- Fresh Catalog Configuration Data with Spanish translations
-- This migration populates the catalog system with default configuration values

-- =============================================================================
-- 1. INSERT CATALOG TYPES
-- =============================================================================

INSERT INTO config.catalog_types (name, code, description, is_active) VALUES
-- Lead and Customer Management
('Fuentes de Leads', 'lead_sources', 'Fuentes de donde se originan los leads', true),
('Tamanos de Empresa', 'company_sizes', 'Categorias de tamano de empresa', true),
('Industrias', 'industries', 'Clasificaciones de industrias', true),
('Estados de Prospectos', 'prospect_statuses', 'Opciones de estado para prospectos', true),
('Estados de Cliente', 'customer_statuses', 'Opciones de estado para clientes', true),

-- Sales Pipeline
('Etapas de Oportunidad', 'opportunity_stages', 'Etapas del pipeline de oportunidades de venta', true),
('Estados de Propuesta', 'proposal_statuses', 'Opciones de estado para propuestas', true),
('Tipos de Interaccion', 'interaction_types', 'Tipos de interacciones con clientes', true),
('Canales de Comunicacion', 'communication_channels', 'Metodos de comunicacion', true),
('Resultados de Interaccion', 'interaction_outcomes', 'Resultados de las interacciones', true),

-- Products and Contracts
('Tipos de Producto', 'product_types', 'Tipos de productos y servicios', true),
('Categorias de Producto', 'product_categories', 'Categorias de productos', true),
('Tipos de Contrato', 'contract_types', 'Tipos de contratos', true),
('Estados de Contrato', 'contract_statuses', 'Estados de contratos', true),
('Terminos de Pago', 'payment_terms', 'Terminos y condiciones de pago', true),

-- Billing and Invoicing
('Estados de Factura', 'invoice_statuses', 'Estados de facturas', true),
('Estados de Pago', 'payment_statuses', 'Estados de pagos', true),
('Frecuencias de Facturacion', 'billing_frequencies', 'Opciones de frecuencia para facturacion', true),
('Tipos de Pago', 'payment_types', 'Tipos de pagos y transacciones', true),

-- General Classifications
('Prioridades', 'priorities', 'Niveles de prioridad', true),
('Tipos de Documento', 'document_types', 'Tipos de documentos', true),
('Estados de Documento', 'document_statuses', 'Opciones de estado de documentos', true),
('Metodos de Firma', 'signature_methods', 'Metodos de firma de documentos', true),

-- Support and Services
('Tipos de Soporte', 'support_types', 'Tipos de servicios de soporte', true),
('Prioridades de Ticket', 'ticket_priorities', 'Niveles de prioridad de tickets de soporte', true),
('Severidades de Ticket', 'ticket_severities', 'Niveles de severidad de tickets de soporte', true),
('Estados de Ticket', 'ticket_statuses', 'Opciones de estado de tickets de soporte', true),
('Categorias de Ticket', 'ticket_categories', 'Categorias de tickets de soporte', true),

-- Renewal and Alerts
('Tipos de Alerta', 'alert_types', 'Tipos de alertas y notificaciones', true),
('Estados de Alerta', 'alert_statuses', 'Opciones de estado para alertas', true);

-- =============================================================================
-- 2. INSERT CATALOG OPTIONS
-- =============================================================================

-- Fuentes de Leads
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'lead_sources'), 'Sitio Web', 'website', 'WEBSITE', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'lead_sources'), 'Referencia', 'referral', 'REFERRAL', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'lead_sources'), 'Llamada en Frio', 'cold_call', 'COLD_CALL', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'lead_sources'), 'Redes Sociales', 'social_media', 'SOCIAL_MEDIA', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'lead_sources'), 'Feria Comercial', 'trade_show', 'TRADE_SHOW', '#EF4444', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'lead_sources'), 'Socio', 'partner', 'PARTNER', '#06B6D4', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'lead_sources'), 'Publicidad', 'advertisement', 'ADVERTISEMENT', '#84CC16', 7, true);

-- Tamanos de Empresa
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'company_sizes'), 'Startup (1-10)', 'startup', 'STARTUP', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'company_sizes'), 'Pequena (11-50)', 'small', 'SMALL', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'company_sizes'), 'Mediana (51-200)', 'medium', 'MEDIUM', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'company_sizes'), 'Grande (201-1000)', 'large', 'LARGE', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'company_sizes'), 'Empresa (1000+)', 'enterprise', 'ENTERPRISE', '#EF4444', 5, true);

-- Industrias
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'industries'), 'Tecnologia', 'technology', 'TECHNOLOGY', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'industries'), 'Salud', 'healthcare', 'HEALTHCARE', '#EF4444', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'industries'), 'Finanzas', 'finance', 'FINANCE', '#10B981', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'industries'), 'Educacion', 'education', 'EDUCATION', '#F59E0B', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'industries'), 'Manufactura', 'manufacturing', 'MANUFACTURING', '#8B5CF6', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'industries'), 'Comercio', 'retail', 'RETAIL', '#06B6D4', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'industries'), 'Gobierno', 'government', 'GOVERNMENT', '#84CC16', 7, true),
((SELECT id FROM config.catalog_types WHERE code = 'industries'), 'Sin Fines de Lucro', 'non_profit', 'NON_PROFIT', '#F97316', 8, true);

-- Estados de Prospectos
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'prospect_statuses'), 'Nuevo Lead', 'new_lead', 'NEW_LEAD', '#6B7280', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'prospect_statuses'), 'Contactado', 'contacted', 'CONTACTED', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'prospect_statuses'), 'Calificado', 'qualified', 'QUALIFIED', '#10B981', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'prospect_statuses'), 'Propuesta Enviada', 'proposal_sent', 'PROPOSAL_SENT', '#F59E0B', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'prospect_statuses'), 'Negociacion', 'negotiation', 'NEGOTIATION', '#8B5CF6', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'prospect_statuses'), 'Convertido', 'converted', 'CONVERTED', '#10B981', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'prospect_statuses'), 'Perdido', 'lost', 'LOST', '#EF4444', 7, true),
((SELECT id FROM config.catalog_types WHERE code = 'prospect_statuses'), 'En Pausa', 'on_hold', 'ON_HOLD', '#F59E0B', 8, true);

-- Estados de Cliente
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'customer_statuses'), 'Activo', 'active', 'ACTIVE', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'customer_statuses'), 'Inactivo', 'inactive', 'INACTIVE', '#6B7280', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'customer_statuses'), 'Suspendido', 'suspended', 'SUSPENDED', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'customer_statuses'), 'Bloqueado', 'blocked', 'BLOCKED', '#EF4444', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'customer_statuses'), 'En Revision', 'under_review', 'UNDER_REVIEW', '#8B5CF6', 5, true);

-- Etapas de Oportunidad
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'opportunity_stages'), 'Prospeccion', 'prospecting', 'PROSPECTING', '#6B7280', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'opportunity_stages'), 'Calificacion', 'qualification', 'QUALIFICATION', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'opportunity_stages'), 'Analisis de Necesidades', 'needs_analysis', 'NEEDS_ANALYSIS', '#06B6D4', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'opportunity_stages'), 'Propuesta', 'proposal', 'PROPOSAL', '#F59E0B', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'opportunity_stages'), 'Negociacion', 'negotiation', 'NEGOTIATION', '#8B5CF6', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'opportunity_stages'), 'Cierre', 'closing', 'CLOSING', '#84CC16', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'opportunity_stages'), 'Ganado', 'won', 'WON', '#10B981', 7, true),
((SELECT id FROM config.catalog_types WHERE code = 'opportunity_stages'), 'Perdido', 'lost', 'LOST', '#EF4444', 8, true);

-- Estados de Propuesta
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'proposal_statuses'), 'Borrador', 'draft', 'DRAFT', '#6B7280', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'proposal_statuses'), 'Enviado', 'sent', 'SENT', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'proposal_statuses'), 'Revisado', 'reviewed', 'REVIEWED', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'proposal_statuses'), 'Aprobado', 'approved', 'APPROVED', '#10B981', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'proposal_statuses'), 'Rechazado', 'rejected', 'REJECTED', '#EF4444', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'proposal_statuses'), 'Expirado', 'expired', 'EXPIRED', '#9CA3AF', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'proposal_statuses'), 'Firmado', 'signed', 'SIGNED', '#059669', 7, true);

-- Tipos de Interaccion
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'interaction_types'), 'Llamada Telefonica', 'phone_call', 'PHONE_CALL', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_types'), 'Correo Electronico', 'email', 'EMAIL', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_types'), 'Reunion', 'meeting', 'MEETING', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_types'), 'Videollamada', 'video_call', 'VIDEO_CALL', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_types'), 'Demostracion', 'demo', 'DEMO', '#06B6D4', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_types'), 'Presentacion', 'presentation', 'PRESENTATION', '#84CC16', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_types'), 'Seguimiento', 'follow_up', 'FOLLOW_UP', '#F97316', 7, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_types'), 'Soporte', 'support', 'SUPPORT', '#EF4444', 8, true);

-- Canales de Comunicacion
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'communication_channels'), 'Telefono', 'phone', 'PHONE', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'communication_channels'), 'Correo Electronico', 'email', 'EMAIL', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'communication_channels'), 'En Persona', 'in_person', 'IN_PERSON', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'communication_channels'), 'Videoconferencia', 'video_conference', 'VIDEO_CONFERENCE', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'communication_channels'), 'Chat', 'chat', 'CHAT', '#06B6D4', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'communication_channels'), 'Redes Sociales', 'social_media', 'SOCIAL_MEDIA', '#84CC16', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'communication_channels'), 'WhatsApp', 'whatsapp', 'WHATSAPP', '#059669', 7, true);

-- Resultados de Interaccion
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'interaction_outcomes'), 'Exitoso', 'successful', 'SUCCESSFUL', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_outcomes'), 'Seguimiento Requerido', 'follow_up_required', 'FOLLOW_UP_REQUIRED', '#F59E0B', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_outcomes'), 'No Interesado', 'not_interested', 'NOT_INTERESTED', '#EF4444', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_outcomes'), 'No Contactado', 'no_contact', 'NO_CONTACT', '#6B7280', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_outcomes'), 'Programar Nueva Reunion', 'reschedule', 'RESCHEDULE', '#8B5CF6', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'interaction_outcomes'), 'Informacion Enviada', 'information_sent', 'INFORMATION_SENT', '#06B6D4', 6, true);

-- Tipos de Producto
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'product_types'), 'Servicio', 'service', 'SERVICE', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'product_types'), 'Producto', 'product', 'PRODUCT', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'product_types'), 'Suscripcion', 'subscription', 'SUBSCRIPTION', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'product_types'), 'Licencia', 'license', 'LICENSE', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'product_types'), 'Consultoria', 'consulting', 'CONSULTING', '#06B6D4', 5, true);

-- Categorias de Producto
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'product_categories'), 'Software', 'software', 'SOFTWARE', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'product_categories'), 'Hardware', 'hardware', 'HARDWARE', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'product_categories'), 'Servicios Profesionales', 'professional_services', 'PROFESSIONAL_SERVICES', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'product_categories'), 'Soporte Tecnico', 'technical_support', 'TECHNICAL_SUPPORT', '#EF4444', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'product_categories'), 'Capacitacion', 'training', 'TRAINING', '#8B5CF6', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'product_categories'), 'Mantenimiento', 'maintenance', 'MAINTENANCE', '#06B6D4', 6, true);

-- Tipos de Contrato
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'contract_types'), 'Contrato de Servicios', 'service_contract', 'SERVICE_CONTRACT', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_types'), 'Contrato de Licencia', 'license_contract', 'LICENSE_CONTRACT', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_types'), 'Contrato de Suscripcion', 'subscription_contract', 'SUBSCRIPTION_CONTRACT', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_types'), 'Contrato de Mantenimiento', 'maintenance_contract', 'MAINTENANCE_CONTRACT', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_types'), 'Contrato Marco', 'framework_contract', 'FRAMEWORK_CONTRACT', '#06B6D4', 5, true);

-- Estados de Contrato
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'contract_statuses'), 'Borrador', 'draft', 'DRAFT', '#6B7280', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_statuses'), 'Pendiente de Aprobacion', 'pending_approval', 'PENDING_APPROVAL', '#F59E0B', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_statuses'), 'Activo', 'active', 'ACTIVE', '#10B981', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_statuses'), 'Suspendido', 'suspended', 'SUSPENDED', '#EF4444', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_statuses'), 'Expirado', 'expired', 'EXPIRED', '#9CA3AF', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_statuses'), 'Terminado', 'terminated', 'TERMINATED', '#6B7280', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'contract_statuses'), 'Renovado', 'renewed', 'RENEWED', '#059669', 7, true);

-- Terminos de Pago
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'payment_terms'), 'Inmediato', 'immediate', 'IMMEDIATE', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_terms'), '15 dias', 'net_15', 'NET_15', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_terms'), '30 dias', 'net_30', 'NET_30', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_terms'), '45 dias', 'net_45', 'NET_45', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_terms'), '60 dias', 'net_60', 'NET_60', '#EF4444', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_terms'), '90 dias', 'net_90', 'NET_90', '#DC2626', 6, true);

-- Estados de Factura
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'invoice_statuses'), 'Borrador', 'draft', 'DRAFT', '#6B7280', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'invoice_statuses'), 'Enviada', 'sent', 'SENT', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'invoice_statuses'), 'Pagada', 'paid', 'PAID', '#10B981', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'invoice_statuses'), 'Vencida', 'overdue', 'OVERDUE', '#EF4444', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'invoice_statuses'), 'Parcialmente Pagada', 'partially_paid', 'PARTIALLY_PAID', '#F59E0B', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'invoice_statuses'), 'Cancelada', 'cancelled', 'CANCELLED', '#9CA3AF', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'invoice_statuses'), 'Anulada', 'voided', 'VOIDED', '#DC2626', 7, true);

-- Estados de Pago
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'payment_statuses'), 'Pendiente', 'pending', 'PENDING', '#F59E0B', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_statuses'), 'Procesando', 'processing', 'PROCESSING', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_statuses'), 'Completado', 'completed', 'COMPLETED', '#10B981', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_statuses'), 'Fallido', 'failed', 'FAILED', '#EF4444', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_statuses'), 'Cancelado', 'cancelled', 'CANCELLED', '#9CA3AF', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_statuses'), 'Reembolsado', 'refunded', 'REFUNDED', '#8B5CF6', 6, true);

-- Frecuencias de Facturacion
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'billing_frequencies'), 'Mensual', 'monthly', 'MONTHLY', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'billing_frequencies'), 'Trimestral', 'quarterly', 'QUARTERLY', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'billing_frequencies'), 'Semestral', 'semi_annually', 'SEMI_ANNUALLY', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'billing_frequencies'), 'Anual', 'annually', 'ANNUALLY', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'billing_frequencies'), 'Una Sola Vez', 'one_time', 'ONE_TIME', '#EF4444', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'billing_frequencies'), 'Semanal', 'weekly', 'WEEKLY', '#06B6D4', 6, true);

-- Tipos de Pago
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'payment_types'), 'Pago Regular', 'payment', 'PAYMENT', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_types'), 'Detraccion', 'detraction', 'DETRACTION', '#F59E0B', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_types'), 'Reembolso', 'refund', 'REFUND', '#8B5CF6', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_types'), 'Anticipo', 'advance', 'ADVANCE', '#06B6D4', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'payment_types'), 'Penalidad', 'penalty', 'PENALTY', '#EF4444', 5, true);

-- Prioridades
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'priorities'), 'Baja', 'low', 'LOW', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'priorities'), 'Media', 'medium', 'MEDIUM', '#F59E0B', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'priorities'), 'Alta', 'high', 'HIGH', '#EF4444', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'priorities'), 'Critica', 'critical', 'CRITICAL', '#DC2626', 4, true);

-- Tipos de Documento
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'document_types'), 'Contrato', 'contract', 'CONTRACT', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_types'), 'Propuesta', 'proposal', 'PROPOSAL', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_types'), 'Acuerdo de Confidencialidad', 'nda', 'NDA', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_types'), 'Enmienda', 'amendment', 'AMENDMENT', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_types'), 'Factura', 'invoice', 'INVOICE', '#06B6D4', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_types'), 'Certificado', 'certificate', 'CERTIFICATE', '#84CC16', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_types'), 'Orden de Compra', 'purchase_order', 'PURCHASE_ORDER', '#F97316', 7, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_types'), 'Acuerdo', 'agreement', 'AGREEMENT', '#EF4444', 8, true);

-- Estados de Documento
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'document_statuses'), 'Borrador', 'draft', 'DRAFT', '#6B7280', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_statuses'), 'Pendiente de Revision', 'pending_review', 'PENDING_REVIEW', '#F59E0B', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_statuses'), 'Aprobado', 'approved', 'APPROVED', '#10B981', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_statuses'), 'Firmado', 'signed', 'SIGNED', '#059669', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_statuses'), 'Rechazado', 'rejected', 'REJECTED', '#EF4444', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_statuses'), 'Expirado', 'expired', 'EXPIRED', '#9CA3AF', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'document_statuses'), 'Cancelado', 'cancelled', 'CANCELLED', '#6B7280', 7, true);

-- Metodos de Firma
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'signature_methods'), 'Firma Digital', 'digital', 'DIGITAL', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'signature_methods'), 'Firma Electronica', 'electronic', 'ELECTRONIC', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'signature_methods'), 'Firma Fisica', 'physical', 'PHYSICAL', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'signature_methods'), 'DocuSign', 'docusign', 'DOCUSIGN', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'signature_methods'), 'Adobe Sign', 'adobe_sign', 'ADOBE_SIGN', '#EF4444', 5, true);

-- Tipos de Soporte
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'support_types'), 'Soporte Basico', 'basic', 'BASIC', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'support_types'), 'Soporte Premium', 'premium', 'PREMIUM', '#F59E0B', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'support_types'), 'Soporte Empresarial', 'enterprise', 'ENTERPRISE', '#EF4444', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'support_types'), 'Soporte 24/7', 'support_24_7', 'SUPPORT_24_7', '#8B5CF6', 4, true);

-- Prioridades de Ticket
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'ticket_priorities'), 'Baja', 'low', 'LOW', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_priorities'), 'Media', 'medium', 'MEDIUM', '#F59E0B', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_priorities'), 'Alta', 'high', 'HIGH', '#EF4444', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_priorities'), 'Urgente', 'urgent', 'URGENT', '#DC2626', 4, true);

-- Severidades de Ticket
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'ticket_severities'), 'Baja', 'low', 'LOW', '#10B981', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_severities'), 'Media', 'medium', 'MEDIUM', '#F59E0B', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_severities'), 'Alta', 'high', 'HIGH', '#EF4444', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_severities'), 'Critica', 'critical', 'CRITICAL', '#DC2626', 4, true);

-- Estados de Ticket
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'ticket_statuses'), 'Abierto', 'open', 'OPEN', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_statuses'), 'En Progreso', 'in_progress', 'IN_PROGRESS', '#F59E0B', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_statuses'), 'Esperando al Cliente', 'waiting_customer', 'WAITING_CUSTOMER', '#8B5CF6', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_statuses'), 'Resuelto', 'resolved', 'RESOLVED', '#10B981', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_statuses'), 'Cerrado', 'closed', 'CLOSED', '#6B7280', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_statuses'), 'Cancelado', 'cancelled', 'CANCELLED', '#EF4444', 6, true);

-- Categorias de Ticket
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'ticket_categories'), 'Problema Tecnico', 'technical_issue', 'TECHNICAL_ISSUE', '#EF4444', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_categories'), 'Reporte de Error', 'bug_report', 'BUG_REPORT', '#DC2626', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_categories'), 'Solicitud de Funcion', 'feature_request', 'FEATURE_REQUEST', '#10B981', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_categories'), 'Pregunta General', 'general_question', 'GENERAL_QUESTION', '#3B82F6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_categories'), 'Problema de Cuenta', 'account_issue', 'ACCOUNT_ISSUE', '#F59E0B', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_categories'), 'Consulta de Facturacion', 'billing_question', 'BILLING_QUESTION', '#8B5CF6', 6, true),
((SELECT id FROM config.catalog_types WHERE code = 'ticket_categories'), 'Solicitud de Capacitacion', 'training_request', 'TRAINING_REQUEST', '#06B6D4', 7, true);

-- Tipos de Alerta
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'alert_types'), 'Alerta por Correo', 'email', 'EMAIL', '#3B82F6', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'alert_types'), 'Alerta por SMS', 'sms', 'SMS', '#10B981', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'alert_types'), 'Notificacion Push', 'push', 'PUSH', '#F59E0B', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'alert_types'), 'Alerta en Panel', 'dashboard', 'DASHBOARD', '#8B5CF6', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'alert_types'), 'Notificacion Slack', 'slack', 'SLACK', '#06B6D4', 5, true);

-- Estados de Alerta
INSERT INTO config.catalog_options (catalog_type_id, name, code, value, color_code, sort_order, is_active) VALUES
((SELECT id FROM config.catalog_types WHERE code = 'alert_statuses'), 'Pendiente', 'pending', 'PENDING', '#F59E0B', 1, true),
((SELECT id FROM config.catalog_types WHERE code = 'alert_statuses'), 'Enviado', 'sent', 'SENT', '#3B82F6', 2, true),
((SELECT id FROM config.catalog_types WHERE code = 'alert_statuses'), 'Reconocido', 'acknowledged', 'ACKNOWLEDGED', '#10B981', 3, true),
((SELECT id FROM config.catalog_types WHERE code = 'alert_statuses'), 'Completado', 'completed', 'COMPLETED', '#059669', 4, true),
((SELECT id FROM config.catalog_types WHERE code = 'alert_statuses'), 'Cancelado', 'cancelled', 'CANCELLED', '#EF4444', 5, true),
((SELECT id FROM config.catalog_types WHERE code = 'alert_statuses'), 'Fallo', 'failed', 'FAILED', '#DC2626', 6, true);

-- =============================================================================
-- 3. INSERT DEFAULT CURRENCIES
-- =============================================================================

INSERT INTO billing.currencies (code, name, symbol, exchange_rate, is_base_currency, is_active) VALUES
('USD', 'Dolar Estadounidense', '$', 1.000000, true, true),
('EUR', 'Euro', '€', 0.850000, false, true),
('PEN', 'Sol Peruano', 'S/', 3.750000, false, true),
('MXN', 'Peso Mexicano', '$', 18.500000, false, true),
('COP', 'Peso Colombiano', '$', 4200.000000, false, true);

-- =============================================================================
-- 4. INSERT DEFAULT PAYMENT METHODS
-- =============================================================================

INSERT INTO billing.payment_methods (name, code, description, is_active) VALUES
('Efectivo', 'cash', 'Pago en efectivo', true),
('Transferencia Bancaria', 'bank_transfer', 'Transferencia bancaria', true),
('Tarjeta de Credito', 'credit_card', 'Pago con tarjeta de credito', true),
('Tarjeta de Debito', 'debit_card', 'Pago con tarjeta de debito', true),
('Cheque', 'check', 'Pago con cheque', true),
('PayPal', 'paypal', 'Pago a traves de PayPal', true),
('Yape', 'yape', 'Pago a traves de Yape', true),
('Plin', 'plin', 'Pago a traves de Plin', true);
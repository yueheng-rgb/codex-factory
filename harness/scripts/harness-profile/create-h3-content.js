var fs = require("fs");
var h = "C:/Codex_App_Factory/harness";

// ===== Profile 1: local-http-app.profile.json =====
var httpProfile = {
    profileId: "local-http-app",
    profileName: "Local HTTP App",
    projectType: "local-http-app",
    defaultWorkerRoles: [
        { roleId: "domain-core", roleName: "Domain Core", responsibilities: ["entity models","validation","state management"] },
        { roleId: "http-api", roleName: "HTTP API", responsibilities: ["routing","handlers","request parsing","response building"] },
        { roleId: "static-ui", roleName: "Static UI", responsibilities: ["static page","app JS","basic UI"] },
        { roleId: "cli-tool", roleName: "CLI Tool", responsibilities: ["dataset generation","fixture management","CLI commands"] },
        { roleId: "reports", roleName: "Reports", responsibilities: ["acceptance runner","report generation","export/import"] }
    ],
    defaultAcceptanceLayers: ["GateCheck","FunctionalAcceptance","RuntimeAcceptance","HTTPAcceptance","StaticAcceptance"],
    defaultComplexityBudget: { minimumWorkers: 2, minimumTasks: 2, minimumJsFiles: 12, minimumNamedExports: 20, minimumCrossWorkerDeps: 8, minimumScenarios: 6 },
    recommendedArtifacts: ["RUN_STATE.jsonl","reports/gatecheck-report.json","reports/functional-acceptance-report.json","reports/http-app-acceptance-report.json","reports/static-artifact-acceptance-report.json","canonical-integrated/"],
    forbiddenSimplifications: ["skip_http_acceptance","skip_static_ui","merge_all_workers_into_one","single_file_server","no_validation_on_input","no_error_handling"],
    requiredArchitecturePatterns: ["entity_validation_layer","request_response_separation","static_page_with_js"],
    defaultFailureModes: ["invalid_input","missing_endpoint","static_page_broken","performance_budget_exceeded"],
    profileVersion: "1.0.0"
};
fs.writeFileSync(h + "/profiles/local-http-app.profile.json", JSON.stringify(httpProfile,null,2),"utf8");

// ===== Profile 2: cli-workflow.profile.json =====
var cliProfile = {
    profileId: "cli-workflow",
    profileName: "CLI Workflow",
    projectType: "cli-workflow",
    defaultWorkerRoles: [
        { roleId: "domain-core", roleName: "Domain Core", responsibilities: ["entity models","validation","state management"] },
        { roleId: "cli-commands", roleName: "CLI Commands", responsibilities: ["command parsing","argument validation","subcommands"] },
        { roleId: "workflow-engine", roleName: "Workflow Engine", responsibilities: ["multi-step workflow","state machine","error recovery"] },
        { roleId: "artifact", roleName: "Artifact Builder", responsibilities: ["output generation","format conversion","file I/O"] },
        { roleId: "reports", roleName: "Reports/Acceptance", responsibilities: ["acceptance runner","report generation","deterministic verification"] }
    ],
    defaultAcceptanceLayers: ["GateCheck","FunctionalAcceptance","RuntimeAcceptance","ArtifactAcceptance","StaticAcceptance"],
    defaultComplexityBudget: { minimumWorkers: 2, minimumTasks: 2, minimumJsFiles: 10, minimumNamedExports: 18, minimumCrossWorkerDeps: 6, minimumScenarios: 5 },
    recommendedArtifacts: ["RUN_STATE.jsonl","reports/gatecheck-report.json","reports/artifact-acceptance-report.json","canonical-integrated/","output-data/"],
    forbiddenSimplifications: ["skip_cli_acceptance","skip_artifacts","single_command_only","no_validation","no_error_messages","deterministic_output_not_guaranteed"],
    requiredArchitecturePatterns: ["command_pattern","pipeline_workflow","deterministic_output"],
    defaultFailureModes: ["invalid_args","workflow_step_failure","artifact_missing","state_not_deterministic"],
    profileVersion: "1.0.0"
};
fs.writeFileSync(h + "/profiles/cli-workflow.profile.json", JSON.stringify(cliProfile,null,2),"utf8");

// ===== Profile 3: data-pipeline.profile.json =====
var pipeProfile = {
    profileId: "data-pipeline",
    profileName: "Data Pipeline",
    projectType: "data-pipeline",
    defaultWorkerRoles: [
        { roleId: "ingestion", roleName: "Data Ingestion", responsibilities: ["source reading","format parsing","schema validation"] },
        { roleId: "transformation", roleName: "Transformation", responsibilities: ["mapping","filtering","aggregation","enrichment"] },
        { roleId: "validation", roleName: "Quality Validation", responsibilities: ["integrity checks","constraint validation","anomaly detection"] },
        { roleId: "output", roleName: "Output Writer", responsibilities: ["report generation","format serialization","file export"] },
        { roleId: "fixture", roleName: "Fixture/Repro", responsibilities: ["fixture generation","reproducible runs","data snapshot"] }
    ],
    defaultAcceptanceLayers: ["GateCheck","FunctionalAcceptance","RuntimeAcceptance","DataIntegrityAcceptance","StaticAcceptance"],
    defaultComplexityBudget: { minimumWorkers: 3, minimumTasks: 3, minimumJsFiles: 14, minimumNamedExports: 22, minimumCrossWorkerDeps: 10, minimumScenarios: 7 },
    recommendedArtifacts: ["RUN_STATE.jsonl","reports/gatecheck-report.json","reports/data-integrity-acceptance-report.json","output-data/","fixtures/"],
    forbiddenSimplifications: ["skip_integrity_checks","skip_validation","single_pipeline_stage","no_reproducible_fixture","no_error_log","no_data_lineage"],
    requiredArchitecturePatterns: ["pipeline_stages","validation_gate","reproducible_fixtures"],
    defaultFailureModes: ["invalid_source_data","transform_error","integrity_check_failed","fixture_not_reproducible","missing_output"],
    profileVersion: "1.0.0"
};
fs.writeFileSync(h + "/profiles/data-pipeline.profile.json", JSON.stringify(pipeProfile,null,2),"utf8");

// ===== Domain Pack 1: inventory-ops =====
var inventoryDomain = {
    domainId: "inventory-ops",
    domainName: "Inventory Operations",
    domainVersion: "1.0.0",
    domainBrief: "Warehouse inventory management with stock tracking, adjustments, transfers, audit events, and concurrency control.",
    glossary: [
        { term: "SKU", definition: "Stock Keeping Unit — unique product identifier", entity: true },
        { term: "stock level", definition: "Current on-hand quantity of a SKU at a location", entity: false },
        { term: "reserved stock", definition: "Stock reserved for pending orders, not available for new orders", entity: false },
        { term: "inbound adjustment", definition: "Positive stock correction (receiving, return, recount up)", entity: false },
        { term: "outbound adjustment", definition: "Negative stock correction (shipment, damage, recount down)", entity: false },
        { term: "transfer", definition: "Movement of stock between locations", entity: false },
        { term: "inventory count", definition: "Physical or system stock count at a point in time", entity: false },
        { term: "audit event", definition: "Immutable record of any stock change", entity: true },
        { term: "idempotency key", definition: "Unique key to prevent double-application of stock changes", entity: false },
        { term: "optimistic version", definition: "Version number for optimistic concurrency control on stock records", entity: false }
    ],
    domainEntities: [
        { entityId: "SKU", entityName: "SKU", fields: ["skuId","name","category","unit"], primaryKey: "skuId", constraints: ["skuId must be unique","name must not be empty"] },
        { entityId: "StockRecord", entityName: "StockRecord", fields: ["skuId","locationId","onHand","reserved","version"], primaryKey: "skuId+locationId", constraints: ["onHand >= 0","reserved <= onHand","reserved >= 0","version starts at 1"] },
        { entityId: "Adjustment", entityName: "Adjustment", fields: ["adjustmentId","skuId","locationId","quantity","type","idempotencyKey","timestamp"], primaryKey: "adjustmentId", constraints: ["adjustmentId must be unique","idempotencyKey must not repeat for same skuId+locationId","type must be inbound or outbound"] },
        { entityId: "Transfer", entityName: "Transfer", fields: ["transferId","skuId","fromLocationId","toLocationId","quantity","status","timestamp"], primaryKey: "transferId", constraints: ["fromLocation.onHand must have sufficient stock","toLocation must exist","quantity > 0"] },
        { entityId: "AuditEvent", entityName: "AuditEvent", fields: ["eventId","entityType","entityId","change","timestamp","actor"], primaryKey: "eventId", constraints: ["every stock change must produce an audit event","audit events are immutable"] }
    ],
    workflows: [
        { workflowId: "inbound-receipt", name: "Inbound Receipt", steps: ["validate SKU exists","validate quantity > 0","generate idempotency key","apply inbound adjustment","update stock level","create audit event"], involvedEntities: ["SKU","StockRecord","Adjustment","AuditEvent"] },
        { workflowId: "outbound-shipment", name: "Outbound Shipment", steps: ["validate SKU exists","check available stock >= quantity","validate quantity > 0","generate idempotency key","apply outbound adjustment","update stock level","create audit event"], involvedEntities: ["SKU","StockRecord","Adjustment","AuditEvent"] },
        { workflowId: "inter-location-transfer", name: "Inter-Location Transfer", steps: ["validate both locations","check source stock","decrement source","increment destination","create transfer record","create audit events"], involvedEntities: ["StockRecord","Transfer","AuditEvent"] }
    ],
    businessRules: [
        { ruleId: "BR-001", description: "Available stock cannot be negative", severity: "critical", affectedEntities: ["StockRecord"], positiveExamples: ["onHand=10, reserved=5 => available=5"], negativeExamples: ["onHand=5, reserved=10 => REJECT"], acceptanceImplication: "Stock adjustment must reject if resulting available stock < 0" },
        { ruleId: "BR-002", description: "Duplicate idempotency key cannot double-apply stock", severity: "critical", affectedEntities: ["Adjustment","StockRecord"], positiveExamples: ["key=abc applied once => stock changes"], negativeExamples: ["key=abc applied twice => second time REJECT"], acceptanceImplication: "Idempotency key must be checked before applying adjustment" },
        { ruleId: "BR-003", description: "Reserved stock cannot exceed on-hand stock", severity: "critical", affectedEntities: ["StockRecord"], positiveExamples: ["onHand=10 => reserve up to 10"], negativeExamples: ["onHand=5 => reserve 6 REJECT"], acceptanceImplication: "Reservation must check onHand before reserving" },
        { ruleId: "BR-004", description: "Every inventory adjustment must create an audit event", severity: "high", affectedEntities: ["Adjustment","AuditEvent"], positiveExamples: ["adjust stock => audit event created"], negativeExamples: ["adjust stock => no audit event FAIL"], acceptanceImplication: "Every adjustment must produce a paired audit event" },
        { ruleId: "BR-005", description: "Stale version update must be rejected", severity: "high", affectedEntities: ["StockRecord"], positiveExamples: ["version=3 update with version=3 => OK"], negativeExamples: ["version=3 update with version=2 => REJECT (stale)"], acceptanceImplication: "Optimistic version check must reject stale updates" }
    ],
    invariants: [
        "available stock = onHand - reserved; available >= 0",
        "duplicate idempotency key cannot double-apply stock change",
        "reserved stock cannot exceed on-hand stock",
        "every inventory adjustment must create an audit event",
        "stale version update must be rejected"
    ],
    edgeCases: ["zero stock adjustment","stock level at exactly zero","transfer between same location","adjustment with quantity zero","reservation release after cancellation"],
    exampleData: [
        { scenario: "normal inbound", data: { skuId: "SKU-001", locationId: "WH-A", quantity: 100, type: "inbound" } },
        { scenario: "insufficient stock outbound", data: { skuId: "SKU-001", locationId: "WH-A", quantity: 200, type: "outbound" } }
    ],
    forbiddenAssumptions: ["stock is always available","no concurrent updates","adjustments never conflict","transfers are instantaneous"],
    requiredWorkerResponsibilities: [
        { workerRole: "domain-core", responsibilities: ["SKU CRUD","StockRecord CRUD","Adjustment validation","inventory queries"], assignedEntities: ["SKU","StockRecord","Adjustment"] },
        { workerRole: "transfer-worker", responsibilities: ["Transfer creation","cross-location validation","stock reservation"], assignedEntities: ["Transfer","StockRecord"] },
        { workerRole: "audit-worker", responsibilities: ["AuditEvent creation","audit log queries","immutability enforcement"], assignedEntities: ["AuditEvent"] },
        { workerRole: "concurrency-worker", responsibilities: ["optimistic version check","idempotency key check","conflict resolution"], assignedEntities: ["StockRecord","Adjustment"] },
        { workerRole: "acceptance-worker", responsibilities: ["fixture generation","acceptance runner","report generation"], assignedEntities: [] }
    ],
    requiredDomainScenarios: ["inbound_adjustment_correctly_updates_stock","outbound_rejected_when_insufficient_stock","duplicate_idempotency_key_rejected","reservation_exceeds_on_hand_rejected","audit_event_created_on_adjustment","stale_version_update_rejected","transfer_decrements_source_increments_destination","adjustment_with_quantity_zero_handled"]
};
fs.writeFileSync(h + "/domain-packs/inventory-ops/domain-skill-pack.json", JSON.stringify(inventoryDomain,null,2),"utf8");

// ===== Verifier Pack 1: inventory-ops =====
var inventoryVerifier = {
    verifierPackId: "inventory-ops-verifier",
    domainId: "inventory-ops",
    acceptanceScenarios: [
        { scenarioId: "S-001", description: "Inbound adjustment correctly updates stock level", requiredInputs: ["valid SKU","positive quantity","idempotency key"], expectedOutputs: ["stock level increased by quantity","audit event created"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["available stock >= 0","audit event created"] },
        { scenarioId: "S-002", description: "Outbound adjustment rejected when insufficient stock", requiredInputs: ["valid SKU","quantity > available stock"], expectedOutputs: ["adjustment rejected","REJECT error message","stock unchanged"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["available stock >= 0"] },
        { scenarioId: "S-003", description: "Duplicate idempotency key rejected", requiredInputs: ["previously used idempotency key"], expectedOutputs: ["adjustment rejected","DUPLICATE_KEY error"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["duplicate idempotency key cannot double-apply"] },
        { scenarioId: "S-004", description: "Reservation exceeds on-hand rejected", requiredInputs: ["reserve quantity > onHand"], expectedOutputs: ["reservation rejected"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["reserved <= onHand"] },
        { scenarioId: "S-005", description: "Audit event created on every adjustment", requiredInputs: ["any valid adjustment"], expectedOutputs: ["paired audit event with matching eventId"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["audit event created"] },
        { scenarioId: "S-006", description: "Stale version update rejected", requiredInputs: ["stock record version=3","update with version=2"], expectedOutputs: ["update rejected","STALE_VERSION error"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["stale version rejected"] },
        { scenarioId: "S-007", description: "Transfer decrements source and increments destination", requiredInputs: ["valid from/to locations","sufficient source stock"], expectedOutputs: ["source decremented","destination incremented","audit events created"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["audit event created"] },
        { scenarioId: "S-008", description: "Adjustment with quantity zero handled gracefully", requiredInputs: ["quantity=0 adjustment"], expectedOutputs: ["handled without error or rejected with clear message"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE" }
    ],
    negativeControls: [
        { negativeId: "N-001", targetsScenario: "S-001", injectedFault: "skip stock update after inbound adjustment", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true },
        { negativeId: "N-002", targetsScenario: "S-002", injectedFault: "allow outbound when insufficient stock", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true },
        { negativeId: "N-003", targetsScenario: "S-003", injectedFault: "ignore idempotency key check", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true },
        { negativeId: "N-004", targetsScenario: "S-004", injectedFault: "skip reservation limit check", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true },
        { negativeId: "N-005", targetsScenario: "S-005", injectedFault: "omit audit event after adjustment", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true },
        { negativeId: "N-006", targetsScenario: "S-006", injectedFault: "accept stale version update", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true }
    ],
    requiredEvidence: ["RUN_STATE.jsonl","reports/functional-acceptance-report.json","reports/gatecheck-report.json","worker-freeze-manifests/","reports/audit-event-log.json"],
    domainSpecificFailureModes: ["duplicate_idempotency_key","insufficient_stock","stale_version","missing_audit_event","negative_available_stock","reservation_exceeds_on_hand"],
    invariantChecks: [
        { invariant: "available stock >= 0", scenarioId: "S-001", negativeId: "N-001" },
        { invariant: "duplicate idempotency key cannot double-apply", scenarioId: "S-003", negativeId: "N-003" },
        { invariant: "reserved <= onHand", scenarioId: "S-004", negativeId: "N-004" },
        { invariant: "audit event created on adjustment", scenarioId: "S-005", negativeId: "N-005" },
        { invariant: "stale version rejected", scenarioId: "S-006", negativeId: "N-006" }
    ],
    reportRequirements: ["Must list invariant->scenario mapping","Must list scenario->negative mapping","Must show gap count for uncovered invariants","Must confirm all business rules have scenarios"]
};
fs.writeFileSync(h + "/domain-packs/inventory-ops/domain-verifier-pack.json", JSON.stringify(inventoryVerifier,null,2),"utf8");

// ===== Domain Pack 2: support-desk =====
var supportDomain = {
    domainId: "support-desk",
    domainName: "Support Desk",
    domainVersion: "1.0.0",
    domainBrief: "Support ticket workflow with priority, assignment, status lifecycle, SLA tracking, and agent workload management.",
    glossary: [
        { term: "ticket", definition: "A support request with subject, description, priority, status", entity: true },
        { term: "requester", definition: "The user who created the ticket", entity: false },
        { term: "agent", definition: "Support staff assigned to resolve tickets", entity: false },
        { term: "priority", definition: "Urgency level (low, medium, high, critical)", entity: false },
        { term: "status", definition: "Ticket lifecycle state (open, assigned, in_progress, resolved, closed)", entity: false },
        { term: "assignment", definition: "Linking an agent to a ticket", entity: true },
        { term: "SLA", definition: "Service Level Agreement — response/resolution time targets", entity: false },
        { term: "workload", definition: "Number of active tickets assigned to an agent", entity: false },
        { term: "resolution", definition: "The solution or fix applied to close a ticket", entity: false },
        { term: "escalation", definition: "Raising a ticket priority or reassigning to senior agent", entity: false }
    ],
    domainEntities: [
        { entityId: "Ticket", entityName: "Ticket", fields: ["ticketId","subject","description","priority","status","requesterId","assignedAgentId","createdAt","resolvedAt"], primaryKey: "ticketId", constraints: ["priority must be low/medium/high/critical","status follows lifecycle: open->assigned->in_progress->resolved->closed"] },
        { entityId: "Agent", entityName: "Agent", fields: ["agentId","name","maxWorkload","currentWorkload","active"], primaryKey: "agentId", constraints: ["currentWorkload <= maxWorkload","maxWorkload > 0"] },
        { entityId: "Assignment", entityName: "Assignment", fields: ["assignmentId","ticketId","agentId","assignedAt","reason"], primaryKey: "assignmentId", constraints: ["ticket can only be assigned to one active agent","agent cannot exceed maxWorkload"] },
        { entityId: "SLAEvent", entityName: "SLAEvent", fields: ["slaId","ticketId","targetType","targetTime","achievedAt","breached"], primaryKey: "slaId", constraints: ["breached=true if achievedAt > targetTime"] }
    ],
    workflows: [
        { workflowId: "ticket-lifecycle", name: "Ticket Lifecycle", steps: ["create ticket","set priority","assign agent","work in progress","resolve","close","archive"], involvedEntities: ["Ticket","Agent","Assignment"] },
        { workflowId: "escalation", name: "Escalation", steps: ["detect SLA breach","raise priority","notify senior agent","reassign"], involvedEntities: ["Ticket","Agent","SLAEvent"] },
        { workflowId: "workload-balance", name: "Workload Balance", steps: ["check agent workload","find available agent","assign ticket","update workload count"], involvedEntities: ["Ticket","Agent","Assignment"] }
    ],
    businessRules: [
        { ruleId: "BR-101", description: "Ticket status must follow valid lifecycle transitions", severity: "critical", affectedEntities: ["Ticket"], positiveExamples: ["open->assigned OK","in_progress->resolved OK"], negativeExamples: ["open->closed REJECT","resolved->assigned REJECT"], acceptanceImplication: "Status transition validation must reject invalid transitions" },
        { ruleId: "BR-102", description: "Agent workload cannot exceed maxWorkload", severity: "critical", affectedEntities: ["Agent","Assignment"], positiveExamples: ["agent has capacity => assignment OK"], negativeExamples: ["agent at maxWorkload => assignment REJECT"], acceptanceImplication: "Assignment must check agent capacity before assigning" },
        { ruleId: "BR-103", description: "High priority tickets must be assigned within SLA window", severity: "high", affectedEntities: ["Ticket","SLAEvent"], positiveExamples: ["high priority assigned in 15min => SLA met"], negativeExamples: ["high priority unassigned after 1hr => SLA breached"], acceptanceImplication: "SLA tracking must detect breached assignments" },
        { ruleId: "BR-104", description: "Resolved tickets cannot be reopened without audit reason", severity: "medium", affectedEntities: ["Ticket"], positiveExamples: ["resolved ticket reopened with 'customer_reply' reason => OK"], negativeExamples: ["resolved ticket reopened without reason => REJECT"], acceptanceImplication: "Reopen must require audit reason" },
        { ruleId: "BR-105", description: "Each status change must record timestamp", severity: "high", affectedEntities: ["Ticket"], positiveExamples: ["status change => timestamp recorded"], negativeExamples: ["status change => timestamp missing FAIL"], acceptanceImplication: "Every ticket mutation must include timestamp" }
    ],
    invariants: [
        "ticket status follows valid lifecycle transitions",
        "agent.currentWorkload <= agent.maxWorkload at all times",
        "high priority tickets must be assigned or escalated within SLA",
        "resolved tickets require audit reason to reopen",
        "every status change must record a timestamp"
    ],
    edgeCases: ["agent with zero maxWorkload","ticket assigned to inactive agent","SLA breached but ticket already resolved","empty subject or description","concurrent assignment attempts"],
    exampleData: [
        { scenario: "normal ticket flow", data: { ticketId: "TKT-001", priority: "medium", subject: "Login issue" } },
        { scenario: "agent at capacity", data: { agentId: "AGT-001", maxWorkload: 5, currentWorkload: 5 } }
    ],
    forbiddenAssumptions: ["agents always have capacity","tickets never breach SLA","status transitions are always valid","no concurrent assignments"],
    requiredWorkerResponsibilities: [
        { workerRole: "ticket-worker", responsibilities: ["Ticket CRUD","status lifecycle validation","priority assignment"], assignedEntities: ["Ticket"] },
        { workerRole: "agent-worker", responsibilities: ["Agent management","workload tracking","assignment validation"], assignedEntities: ["Agent","Assignment"] },
        { workerRole: "sla-worker", responsibilities: ["SLA tracking","breach detection","escalation triggers"], assignedEntities: ["SLAEvent"] },
        { workerRole: "workflow-worker", responsibilities: ["status transitions","reopen validation","audit reason enforcement"], assignedEntities: ["Ticket"] },
        { workerRole: "acceptance-worker", responsibilities: ["fixture generation","acceptance runner","report generation"], assignedEntities: [] }
    ],
    requiredDomainScenarios: ["valid_status_transition_accepted","invalid_status_transition_rejected","agent_at_capacity_assignment_rejected","sla_breach_detected","resolved_ticket_reopen_with_reason","resolved_ticket_reopen_without_reason_rejected","status_change_timestamp_recorded","assign_ticket_to_available_agent"]
};
fs.writeFileSync(h + "/domain-packs/support-desk/domain-skill-pack.json", JSON.stringify(supportDomain,null,2),"utf8");

// ===== Verifier Pack 2: support-desk =====
var supportVerifier = {
    verifierPackId: "support-desk-verifier",
    domainId: "support-desk",
    acceptanceScenarios: [
        { scenarioId: "S-101", description: "Valid status transition accepted", requiredInputs: ["ticket in open status","transition to assigned"], expectedOutputs: ["status changed to assigned","timestamp recorded"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["valid lifecycle transitions"] },
        { scenarioId: "S-102", description: "Invalid status transition rejected", requiredInputs: ["ticket in resolved status","transition to assigned"], expectedOutputs: ["transition rejected","INVALID_TRANSITION error"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["valid lifecycle transitions"] },
        { scenarioId: "S-103", description: "Agent at capacity assignment rejected", requiredInputs: ["agent at maxWorkload","new ticket assignment"], expectedOutputs: ["assignment rejected","AGENT_AT_CAPACITY error"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["workload <= maxWorkload"] },
        { scenarioId: "S-104", description: "SLA breach detected for unassigned high priority", requiredInputs: ["high priority ticket","no assignment within SLA window"], expectedOutputs: ["SLAEvent with breached=true"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["high priority assigned within SLA"] },
        { scenarioId: "S-105", description: "Resolved ticket reopen with audit reason accepted", requiredInputs: ["resolved ticket","reopen with reason"], expectedOutputs: ["ticket reopened","audit reason recorded"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["audit reason on reopen"] },
        { scenarioId: "S-106", description: "Resolved ticket reopen without reason rejected", requiredInputs: ["resolved ticket","reopen without reason"], expectedOutputs: ["reopen rejected","REASON_REQUIRED error"], evidencePath: "reports/functional-acceptance-report.json", failureClassification: "FAIL_TARGET_GATE", invariantCoverage: ["audit reason on reopen"] }
    ],
    negativeControls: [
        { negativeId: "N-101", targetsScenario: "S-101", injectedFault: "allow invalid status transition", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true },
        { negativeId: "N-102", targetsScenario: "S-102", injectedFault: "reject valid transition", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true },
        { negativeId: "N-103", targetsScenario: "S-103", injectedFault: "assign to agent at capacity", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true },
        { negativeId: "N-104", targetsScenario: "S-104", injectedFault: "miss SLA breach detection", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true },
        { negativeId: "N-105", targetsScenario: "S-105", injectedFault: "reopen without checking for audit reason", expectedFailureClass: "FAIL_TARGET_GATE", mustKeepOtherGatesPassing: true }
    ],
    requiredEvidence: ["RUN_STATE.jsonl","reports/functional-acceptance-report.json","reports/gatecheck-report.json","worker-freeze-manifests/","reports/sla-event-log.json"],
    domainSpecificFailureModes: ["invalid_status_transition","agent_over_capacity","sla_breached","missing_audit_reason","duplicate_assignment"],
    invariantChecks: [
        { invariant: "valid lifecycle transitions", scenarioId: "S-101", negativeId: "N-101" },
        { invariant: "agent workload <= maxWorkload", scenarioId: "S-103", negativeId: "N-103" },
        { invariant: "high priority SLA assignment", scenarioId: "S-104", negativeId: "N-104" },
        { invariant: "audit reason on reopen", scenarioId: "S-105", negativeId: "N-105" }
    ],
    reportRequirements: ["Must list invariant->scenario mapping","Must list scenario->negative mapping","Must cover all 5 invariants","Must confirm all business rules have scenarios"]
};
fs.writeFileSync(h + "/domain-packs/support-desk/domain-verifier-pack.json", JSON.stringify(supportVerifier,null,2),"utf8");

console.log("3 profiles + 2 domain packs + 2 verifier packs created");

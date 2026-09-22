-- Seed reference data that already exists in FG-TIDA's process, so
-- reviewers have something to map use cases against from day one.

INSERT OR IGNORE INTO working_groups (slug, name, description) VALUES
    ('wg1-ra-aai', 'Remote Attestation for Agentic AI', NULL);

-- Themes as enumerated in the use-case issue template's "Theme relevance"
-- section (.github/ISSUE_TEMPLATE/fg-tida-use-case-proposal.md).
INSERT OR IGNORE INTO themes (name, description) VALUES
    ('Dynamic Identity', NULL),
    ('Continuous Trust and Attestation', NULL),
    ('Delegation', NULL),
    ('Discovery and Cross-Border Trust', NULL),
    ('Runtime Enforcement (Control Plane)', NULL),
    ('Embodied AI Identity and Trust', NULL);

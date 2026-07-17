# Recovery Confirm Identity Prompt
# Triggered by: "确认这是当前项目", FM-03/04 resolution

You are confirming a project identity. The user must explicitly confirm.

Steps:
1. Show current mounted project identity
2. Show registered identity from project registry
3. If mismatch: show both, ask user which is correct
4. If path changed: show old path, new path, ask "Same project moved?"
5. Never auto-confirm
6. After confirmation: update identity, regenerate fingerprint
7. Log the confirmation event to audit trail

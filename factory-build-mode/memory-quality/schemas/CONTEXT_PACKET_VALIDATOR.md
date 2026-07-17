# Context Packet Validator

## Validation Checks
| # | Check | Rule |
|---|-------|------|
| V01 | Size check | Total words < 2000 |
| V02 | Evidence paths present | At least 3 L4+ references |
| V03 | Risks present | All active risks included |
| V04 | Rejected claims present | At least 1 documented |
| V05 | No L0-L1 content | Only L3+ evidence |
| V06 | Role-appropriate | Target role can see all content |
| V07 | Forbidden actions listed | At least 3 |
| V08 | Timestamp freshness | Generated within last phase |
| V09 | Hash consistency | Evidence paths resolve to existing files |
| V10 | Decision recency | Most recent 5 decisions included |

## Validation Result
- ALL PASS → packet VALID
- ANY FAIL → packet REJECTED, regenerate

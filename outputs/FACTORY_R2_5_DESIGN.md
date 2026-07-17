# Products List API — Design
## R2.5 Real Factory Task
## Based on: Evidence Pack v2 (19 sources), REST API conventions

### Adopted Approach
- **Cursor-based pagination** (not offset): /api/products?cursor=xxx&limit=20
- **Multi-field filtering**: /api/products?filter[category]=electronics&filter[status]=active
- **Text search**: /api/products?search=wireless
- **Sorting**: /api/products?sort=price&order=desc

### Why cursor over offset
- Cursor is stable when data changes (no duplicate/skip)
- Better performance on large datasets (no OFFSET scan)
- Industry standard for modern APIs (GitHub, Stripe, Twitter)

### Query Parameter Design (from EP)
| Param | Type | Example | Description |
|-------|------|---------|-------------|
| cursor | string | "eyJpZCI6NDJ9" | base64-encoded last item ID |
| limit | int | 20 (max 100) | items per page |
| sort | string | price | field to sort by |
| order | string | sc/desc | sort direction |
| filter[field] | string | electronics | exact match filter |
| search | string | wireless | text search (LIKE) |

### Response Format
\\\json
{
  "data": [...],
  "pagination": {
    "nextCursor": "eyJpZCI6NjJ9",
    "hasMore": true,
    "total": 1542
  },
  "filters": { "applied": { "category": "electronics" } }
}
\\\

### Rejected Alternatives
| Alt | Reason |
|-----|--------|
| Offset pagination | Unstable with inserts/deletes; slow on large offsets |
| Page-based (?page=3) | Same issues as offset; hides total count dependency |
| GraphQL | Overkill for single list endpoint |
| Full-text search engine | Elasticsearch/Meilisearch overkill; SQL LIKE sufficient for MVP |

### Implementation Plan
1. GET /api/products with query params
2. Cursor = base64(JSON({id, sortValue}))
3. Dynamic WHERE from filter[] params (whitelist allowed fields)
4. search → SQL LIKE '%term%' on name + description
5. ORDER BY sort field, id (tiebreaker)
6. LIMIT limit + 1 (to detect hasMore)
7. Return pagination metadata

### Test Plan
| Test | Expected |
|------|----------|
| No params → first 20 products | 200, hasMore=true/false |
| cursor → next page | 200, different items |
| filter[category]=x → filtered | only matching items |
| search=term → matching | items with term in name/desc |
| limit=101 → rejected | 400, max 100 |
| invalid sort field → rejected | 400 |

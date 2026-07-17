# Source Priority for Research Agent
> Part of: FACTORY-R2.1-INFRA-MVP
> Version: 1.0.0

## Priority Order (Highest to Lowest)

1. **Official Documentation** (docs.example.com, nextjs.org, prisma.io, etc.)
   - Trust: VERIFIED
   - Use: Primary source for best practices and API references
   - Caveat: May lag behind latest release by days

2. **Official Examples / Starters** (github.com/vercel/next.js/tree/canary/examples)
   - Trust: VERIFIED
   - Use: Implementation patterns, project structure
   - Caveat: May be simplified for demo purposes

3. **Known Community Resources** (conference talks, well-known blog authors)
   - Trust: TRUSTED
   - Use: Architecture patterns, real-world experience
   - Caveat: May reflect personal preference over best practice

4. **GitHub Repos (> 1000 stars)**
   - Trust: TRUSTED
   - Use: Production patterns, edge case handling
   - Caveat: May include project-specific workarounds

5. **Stack Overflow (accepted answer, > 10 votes)**
   - Trust: AVAILABLE
   - Use: Specific error resolution, gotchas
   - Caveat: Answers may be outdated

6. **Blog Posts (author reputation considered)**
   - Trust: AVAILABLE
   - Use: Tutorials, walkthroughs
   - Caveat: Quality varies widely

7. **AI-Generated Content**
   - Trust: UNVERIFIED
   - Use: None directly. May be used for discovery only.
   - Caveat: High risk of hallucination. Always verify against official docs.

## Source Evaluation Criteria

- **Recency**: Published/updated within last 6 months (12 for stable tech)
- **Authority**: Author/organization with recognized expertise
- **Accuracy**: Consistent with official documentation
- **Coverage**: Addresses the specific question, not tangential
- **Objectivity**: Not marketing material or sponsored content

## Blocked Sources

- Paywalled content (cannot verify)
- Sources requiring login (cannot access)
- Sources with known malware/phishing history
- Sources that contradict official documentation without explanation
- Sources older than 2 years without update (unless version-pinned)

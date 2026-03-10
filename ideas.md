# SableLinux — Project Ideas & Notes

## Compliance-Aware OSINT Agent

An agentic app that takes a target (domain, IP, company, person) as input and:

1. Researches jurisdiction-specific legality of OSINT targeting (CFAA, GDPR, local laws)
2. Determines which OSINT techniques are legally applicable to that specific target type
3. Executes permitted passive recon tools (theHarvester, whois, DNS, etc.)
4. Synthesizes a structured report: legal framework + findings + recommended next steps

Key differentiator: compliance-aware before execution — reasons about what it's legally
allowed to gather before gathering it. Relevant to professional red team engagements
where rules of engagement matter.

Prototype of the commercial pentest automation and report writing product.

Stack: Python, LangGraph, Anthropic/OpenAI API, theHarvester, whois, DNS tools.

# Nexoraa CleanSoft ERP Prompt Engineering Standards

## Document Control

| Item | Definition |
|---|---|
| Document | Prompt Engineering Standards |
| Planning phase | Phase 07 — Prompt Engineering |
| Status | Official planning and governance guide |
| Applies to | All AI-assisted planning, architecture, implementation, testing, deployment, audit, documentation, and completion prompts |
| Primary repository location | `ERP-PLANNING/prompt-engineering/README.md` |
| Related governance | `ERP-PLANNING/implementation-prompts/README.md` |
| Implementation authority | None; this document defines standards and does not authorize implementation |

## Purpose and Boundaries

This document establishes the official Prompt Engineering methodology for the Nexoraa CleanSoft ERP. It governs how prompts are planned, written, reviewed, approved, executed, validated, reported, versioned, and maintained across the ERP development lifecycle.

The guide is documentation and planning material only. It does not contain or authorize source code, application programming interfaces, database schemas, user-interface components, business logic, module-specific requirements, or other implementation artifacts. It describes how future instructions must be designed and governed, not what any ERP module must implement.

# 1. Introduction

## 1.1 Definition of Prompt Engineering

Prompt Engineering is the disciplined practice of translating approved project intent into clear, structured, bounded, and verifiable instructions for an AI system. In an enterprise software program, it is not limited to phrasing a request effectively. It includes the governance needed to ensure that the AI receives the correct context, understands its authority, respects project constraints, produces the required evidence, and stops at the intended boundary.

For Nexoraa CleanSoft, a prompt acts as a controlled interface between planning and AI-assisted delivery. It explains the intended outcome, identifies authoritative sources, establishes scope and dependencies, defines quality expectations, and specifies how completion will be demonstrated. The prompt does not replace business requirements, architecture records, engineering standards, or human accountability. It connects those sources into an executable set of instructions.

## 1.2 Importance in AI-Assisted Software Development

AI development tools can analyze large repositories, propose changes, perform repetitive work, and accelerate validation. Their effectiveness, however, depends on the quality of the instructions and evidence they receive. A vague request can lead to reasonable-looking work that is incomplete, architecturally inconsistent, difficult to maintain, or outside the intended scope.

Prompt Engineering reduces this risk by making important constraints explicit. It ensures that an AI tool is directed to inspect existing work before acting, verify dependencies, preserve established decisions, distinguish requirements from assumptions, and validate outcomes rather than treating generation as completion.

In a multi-phase ERP, these controls are especially important because a local change can affect tenant separation, security, data ownership, integrations, operations, documentation, and later roadmap phases. A well-engineered prompt gives these concerns the same visibility as the immediate task.

## 1.3 Benefits of Standardization

A standardized prompt system improves:

- **Consistency:** AI tools receive the same categories of context, constraints, quality requirements, and completion instructions across phases.
- **Maintainability:** Prompts use predictable sections, terminology, references, and evidence requirements, making them easier to review and update.
- **Development quality:** Testing, documentation, security awareness, dependency verification, and acceptance evidence are planned before execution.
- **Architectural alignment:** Prompts reinforce approved boundaries and direct material decisions through the established architecture-decision process.
- **Traceability:** Objectives, scope, tasks, deliverables, acceptance criteria, validation evidence, and completion reports can be linked.
- **Repeatability:** Equivalent work can be approached using a consistent method across AI tools, development sessions, and contributors.
- **Governance:** Reviewers can determine what was authorized, which instructions were approved, and whether reported completion matches the original assignment.

Standardization does not mean making every prompt identical. It provides a common control structure while allowing prompt content and depth to remain proportionate to the category, risk, and complexity of the assigned work.

# 2. Objectives

## 2.1 Primary Objectives

The Prompt Engineering standards are intended to:

- Reduce ambiguity by stating the objective, scope, exclusions, dependencies, constraints, assumptions, expected outputs, and stopping condition.
- Standardize AI instructions so that different tools and contributors interpret equivalent requirements consistently.
- Improve implementation quality by requiring repository analysis, verification, testing, documentation, and evidence-based completion.
- Ensure architectural consistency by connecting every relevant prompt to approved architecture, ownership boundaries, decisions, and repository conventions.
- Enable repeatable enterprise development through a governed lifecycle, reusable structure, objective review gates, and version control.
- Prevent accidental scope expansion into unrelated modules, later phases, speculative features, or unauthorized remediation.
- Preserve existing work by requiring inspection of the repository and current changes before execution.
- Make hidden assumptions visible and direct material uncertainties to an explicit decision or escalation path.

## 2.2 Governance Objectives

Prompt Engineering also supports long-term program governance by ensuring that:

- Every approved phase has an identifiable instruction set and corresponding completion evidence.
- Prompt changes are reviewable and traceable to a reason, decision, audit finding, or repository change.
- A prompt is approved before it becomes the basis for implementation.
- Completion is based on observable results, not on the AI tool's confidence or a summary of attempted work.
- Failed, unavailable, skipped, or externally blocked validation is disclosed accurately.
- Historical completion evidence is not rewritten merely to match newer expectations.
- Execution ends when the assigned prompt is complete and does not continue automatically into another phase.

## 2.3 Success Characteristics

The standards are successful when an authorized AI tool can understand the assignment, locate the required context, recognize its boundaries, identify the expected evidence, and complete the assigned phase without avoidable clarification. Genuine missing authority or an unresolved material decision must still result in an explicit escalation rather than an invented answer.

# 3. Prompt Architecture

## 3.1 Standard Prompt Model

Every implementation prompt must follow a recognizable architecture. Section depth may vary according to risk and complexity, but mandatory information must not be omitted. A standard structure reduces interpretation differences and allows reviewers to detect gaps before execution.

The prompt architecture should progress from identity and intent, through authority and execution, to evidence and closure:

1. Identify the phase and its execution contract.
2. Define the desired outcome and boundaries.
3. Establish authoritative context and verified dependencies.
4. State architecture and quality constraints.
5. Describe the controlled workflow.
6. Define deliverables and acceptance evidence.
7. Instruct the executor how to report completion and stop.

## 3.2 Phase Information

Each phase prompt must provide:

- A canonical phase number and name.
- A stable document title and repository-relative location.
- Its status, such as draft, under review, approved, superseded, or retired.
- The corresponding completion-report location.
- Its relationship to direct predecessor and successor phases where that relationship affects execution.
- Any legacy filename or identifier that must be retained for traceability.

The phase number, name, catalog entry, prompt title, cross-references, and completion report must agree. Identity conflicts must be corrected or explicitly documented before approval.

## 3.3 Objective

The objective defines the outcome the assigned phase must achieve. It must be concise enough to guide decisions and specific enough to distinguish the phase from adjacent work.

A valid objective:

- Describes an outcome rather than a list of activities.
- Relates to approved planning or roadmap intent.
- Avoids embedding unsupported product requirements.
- Can be traced to deliverables and acceptance criteria.
- Does not promise results that depend on unavailable future phases.

## 3.4 Scope and Exclusions

The scope defines the work authorized by the prompt. It should identify affected capability areas, artifact types, validation responsibilities, and documentation expectations without prescribing unapproved implementation details.

Every implementation prompt must also contain an explicit out-of-scope section. Exclusions should identify adjacent capabilities, future-phase work, unsupported variants, broad refactoring, destructive changes, speculative enhancements, and external work that is not authorized.

Where the boundary might otherwise be unclear, the prompt should define:

- Whether limited dependency repair is permitted.
- Whether migrations, compatibility work, or operational updates are part of the phase.
- Whether existing defects discovered during execution may be corrected.
- Which systems, applications, packages, or documents may be changed.
- Which deliverables require separate approval.

## 3.5 Mandatory Reading and Authoritative Sources

The prompt must identify the material the executor is required to read before acting. This typically includes relevant planning documents, architecture guidance, engineering standards, decision records, predecessor prompts and reports, repository documentation, affected manifests, applicable tests, and the current repository state.

Mandatory reading must be:

- Relevant to the assigned work.
- Referenced by an accurate repository-relative path or stable authoritative identifier.
- Complete enough to prevent isolated interpretation.
- Ordered or grouped so the executor can identify governing sources.
- Reviewed periodically to remove obsolete or broken references.

The prompt must define how conflicts are resolved. Current verified repository evidence and newer approved decisions normally take precedence over stale prose, while business or architectural conflicts requiring new authority must be escalated rather than silently resolved.

## 3.6 Dependencies

Dependencies include earlier phases, decisions, services, shared capabilities, environments, approvals, artifacts, or external access required for the assignment.

For each material dependency, the prompt should explain:

- What the dependency is.
- Why it is required.
- Which evidence demonstrates readiness.
- How the executor verifies the evidence.
- What happens if the dependency is missing, inconsistent, or incomplete.

A completion report alone must not be treated as conclusive when current tests, configuration, documentation, or repository behavior contradict it. Dependency handling must not become an implicit authorization to implement a different phase.

## 3.7 Architecture Notes

Architecture notes connect the prompt to approved system direction without duplicating the complete architecture baseline. They should identify the boundaries and decisions that materially constrain the assignment, such as ownership, dependency direction, separation of concerns, interoperability, compatibility, security, isolation, observability, and operational responsibilities.

Architecture notes must:

- Reference authoritative architecture documents and applicable decisions.
- Distinguish established decisions from assumptions.
- Identify when a material deviation requires an Architecture Decision Record.
- Avoid creating a second, conflicting architecture source.
- Remain technology-neutral when the phase is itself a planning activity.

## 3.8 Implementation Workflow

The workflow section defines the controlled sequence the AI executor must follow. It should cover repository inspection, mandatory reading, dependency verification, planning against acceptance criteria, architecture validation, execution order, verification, documentation, completion reporting, and stopping.

The workflow should define necessary sequencing without micromanaging incidental steps. It must allow the executor to make local, reversible decisions within approved standards while preventing unreviewed changes to scope, architecture, or business intent.

## 3.9 Coding and Engineering Standards

An implementation prompt must reference the approved coding, naming, repository, security, testing, documentation, and operational standards that apply. Where phase-specific emphasis is needed, the prompt may restate a concise constraint, but it should not duplicate central standards unnecessarily.

This section should address, at the level appropriate to the assignment:

- Repository and module boundaries.
- Language and tooling conventions.
- Maintainability and separation of responsibilities.
- Validation and error-handling expectations.
- Security, privacy, and isolation.
- Compatibility and controlled evolution.
- Observability and operational support.
- Preservation of unrelated work.
- Prohibition of shortcuts that weaken quality gates.

## 3.10 Testing Requirements

Testing requirements define the evidence needed to establish that the phase behaves as intended and has not damaged established behavior. They must be proportionate to risk and should identify applicable test levels, negative cases, boundary conditions, integrations, security conditions, recovery behavior, and regression coverage.

Prompts must require honest reporting of exact validation outcomes. A test or gate that was not run, could not run, or failed must never be represented as passed.

## 3.11 Documentation Requirements

The prompt must define which documentation needs to be created or updated and the audience it must serve. Applicable documentation can include implementation notes, architecture decisions, operating guidance, repository guides, validation evidence, assumptions, migration notes, and completion reports.

Documentation requirements must insist that:

- Descriptions match actual completed behavior.
- Implemented, deferred, and proposed work are clearly distinguished.
- Material assumptions and decisions are recorded.
- References use accurate repository-relative paths.
- No secrets or sensitive production information are included.
- Repeated content does not create conflicting sources of truth.

## 3.12 Deliverables

Deliverables are the concrete outputs the phase is expected to produce. Each deliverable must be:

- Within the approved scope.
- Traceable to the objective.
- Verifiable through one or more acceptance criteria.
- Specific enough to identify when it is absent or incomplete.
- Free from vague terms such as “appropriate updates” unless the affected artifact class is clearly defined.

Deliverables should describe results, not merely actions performed during execution.

## 3.13 Acceptance Criteria

Acceptance criteria are the objective conditions that must be satisfied before completion can be declared. Each criterion should:

- State an observable result.
- Be objectively verifiable.
- Identify or imply the expected evidence.
- Cover success and material prohibited outcomes.
- Trace to the objective, scope, deliverables, quality requirements, or risk controls.
- Avoid subjective language such as “good,” “clean,” or “works correctly” without a defined measure.

The full set of criteria must cover functional outcome, scope control, architecture alignment, required quality gates, documentation accuracy, and completion-report integrity.

## 3.14 Completion Instructions

Completion instructions must direct the executor to:

1. Review the final result and repository diff.
2. Map each acceptance criterion to factual evidence.
3. Run the required validation and record exact outcomes.
4. Identify files or artifacts created, modified, or intentionally left unchanged.
5. Record decisions, assumptions, deviations, limitations, and pending external gates.
6. Update only the completion report associated with the assigned phase.
7. Avoid claiming unverified work as complete.
8. Stop after the assigned phase and avoid beginning successor work.

# 4. Prompt Lifecycle

## 4.1 Planning

Prompt planning begins with approved business intent, roadmap placement, architecture, risk, dependency order, and expected delivery evidence. The author determines whether a new prompt is needed, which category applies, and how narrowly the assignment can be bounded while still producing a coherent outcome.

Planning should identify stakeholders, reviewers, direct dependencies, governing documents, completion evidence, and likely ambiguity before detailed authoring begins.

## 4.2 Creation

During creation, the author uses the standard prompt architecture and approved terminology. The first draft must be based on repository evidence and current authoritative documents rather than memory or assumptions.

The author should build traceability from objective to scope, tasks, deliverables, acceptance criteria, and completion evidence. Any unresolved point must be labeled and resolved before approval; it must not remain as a hidden assumption or placeholder.

## 4.3 Review

Review determines whether the prompt is complete, accurate, bounded, internally consistent, architecturally aligned, and executable. Reviewers examine dependencies, authority, documentation references, quality requirements, expected outputs, and stopping instructions.

Material findings are documented and returned to the author. Editorial improvements may be resolved directly, while scope, business, security, or architecture changes require the appropriate authority.

## 4.4 Approval

Approval confirms that the prompt is authorized for its intended use. An approved prompt must have:

- A stable identity and repository location.
- No unresolved critical review findings.
- No placeholders or incomplete mandatory sections.
- Confirmed scope and dependency order.
- Objective acceptance criteria and completion instructions.
- A version-controlled approval history.

Approval does not guarantee that every execution dependency is available. The executor must still verify dependency readiness at run time.

## 4.5 Execution

Execution begins only from an approved prompt. The AI tool establishes the current repository context, reads required sources, verifies dependencies, validates architecture, plans against acceptance criteria, and performs only the authorized work.

Material conflicts, missing authority, or unsafe ambiguity are handled using the prompt's escalation rules. The executor must not resolve such issues by inventing product behavior or broadening scope.

## 4.6 Validation

Validation compares actual outcomes against the prompt, approved architecture, established standards, and current repository evidence. It includes required automated checks, targeted inspection, documentation review, security and isolation review where applicable, and confirmation that no prohibited scope was introduced.

Validation evidence must be reproducible and honestly categorized as passed, failed, unavailable, skipped, or externally blocked.

## 4.7 Completion Reporting

The completion report is the factual record of execution. It should state:

- What was completed.
- What evidence was reviewed or produced.
- Which validation was performed and its exact outcome.
- Which artifacts changed.
- Which decisions or assumptions were material.
- Which limitations, deviations, failures, or external gates remain.
- What downstream work may rely on the result.

The report must not repeat future instructions or convert incomplete work into a success claim.

## 4.8 Maintenance

Prompts must be maintained as authoritative inputs, architecture, repository structure, dependencies, tooling, risks, and governance standards evolve. Maintenance includes fixing broken links, updating terminology, resolving newly identified ambiguity, and applying lessons from execution or audit findings.

Changes should be made at the narrowest correct level: central standards for library-wide rules, category templates for repeated patterns, and individual prompts for phase-specific corrections.

## 4.9 Future Updates and Retirement

Material changes to an approved or executed prompt require impact assessment. The project must determine whether the change:

- Clarifies existing intent without changing scope.
- Corrects an error before execution.
- Requires reapproval.
- Requires corrective work or a new phase.
- Supersedes the prompt.

Superseded prompts should remain traceable through version control and should point to their replacement. Historical completion reports must remain factual to the work that was actually performed.

# 5. Prompt Categories

## 5.1 Planning Prompts

Planning prompts organize and refine business goals, scope, stakeholders, constraints, risks, roadmap placement, and expected planning outputs. They produce planning knowledge, not implementation. They must distinguish approved facts from proposals and avoid silently creating technical or product commitments.

## 5.2 Architecture Prompts

Architecture prompts support analysis and documentation of system structure, ownership, boundaries, quality attributes, trade-offs, and decisions. They must require alignment with existing architecture and the Architecture Decision Record process. They do not authorize implementation unless paired with a separately approved implementation scope.

## 5.3 Implementation Prompts

Implementation prompts are controlled execution guides for one approved phase. They contain the complete architecture described in Section 3 and define scope, dependencies, standards, validation, deliverables, acceptance criteria, reporting, and a strict stopping point.

## 5.4 Testing Prompts

Testing prompts direct the design, execution, review, or improvement of validation activities. They define the subject under test, required environments or evidence, risk coverage, test levels, success and failure reporting, and constraints on modifying production behavior.

Testing prompts must not authorize feature expansion merely to make a test pass. Defects should be reported or corrected only within explicitly approved authority.

## 5.5 Deployment Prompts

Deployment prompts govern release preparation, environment verification, rollout, configuration review, operational validation, rollback readiness, and evidence collection. They must clearly distinguish planning, dry-run, non-production, and production authority.

Because deployment can create external effects, these prompts require explicit environment identification, approval boundaries, secret-handling rules, failure conditions, and stopping or rollback instructions.

## 5.6 Audit Prompts

Audit prompts evaluate plans, prompts, architecture, implementation evidence, security posture, documentation, or release readiness against defined criteria. They are read-only unless a separate remediation scope is explicitly authorized.

Findings must be evidence-based, prioritized by impact, traceable to the evaluated requirement, and clear about uncertainty. Audits must not rewrite history or treat absence of evidence as proof of success.

## 5.7 Documentation Prompts

Documentation prompts create, restructure, or validate project documentation. They define the audience, authoritative inputs, allowed document scope, required structure, terminology, linkage, and review criteria.

They must prevent invented implementation claims, stale duplication, disclosure of sensitive information, and unauthorized expansion into implementation work.

## 5.8 Completion Prompts

Completion prompts or completion instructions standardize how execution results are reported. They require a factual status, evidence mapping, changed-artifact inventory, validation outcomes, decisions, limitations, and follow-up boundaries.

A completion prompt must never encourage an AI tool to declare success based solely on task effort or to hide failed and unavailable checks.

## 5.9 Category Selection

A prompt should have one primary category. Related concerns can be included when necessary, but combining materially different authorities in one prompt should be avoided. For example, an audit with permission to remediate should clearly separate the read-only assessment stage from the approved correction stage.

# 6. Prompt Writing Standards

## 6.1 Writing Style

Prompts must use professional, direct, and neutral language. Instructions should be written as explicit requirements using consistent verbs such as “inspect,” “verify,” “document,” “validate,” “report,” and “stop.”

Writers should:

- Prefer short, complete sentences for requirements.
- Use explanatory paragraphs for rationale and bullet points for grouped controls.
- Avoid conversational filler, motivational language, and unnecessary repetition.
- Avoid vague intensifiers such as “properly,” “fully,” or “correctly” unless the expected condition is defined.
- Separate requirements from guidance and examples.
- State prohibitions directly where risk justifies them.

## 6.2 Formatting

Prompts should use:

- One clear title.
- Numbered major sections where the document is long or governed.
- Descriptive subheadings.
- Bullets for parallel requirements.
- Numbered lists for required sequences.
- Tables only when they improve comparison or traceability.
- Checklists for approval or acceptance gates, not as a substitute for explanation.

Heading levels must be consistent. Empty headings, duplicated sections, decorative formatting, and excessively nested lists should be avoided.

## 6.3 Clarity and Precision

Every instruction must answer the relevant questions of who or what acts, what outcome is required, which boundaries apply, which evidence is expected, and when execution ends.

Terms such as “relevant,” “appropriate,” “necessary,” and “as needed” should be used only when the prompt gives the executor an objective rule for determining relevance or necessity.

## 6.4 Terminology

Prompt terminology must match the approved project glossary, roadmap, architecture, repository names, and phase catalog. A single concept should use one canonical term throughout the library.

Legacy names may be retained for file compatibility, but the canonical identity must be stated. Abbreviations should be defined on first use unless they are established project terms.

## 6.5 Scope Definition

Scope must be expressed positively and negatively:

- Positive scope states what the executor is authorized and required to address.
- Negative scope identifies adjacent or tempting work that must not be performed.
- Conditional scope identifies actions permitted only when a stated condition is met.

The prompt must not rely on phrases such as “anything else required” because they create uncontrolled authority.

## 6.6 Assumptions and Unknowns

Known assumptions must be stated, limited, and traceable to their source. The prompt must distinguish:

- Verified facts.
- Approved constraints.
- Working assumptions that are safe and reversible.
- Material unknowns that require a decision or escalation.

Prompts must never instruct an AI tool to guess missing business rules, security policy, architecture authority, production credentials, or approval.

## 6.7 Dependency Handling

Dependencies must be named and accompanied by a verification method and failure policy. The prompt should not merely say “ensure dependencies are complete.”

Where narrow dependency correction is allowed, the allowed extent and reporting requirement must be explicit. Otherwise, incomplete prerequisites must be recorded and escalated.

## 6.8 Expected Outputs

Expected outputs must be concrete, bounded, and mapped to deliverables. The prompt should specify:

- Required artifact types.
- Required locations or naming rules where governed.
- Required evidence or reporting.
- Whether modification, creation, review, or recommendation is authorized.
- What must not be produced.

An output list must not imply implementation authority in a planning-only or audit-only prompt.

## 6.9 AI Instruction Standards

Instructions intended for AI tools must:

- Establish the repository or document set as the working context.
- Require inspection before modification.
- Define authoritative sources and conflict handling.
- Require preservation of unrelated work.
- Prohibit unsupported scope and fabricated evidence.
- Require verification before claims of completion.
- Identify conditions that require escalation.
- Include an explicit stopping condition.

Tool-specific wording should be minimized unless a specific capability or operational control depends on it. Prompts should remain portable across approved tools wherever practical.

## 6.10 Self-Containment Without Duplication

A self-contained prompt includes enough context and references to execute its assignment without avoidable clarification. It does not need to reproduce every project standard. Central policies should be linked, with concise phase-specific constraints included only where they materially affect execution.

# 7. Prompt Execution Workflow

## 7.1 Establish Context

The implementation AI confirms:

- The approved prompt and canonical phase identity.
- The repository root and current working state.
- The assigned completion report.
- The authorized scope and explicit exclusions.
- Any user-provided additions that lawfully refine the assignment.

The AI must inspect current changes before acting so that unrelated or concurrent work is preserved.

## 7.2 Perform Repository Analysis

Before implementation, the AI analyzes the current repository structure, applicable applications and packages, documentation, decisions, manifests, tests, and affected history. The objective is to understand the existing system rather than assume that a prompt describes the repository perfectly.

Repository analysis should identify:

- Existing capability and ownership boundaries.
- Current conventions and reusable patterns.
- Uncommitted or unrelated changes.
- Evidence of predecessor work.
- Conflicts between documented intent and actual state.
- Relevant quality gates and execution commands.

## 7.3 Complete Mandatory Reading

All mandatory material identified by the prompt must be read before changes begin. The AI should also read local documentation in any area it is authorized to touch.

Reading is not a ceremonial checklist. The AI must apply the sources when planning, identify conflicts, and use the documented precedence or escalation rules.

## 7.4 Verify Dependencies

The AI verifies direct prerequisites through current evidence. Verification may include approved decisions, repository artifacts, configuration, test results, completion reports, and other observable state identified by the prompt.

If a dependency is incomplete, the AI follows the prompt's policy. It must not conceal the issue, assume success, or perform broad predecessor work without authorization.

## 7.5 Validate Architecture

Before making changes, the AI confirms that the planned work respects:

- Approved responsibility and ownership.
- Module and repository boundaries.
- Dependency direction.
- Security, privacy, tenant, and branch boundaries where applicable.
- Compatibility and evolution policies.
- Documentation and decision-record requirements.

A material deviation must be stopped, escalated, or documented through the authorized decision process before implementation proceeds.

## 7.6 Plan the Implementation Sequence

The AI creates a working sequence mapped to acceptance criteria. The sequence should begin with the highest-risk uncertainties and prerequisite validation, then proceed through bounded changes, targeted verification, integration verification, documentation, and final review.

The working plan is an execution aid and does not expand prompt authority.

## 7.7 Execute Incrementally

The AI works in small, reviewable increments and verifies important assumptions early. It reuses established patterns and preserves repository consistency.

During execution, the AI must:

- Remain within the assigned phase.
- Avoid speculative features and broad unrelated refactoring.
- Preserve previous work unless replacement is explicitly authorized.
- Record material assumptions and decisions.
- Avoid placeholders, simulated success, and knowingly incomplete paths.
- Reassess the plan when verified repository evidence contradicts it.

## 7.8 Test and Validate

The AI runs the checks required by the prompt and applicable repository standards. It reviews both positive results and material failure paths. Validation should cover the assigned outcome, regressions, architecture, security, isolation, documentation, and scope as appropriate.

Exact commands or review methods and outcomes must be retained for completion reporting. Failures must be investigated within scope and disclosed when unresolved.

## 7.9 Update Documentation

Documentation is updated to describe actual completed behavior and decisions. Proposed or deferred work must not be presented as implemented.

The AI updates only documentation within the assigned scope and avoids duplicating authoritative sources. Material architecture decisions use the approved Architecture Decision Record process.

## 7.10 Produce the Completion Report

The AI maps every acceptance criterion to evidence and updates the corresponding completion report. It lists changed artifacts accurately and discloses limitations, skipped checks, external dependencies, and pending approvals.

## 7.11 Stop at the Assigned Phase

After the assigned deliverables, validation, documentation, and completion report are accurate, execution stops. The AI must not start the next phase, prebuild later functionality, or modify another phase's completion report.

# 8. Prompt Validation

## 8.1 Validation Purpose

Prompt validation detects defects before the prompt directs repository work. It determines whether the prompt is understandable, authorized, complete, architecture-aligned, dependency-aware, objectively verifiable, and safe to execute.

## 8.2 Completeness Validation

Reviewers confirm that:

- All mandatory prompt-architecture sections are present.
- The objective, scope, exclusions, workflow, deliverables, acceptance criteria, and completion instructions agree.
- No heading is empty.
- No placeholder, TODO, unresolved drafting note, or implied future addition remains.
- Mandatory reading and expected documentation are identified.
- The stopping condition is explicit.

## 8.3 Dependency Validation

Reviewers verify that:

- Each direct dependency is real and necessary.
- Dependency order matches the approved roadmap.
- Readiness can be established through named evidence.
- The missing-dependency policy is safe and unambiguous.
- No circular or hidden future dependency exists.
- The prompt does not rely on an unverified environment, approval, service, or credential.

## 8.4 Architectural Consistency Validation

The prompt is compared with approved architecture, decisions, ownership boundaries, and repository conventions. Reviewers check for duplicated ownership, incorrect dependency direction, cross-boundary authority, unapproved technology choices, and conflicting sources of truth.

Material architecture conflicts must be resolved before approval.

## 8.5 Documentation Quality Validation

Reviewers confirm that document references exist, paths and names are correct, required audiences are addressed, and expected updates do not duplicate or contradict authoritative sources. They also verify that documentation requirements distinguish actual behavior from planned behavior.

## 8.6 Scope Verification

The prompt is compared with its roadmap phase and neighboring prompts to confirm:

- Required work is included.
- Adjacent work is not duplicated.
- Later-phase work is excluded.
- Corrective authority is explicitly bounded.
- The phase can produce a coherent outcome without unauthorized expansion.
- No instruction grants open-ended authority.

## 8.7 Acceptance-Criteria Validation

Each criterion is reviewed for:

- Objective wording.
- Traceability to a requirement, deliverable, risk, or exclusion.
- A practical evidence method.
- Coverage of material negative outcomes.
- Consistency with the defined scope.

The criteria set must be sufficient to reject an incomplete result even if most tasks were attempted.

## 8.8 Expected-Output Validation

Reviewers confirm that every expected output:

- Belongs to the prompt category and authorized scope.
- Has a clear artifact type or reporting form.
- Can be located and evaluated.
- Does not imply unsupported implementation authority.
- Is represented in the deliverables and acceptance criteria.

## 8.9 Approval Gate

A prompt is approved only when critical ambiguity is eliminated, required reviews pass, references are valid, dependencies and scope are coherent, acceptance criteria are objective, and no placeholders or contradictions remain.

Rejected prompts return to authoring with documented findings. Approval status and material revisions must be visible in version control.

# 9. Prompt Quality Standards

## 9.1 Enterprise Readiness

An enterprise-ready prompt supports governed work in a long-lived, multi-team ERP program. It accounts for traceability, review, dependency order, security, documentation, operational evidence, and handover. It is not written as an isolated one-time request.

## 9.2 Production Readiness

An implementation prompt must direct the executor toward complete and supportable outcomes rather than demonstrations or prototypes, unless the approved phase is explicitly exploratory. It must address applicable validation, failure behavior, compatibility, security, documentation, and operational readiness.

## 9.3 Scalability

Prompt structure and expectations should remain usable as the repository, team, user base, and integration landscape grow. Prompts should reinforce modularity, explicit ownership, stable contracts, dependency discipline, and maintainable documentation.

## 9.4 Maintainability

A maintainable prompt has a stable identity, predictable structure, consistent terminology, minimal duplication, accurate references, and clear version history. Future maintainers should be able to understand why it exists, what it authorizes, and how it relates to other prompts.

## 9.5 Security Awareness

Prompts must include security and privacy requirements proportionate to their scope. They should direct attention to least privilege, isolation, sensitive information, validation, auditability, external effects, and safe failure behavior without inventing security rules absent from approved policy.

Planning, documentation, and audit prompts must also avoid exposing credentials, sensitive production information, or unsafe operational instructions.

## 9.6 Self-Contained Documentation

Every prompt must be complete enough to execute when combined with its referenced authoritative sources. Required context, authority, dependencies, decision rules, outputs, validation, and stopping conditions must be discoverable from the prompt.

## 9.7 Consistency

The prompt must be internally consistent and consistent with the roadmap, architecture, standards, repository structure, and neighboring phases. Phase identity, file references, terminology, dependencies, and expected evidence must agree.

## 9.8 Removal of Ambiguity and Incompleteness

Approved prompts must not contain:

- Placeholders or TODO markers.
- Empty or unfinished sections.
- Conflicting requirements.
- Unsupported assumptions.
- Vague acceptance criteria.
- Unresolved phase or artifact names.
- Instructions to “fill in later.”
- Ellipses standing in for requirements.
- Claims about unavailable evidence.

Where genuine uncertainty cannot be removed, the prompt must define a clear escalation or blocking condition.

## 9.9 Verifiability

Quality requirements must be expressed in observable terms. A prompt must define how its outcomes will be evaluated and must prevent the executor from treating confidence, generated volume, or task activity as evidence of success.

# 10. Prompt Library Organization

## 10.1 Repository Structure

The prompt library uses the existing planning structure:

| Repository location | Responsibility |
|---|---|
| `ERP-PLANNING/prompt-engineering/` | Prompt Engineering methodology, quality standards, validation, and maintenance guidance |
| `ERP-PLANNING/implementation-prompts/` | Implementation-prompt framework, strategy, and governance |
| `ERP-PLANNING/phase-prompts/` | Approved phase-level execution prompts and reusable phase-audit instructions |
| `ERP-PLANNING/phase-completions/` | Factual completion evidence corresponding to executed phases |
| `ERP-PLANNING/templates/` | Approved reusable documentation structures where maintained |
| `docs/architecture-decision-records/` | Material architecture decisions and the approved decision template |

New prompt-related folders should not be created when an established location already serves the purpose.

## 10.2 Naming Conventions

Prompt names must:

- Use the canonical phase number and descriptive phase name.
- Follow the established uppercase phase-file convention where applicable.
- Use stable, readable words rather than temporary labels.
- Make the relationship between a phase prompt and completion report clear.
- Preserve a legacy filename when renaming would damage traceability, while stating the canonical identity inside the document.

Catalogs, links, titles, and reports must use the same canonical identity.

## 10.3 Relationships and Traceability

Each implementation prompt should identify:

- Governing planning and architecture sources.
- Direct predecessor prompts and completion evidence.
- Its matching completion report.
- Decisions or standards that constrain execution.
- Downstream phases that rely on its output when relevant to compatibility.

Cross-references should establish traceability without copying entire documents. A later prompt must verify predecessor evidence rather than assuming that a cross-reference proves readiness.

## 10.4 Version Control

All prompt documents must be version-controlled. A material change should make clear:

- Why the prompt changed.
- Whether the change is editorial, clarifying, corrective, or scope-affecting.
- Which requirement, decision, audit finding, or repository change prompted it.
- Whether the prompt requires renewed review or approval.
- Whether an already completed phase is affected.

Historical evidence must be preserved. Prompt changes must not rewrite a completion report to imply that earlier work satisfied requirements that did not exist at the time.

## 10.5 Update Strategy

Updates should be applied at the narrowest authoritative location:

- Library-wide methodology changes belong in this guide.
- Implementation governance changes belong in the implementation-prompt framework.
- Category-wide repeated structures belong in an approved template.
- Phase-specific details belong in the relevant phase prompt.
- Material architecture choices belong in an Architecture Decision Record.

After an update, maintainers should review inbound and outbound links, catalogs, dependent prompts, and affected completion guidance.

## 10.6 Maintenance Practices

The library should be reviewed:

- Before a prompt is approved.
- When roadmap or architecture decisions change.
- When repository paths or conventions change.
- After recurring execution misunderstandings.
- After audit findings.
- Before major release or governance gates.

Maintenance includes removing stale references, reconciling terminology, documenting legacy names, eliminating duplication, and ensuring that prompt status remains visible.

# 11. AI Collaboration Guidelines

## 11.1 Common Interpretation Standard

Claude Code, Codex, ChatGPT, and other approved AI tools must interpret a prompt as a bounded execution contract. They must apply the same objective, scope, repository evidence, architecture rules, quality gates, and reporting standard regardless of differences in tool capability.

## 11.2 Repository Consistency

AI tools must inspect existing structure and conventions before proposing or making changes. They should reuse established patterns where those patterns remain authoritative and should avoid creating parallel structures, duplicate concepts, or conflicting documentation.

When prompt prose conflicts with newer verified repository evidence, the tool must follow the stated precedence and escalation rules. It must not silently choose the interpretation that is easiest to implement.

## 11.3 Preservation of Previous Work

AI tools must preserve:

- Unrelated user or contributor changes.
- Valid behavior established by earlier phases.
- Historical evidence and decision records.
- Repository organization unless change is explicitly authorized.
- Public or shared expectations governed by approved compatibility rules.

Previous work should be modified only when the assigned scope requires it or when a narrowly authorized dependency correction is necessary and documented.

## 11.4 Respect for Module and Ownership Boundaries

An AI tool must not bypass approved ownership or implement cross-module behavior merely because it can access the full repository. It should follow established responsibility, dependency, integration, and documentation boundaries.

Discovering an opportunity for broader cleanup or enhancement does not create authority to perform it. The opportunity may be reported as a recommendation when useful.

## 11.5 Scope Discipline

AI tools must:

- Implement only the assigned phase.
- Avoid speculative requirements.
- Avoid pre-implementing successor phases.
- Avoid broad refactoring unrelated to acceptance.
- Avoid altering external systems or production state without explicit authority.
- Stop when the assigned completion conditions are met.

## 11.6 Evidence and Honesty

AI tools must distinguish observed evidence from inference. They must not fabricate:

- Test results.
- Repository files or behavior.
- Approvals.
- External-system state.
- Completed dependencies.
- Measurements.
- User decisions.

Uncertainty, unavailable validation, and external blockers must be reported clearly.

## 11.7 Tool Capability Differences

When an AI tool lacks a required capability, it should complete all safe in-scope work still possible and report the missing capability or external gate. It must not weaken the acceptance standard merely because its toolset differs.

## 11.8 Collaboration and Handover

AI-generated completion reports and documentation must allow another human or AI contributor to understand the outcome without reconstructing the entire execution session. Handover information should emphasize verified state, decisions, limitations, and the next authorized dependency rather than conversational history.

# 12. Documentation Standards

## 12.1 Documentation as Part of Delivery

Prompt-related documentation is a required part of governance, not an optional summary. It preserves intent, authority, decisions, evidence, and operational knowledge across tools, contributors, and time.

## 12.2 Implementation Notes

Implementation notes should record material execution context that is necessary for maintenance or review. They should explain significant constraints, compatibility considerations, or non-obvious outcomes without becoming an unstructured activity log.

Implementation notes must describe actual work and should link to authoritative decisions, tests, or repository locations.

## 12.3 Assumptions

Assumptions must be:

- Explicitly identified.
- Supported by the best available evidence.
- Limited to safe, reversible matters within scope.
- Recorded where future contributors will encounter them.
- Replaced by an approved decision when they become material or long-lived.

Material business, security, or architecture uncertainty must not be hidden as an assumption.

## 12.4 Architecture Decisions and ADRs

An Architecture Decision Record is required when execution introduces or changes a material architectural choice, boundary, dependency direction, compatibility strategy, or operational constraint.

The ADR should record context, considered options, decision, rationale, consequences, migration or compatibility effects, and reversal considerations. The prompt and completion report should link to it rather than duplicate the full decision.

## 12.5 Completion Reports

Completion reports must include:

- Phase identity and status.
- Scope actually completed.
- Deliverables and acceptance mapping.
- Files or artifacts created and modified.
- Validation methods and exact results.
- Decisions and assumptions.
- Deviations from the prompt.
- Known limitations and pending work.
- External gates and ownership of the next action where known.

Reports must use factual past tense and must not retain authoring instructions, placeholders, or unsupported success claims.

## 12.6 Repository Documentation Updates

Repository guides, indexes, catalogs, and affected area documentation must be updated when a phase changes the information they govern. Documentation should be linked rather than copied when a central source exists.

All repository paths must be accurate, examples must be synthetic and safe, and implemented behavior must be clearly separated from future plans.

## 12.7 Documentation Review

Documentation review confirms accuracy, audience fit, consistency, traceability, absence of sensitive information, and removal of stale or duplicated claims. A phase is not documentation-complete merely because a file was changed; the resulting guidance must match verified reality.

# 13. Common Prompt Design Principles

## 13.1 Modularity

Each prompt should address one coherent outcome with clear boundaries. Large assignments should be divided according to roadmap, architecture, dependency, and validation boundaries rather than arbitrary document length.

Modularity improves review, rollback, evidence quality, handover, and scope control.

## 13.2 Clarity

Prompts should make purpose, authority, requirements, exclusions, evidence, and stopping conditions immediately discoverable. Requirements must not depend on implied context or private author knowledge.

## 13.3 Dependency Management

Dependencies should be minimized, explicit, ordered, and verified. A prompt must identify both what it requires and how it responds when the requirement is absent.

Prompt authors should avoid circular sequencing and hidden reliance on future work.

## 13.4 Incremental Development

Prompts should direct work through small, coherent, verifiable increments. High-risk assumptions and dependencies should be checked before expensive or broad execution.

Incremental work does not mean accepting incomplete production paths. Every phase must still finish at a coherent, approved boundary.

## 13.5 Verification-First Execution

Verification begins before implementation through repository analysis and dependency checks. Acceptance criteria are planned before changes, important assumptions are tested early, and final claims are supported by evidence.

The guiding principle is that generation produces a candidate result; verification establishes whether the result is acceptable.

## 13.6 Documentation-Driven Development

Approved plans, architecture, decisions, prompts, and completion evidence guide implementation. Documentation is updated as part of the same phase so that future contributors do not depend on conversational memory.

Documentation-driven development must not become document duplication. Each subject should have a clear authoritative source.

## 13.7 Explicit Negative Boundaries

Prompts should identify prohibited outcomes when their risk is material. Clear exclusions are especially important for later-phase work, destructive actions, external effects, broad refactoring, unsupported business behavior, and bypassing quality controls.

## 13.8 Evidence-Based Completion

Task execution, file creation, or AI confidence is not completion. Completion exists only when deliverables and acceptance criteria are supported by factual evidence and limitations are disclosed.

## 13.9 Least Necessary Authority

Every prompt should grant only the authority required to achieve its objective. Read-only reviews should remain read-only; planning prompts should not imply implementation; implementation prompts should not imply deployment; and phase scope should not imply program-wide remediation.

# 14. Risks and Limitations

## 14.1 Ambiguous Instructions

Ambiguous wording can cause different tools to produce inconsistent outcomes or make unsafe assumptions.

Mitigation includes:

- Use explicit objectives, scope, exclusions, and terminology.
- Replace subjective requirements with observable criteria.
- Define conflict and escalation rules.
- Validate the prompt with a reviewer before approval.

## 14.2 Scope Creep

An AI tool may interpret related improvements as part of the assignment, especially when the repository exposes adjacent work.

Mitigation includes:

- Define positive and negative scope.
- Restrict dependency repair.
- Require preservation of unrelated work.
- Add a phase-specific stopping condition.
- Review the final diff against authorized scope.

## 14.3 Inconsistent Architecture

Prompts written without current architecture context can introduce duplicate ownership, conflicting patterns, or unsafe dependencies.

Mitigation includes:

- Reference authoritative architecture and decisions.
- Require repository analysis and architecture validation before execution.
- Route material deviations through an ADR and approval process.
- Include architecture consistency in acceptance and review.

## 14.4 Duplicated Implementations or Documentation

Failure to inspect existing work can create parallel capabilities, redundant abstractions, or competing sources of truth.

Mitigation includes:

- Require existing-state analysis.
- Prefer established patterns and central documentation.
- Validate ownership and repository placement.
- Review for duplication before completion.

## 14.5 Missing or Incorrect Dependencies

Unverified prerequisites can lead to rework, temporary workarounds, or invalid completion claims.

Mitigation includes:

- Name direct dependencies and readiness evidence.
- Verify current state rather than relying only on prior reports.
- Define a safe missing-dependency policy.
- Prevent automatic expansion into predecessor or future phases.

## 14.6 Undocumented Assumptions

Hidden assumptions can become permanent business or architecture decisions without review.

Mitigation includes:

- Separate facts, constraints, assumptions, and unknowns.
- Record material assumptions in completion documentation.
- Require an ADR or authority for long-lived material decisions.
- Escalate missing business, security, or architecture choices.

## 14.7 Prompt Drift

Prompts can become stale as the roadmap, repository, architecture, tooling, or standards change.

Mitigation includes:

- Review prompts at lifecycle gates.
- Version all changes.
- Maintain cross-references and catalogs.
- Apply updates at the correct authoritative level.
- Mark superseded prompts clearly.

## 14.8 Tool Interpretation Differences

Different AI tools may vary in context capacity, repository access, execution capabilities, or how they interpret prose.

Mitigation includes:

- Use a stable prompt architecture and canonical terminology.
- Keep critical constraints explicit.
- Minimize unnecessary tool-specific instructions.
- Require the same evidence and reporting standard across tools.
- Report unavailable capabilities instead of lowering quality criteria.

## 14.9 False Completion

An AI tool may present attempted work, partial validation, or inferred state as complete.

Mitigation includes:

- Use objective acceptance criteria.
- Require exact validation outcomes.
- Require artifact inventories and evidence mapping.
- Distinguish passed, failed, skipped, unavailable, and blocked checks.
- Review completion reports against repository evidence.

## 14.10 Excessive Prompt Size

An overly large prompt can hide priorities, duplicate central standards, and make contradictions harder to detect.

Mitigation includes:

- Keep one coherent objective per prompt.
- Link authoritative standards instead of copying them wholesale.
- Use structured headings and traceability.
- Include only relevant mandatory reading.
- Move reusable governance to central guidance.

## 14.11 Limitations of Prompt Engineering

Prompt Engineering improves control but does not eliminate the need for:

- Approved business requirements.
- Architecture governance.
- Human accountability and review.
- Secure access controls.
- Reliable automated testing.
- Production change management.
- Independent security, compliance, or operational assurance where required.

A well-written prompt cannot compensate for missing authority, inaccurate source material, unavailable environments, or an inherently unsafe project decision. It must expose these conditions rather than conceal them.

# 15. Expected Outcome

The expected result of Prompt Engineering is a governed prompt library in which every implementation prompt is a complete, self-contained, enterprise-grade execution guide for one approved phase of the Nexoraa CleanSoft ERP.

Each prompt should enable an approved AI development tool to:

- Understand the assigned outcome and business context.
- Locate and apply the authoritative project sources.
- Verify dependencies and the current repository state.
- Preserve architecture, security, ownership, and module boundaries.
- Execute only the authorized phase.
- Produce the required deliverables and documentation.
- Validate the outcome through objective evidence.
- Report completion, limitations, and external gates honestly.
- Stop without requiring avoidable clarification or beginning later work.

The resulting methodology provides consistent instructions across Claude Code, Codex, ChatGPT, and other approved tools while preserving human governance and project accountability. It supports accurate, maintainable, scalable, secure, and repeatable AI-assisted development throughout the ERP lifecycle.

This guide remains a planning and documentation standard. It defines how implementation prompts must be engineered; it does not itself authorize or specify any implementation.

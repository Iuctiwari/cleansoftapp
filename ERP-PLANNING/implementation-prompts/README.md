# Nexoraa CleanSoft ERP Implementation Prompt Framework

## Document Purpose

This document is the master planning and governance guide for the Nexoraa CleanSoft ERP implementation prompt library. It defines how implementation prompts are designed, organized, reviewed, executed, validated, and maintained across the project.

It is not an implementation prompt for a module or development phase. It does not authorize source-code changes and does not define module-specific business logic. Future prompt authors, reviewers, maintainers, and AI-assisted development tools must use this framework together with the approved project planning documents and repository evidence.

## Governing Principles

- The repository is the authoritative source for current project structure, approved decisions, completed work, and executable evidence.
- Each implementation phase has one clearly identified prompt and one corresponding completion report.
- Prompts must be sufficiently complete to execute without avoidable clarification while remaining limited to their approved phase.
- Architecture, security, tenant isolation, branch boundaries, data ownership, testing, and operational readiness are requirements throughout the library rather than optional additions.
- A phase is not complete until its results are validated and its completion report contains factual evidence.
- Execution stops at the boundary of the assigned phase. A later phase never starts automatically.

# 1. Introduction

## 1.1 Purpose of Implementation Prompts

Implementation prompts translate approved product plans, architecture decisions, roadmap phases, and quality policies into controlled instructions for delivery. They establish what an implementation agent must understand, what work is authorized, what work is excluded, which dependencies must already exist, how the result must be verified, and what evidence must be recorded.

A prompt is therefore more than a task description. It is an execution contract between project governance and the implementation agent. It provides a repeatable bridge from planning to delivery without replacing the approved architecture, roadmap, or business requirements.

## 1.2 Why Prompt-Driven Development Is Used

Nexoraa CleanSoft uses prompt-driven development to coordinate complex, multi-phase work performed with AI-assisted engineering tools such as Claude Code or Codex. The approach makes project intent explicit before implementation begins and allows every phase to be assessed against the same standards.

Prompt-driven development supports the project by:

- Converting broad roadmap objectives into bounded, executable assignments.
- Giving implementation agents the business, architecture, dependency, security, and quality context needed for sound decisions.
- Reducing inconsistent interpretations across modules, services, applications, and development sessions.
- Creating a reviewable record of the instructions that produced each phase.
- Making acceptance and completion evidence part of the delivery process.
- Preventing accidental expansion into later phases or unrelated product scope.

## 1.3 Value of Standardization

Standardized prompts make delivery more predictable. When prompts use a common hierarchy, vocabulary, evidence model, and completion process, reviewers can identify omissions early and implementation agents can work without repeatedly rediscovering project rules.

This consistency improves:

- **Quality:** Every phase receives explicit requirements for validation, testing, security, documentation, and operational behavior.
- **Maintainability:** Common structure and naming make prompts easier to update, compare, audit, and hand over.
- **Architecture alignment:** Ownership boundaries and approved decisions remain visible throughout implementation.
- **Traceability:** Objectives, tasks, deliverables, acceptance criteria, validation results, and completion evidence can be linked.
- **AI-assisted development:** Tools receive clear constraints, authoritative inputs, expected outputs, and stopping conditions.

# 2. Objectives

## 2.1 Primary Objectives

The implementation prompt library is intended to:

- Standardize how all development phases are described and executed.
- Reduce ambiguity by stating the authorized scope, exclusions, dependencies, constraints, and expected results.
- Preserve consistency with the approved system architecture, repository boundaries, domain ownership, and cross-cutting policies.
- Require production-ready outcomes rather than prototypes, demonstrations, or partially completed paths.
- Support enterprise-scale development through explicit quality gates, dependency sequencing, documentation, and evidence.
- Make each phase independently understandable while preserving the required execution order between phases.
- Provide a stable basis for technical review, audit, change control, and future maintenance.

## 2.2 Supporting Objectives

The library must also:

- Prevent hidden assumptions from becoming undocumented technical or product decisions.
- Ensure that implementation agents inspect existing work before changing it.
- Protect unrelated repository changes and established behavior.
- Require measurable acceptance criteria rather than subjective completion claims.
- Maintain clear relationships between planning sources, executable prompts, decisions, tests, and completion reports.
- Enable safe prompt improvement without silently changing already approved project scope.

## 2.3 Definition of Success

The prompt library succeeds when every approved development phase has a complete, consistent, reviewable prompt that a qualified AI-assisted engineering tool can execute without additional clarification, provided that its documented dependencies and required resources are available.

Independence in this context means that the prompt contains all instructions and references needed to perform its own phase. It does not mean that phases may be executed out of order or without verifying their dependencies.

# 3. Prompt Architecture

## 3.1 Required Document Hierarchy

Every implementation prompt must use a predictable top-down structure:

1. **Identity and execution contract** — phase number, canonical name, purpose, agent responsibility, source-of-truth rule, and stopping condition.
2. **Objective and business context** — the outcome the phase must enable and why it matters.
3. **Scope boundaries** — work included, work excluded, and assumptions that limit interpretation.
4. **Required inputs and dependencies** — mandatory reading, prior completion evidence, repository areas, decisions, and external prerequisites.
5. **Architecture and quality constraints** — ownership, boundaries, compatibility, security, reliability, performance, maintainability, and operational expectations.
6. **Tasks and expected outputs** — ordered work, required documentation, deliverables, and completion artifacts.
7. **Validation and acceptance** — required checks, evidence expectations, measurable acceptance criteria, and review conditions.
8. **Completion instructions** — completion-report update, final review, disclosure of limitations, and an explicit instruction to stop.

The heading names may be refined for a particular category, but the underlying information must remain present and easy to locate.

## 3.2 Mandatory Prompt Sections

An executable implementation prompt must include, when applicable:

- Phase number and canonical phase name.
- Execution contract and repository source-of-truth statement.
- Business objective and intended outcome.
- In-scope and out-of-scope work.
- Mandatory reading and authoritative references.
- Dependencies, prerequisites, and dependency verification rules.
- Architecture and ownership constraints.
- Functional responsibility at an outcome level.
- Non-functional requirements.
- Security, privacy, isolation, audit, and compliance expectations.
- Reliability, performance, scalability, compatibility, and recovery expectations.
- Testing and validation requirements.
- Documentation requirements.
- Ordered tasks.
- Expected deliverables.
- Measurable acceptance criteria.
- Completion-report location and evidence requirements.
- Explicit stop condition.

Sections that genuinely do not apply should explain why. They must not be omitted silently or retained as empty boilerplate.

## 3.3 Formatting Standards

Prompts must use:

- Markdown with one clear document title.
- Numbered primary sections when sequence or traceability matters.
- Descriptive headings and short, focused paragraphs.
- Meaningful bullets for requirements, boundaries, checks, and deliverables.
- Ordered lists for execution sequences.
- Tables only where they improve comparison, ownership mapping, dependencies, or traceability.
- Repository-relative paths using exact capitalization.
- Consistent phase numbers, canonical names, and terminology across all references.
- Checklists for acceptance criteria when each item requires independent verification.

Prompts must not rely on decorative formatting, excessive repetition, unexplained abbreviations, vague emphasis, or large unstructured blocks of instructions.

## 3.4 Writing Style

Prompt language must be direct, professional, testable, and unambiguous. Requirements use terms such as **must**, **must not**, **verify**, **record**, and **stop** when compliance is mandatory. Explanatory text should state intent and decision context without turning the prompt into a design tutorial.

Writers must:

- Prefer specific outcomes over broad requests such as “build,” “improve,” or “handle.”
- Distinguish mandatory requirements from guidance and optional considerations.
- Define specialized terms or link to their authoritative definition.
- Avoid prescribing unsupported product behavior.
- Avoid repeating global rules unless repetition is necessary for safe execution.
- State how uncertainty or conflicting evidence must be resolved.

## 3.5 Module-Specific Organization

Module implementation prompts follow the master structure but organize their requirements around the module’s approved responsibilities. The prompt should identify:

- The business capability owned by the module.
- Its relationship to earlier and later phases.
- Approved ownership and interaction boundaries.
- User-facing, operational, and administrative outcomes that belong to the phase.
- Cross-cutting policies that apply to the module.
- Interfaces or downstream expectations at a documentation and contract level.
- Explicitly deferred capabilities.

Module prompts must not copy generic requirements without adapting them to the module’s actual risks, dependencies, and acceptance evidence.

## 3.6 Expected Outputs

Each prompt must name the categories of output expected from the phase without attempting to pre-write the implementation. Expected outputs may include completed product capabilities, validated configuration, tests, operational documentation, architecture decisions, migration evidence, or a completion report, depending on the phase.

Outputs must be:

- Traceable to the objective and tasks.
- Bounded by the stated scope.
- Verifiable through acceptance criteria.
- Assigned to known repository locations or clearly identified artifact types.
- Described as completed outcomes rather than speculative intentions.

## 3.7 Consistency Guidelines

All prompts must share:

- The same canonical project vocabulary.
- The same phase numbering and sequencing model.
- The same repository source-of-truth principle.
- The same treatment of completion evidence and unresolved limitations.
- Compatible definitions of architecture, security, quality, and production readiness.
- A consistent rule that later-phase work is not started early.

Reusable language may be maintained centrally, but each prompt remains self-contained enough to be executed and reviewed in isolation.

# 4. Prompt Categories

## 4.1 Foundation Prompts

Foundation prompts establish the repository, shared engineering policies, common tooling expectations, and baseline governance needed by all later phases. They define stable project conventions and must avoid introducing module business capabilities prematurely.

## 4.2 Planning Prompts

Planning prompts produce or refine authoritative planning artifacts such as product definition, architecture, data ownership, security strategy, module boundaries, roadmaps, and audit findings. Their outputs are decisions and documentation, not application implementation.

## 4.3 Module Implementation Prompts

Module prompts authorize delivery of one bounded ERP capability. They connect the approved business objective to ownership, dependencies, user outcomes, cross-cutting requirements, tests, documentation, acceptance evidence, and completion reporting. Each module prompt must prevent unauthorized work in adjacent modules.

## 4.4 Testing Prompts

Testing prompts coordinate validation across implemented capabilities. They define test scope, environments, quality gates, risk coverage, evidence, defect handling, and exit criteria. They validate behavior rather than introducing unrelated features under the guise of fixing tests.

## 4.5 Deployment Prompts

Deployment prompts govern environment readiness, release configuration, controlled rollout, verification, rollback readiness, and operational handover. They must identify approvals and external prerequisites and must never represent an unavailable environment or unexecuted deployment as successful.

## 4.6 Documentation Prompts

Documentation prompts create or reconcile user, developer, operator, support, architecture, and release documentation with implemented behavior. They must rely on verified repository and runtime evidence and must not describe planned functionality as delivered.

## 4.7 Audit Prompts

Audit prompts perform an independent conformance review against approved requirements, architecture, security controls, acceptance criteria, and completion evidence. They report findings, severity, ownership, and remediation requirements. Audit prompts do not silently expand scope or convert missing evidence into an assumption of success.

## 4.8 Completion Prompts

Completion prompts or completion instructions close a phase by confirming acceptance evidence, documenting changed artifacts, recording decisions and limitations, and updating only the corresponding completion report. Completion is evidence-based and cannot be declared solely because tasks were attempted.

# 5. Prompt Development Standards

## 5.1 Authoritative Inputs

Before writing a prompt, the author must review the approved business plans, architecture documents, roadmap, prior audits, repository conventions, applicable decisions, and predecessor completion reports. Current repository evidence must be considered so that the prompt does not refer to obsolete paths, superseded decisions, or capabilities that do not exist.

Every prompt must identify the authoritative inputs its executor must read. References should be limited to material that is genuinely necessary while still covering all governing decisions.

## 5.2 Business Context

The prompt must explain the business reason for the phase, the users or operations it supports, and the outcome it must enable. Business context should be sufficient to guide implementation trade-offs without embedding module-specific rules that have not been approved elsewhere.

## 5.3 Scope Definition

Scope must define both inclusion and exclusion:

- **In scope** describes the capabilities, artifacts, integrations, validation, and documentation authorized by the phase.
- **Out of scope** identifies adjacent capabilities, later phases, unsupported variations, and destructive or speculative work that must not be introduced.
- **Assumptions and constraints** state approved limits and explain how unresolved information must be treated.

Scope must be narrow enough to protect phase sequencing and complete enough to deliver a coherent result.

## 5.4 Architecture Requirements

Prompts must identify the architecture principles and approved boundaries that affect the phase. These can include responsibility ownership, separation of concerns, dependency direction, isolation, interoperability, compatibility, observability, and decision-record requirements.

The prompt should tell the executor where authoritative architecture is documented and when a new or changed decision requires formal review. It must not duplicate architecture documents in a way that creates a competing source of truth.

## 5.5 Non-Functional Requirements

Non-functional requirements must be relevant, measurable where possible, and proportionate to the phase. Applicable concerns include:

- Security and privacy.
- Tenant and branch isolation.
- Reliability and recovery.
- Performance and capacity.
- Scalability.
- Accessibility and usability.
- Observability and auditability.
- Localization and consistency of user experience.
- Compatibility and controlled change.
- Maintainability and supportability.

Generic statements such as “make it secure” or “ensure good performance” are insufficient. The prompt must define the expected validation or evidence.

## 5.6 Dependencies

Each dependency must identify:

- The prerequisite phase, artifact, decision, service, environment, or approval.
- Why it is required.
- How its availability or completion is verified.
- What the executor must do if evidence conflicts or the dependency is incomplete.

A completion report alone is not proof when current implementation, tests, configuration, or other verified evidence contradicts it. Dependency repair is permitted only when the prompt explicitly authorizes a narrow corrective action; otherwise the issue must be recorded and escalated.

## 5.7 Documentation Expectations

Prompts must require documentation that matches completed behavior and its intended audience. Documentation requirements should cover the relevant operational, architecture, support, user, validation, and maintenance knowledge needed after handover.

Documentation must:

- Use authoritative links and repository-relative paths.
- Distinguish implemented behavior from deferred work.
- Record material decisions and consequences.
- Avoid secrets, sensitive production data, and misleading claims.
- Remain synchronized with the phase’s actual outcome.

## 5.8 Acceptance Criteria

Acceptance criteria define observable conditions for completion. Every criterion must be:

- Specific and objectively verifiable.
- Traceable to the objective, scope, task, risk, or deliverable.
- Written as an outcome rather than an activity.
- Supported by named evidence such as tests, inspection, measurements, review, or documentation.
- Clear about negative conditions, including prohibited behavior and scope exclusions where important.

An acceptance checklist must not contain vague items such as “works correctly” without defining the expected result and evidence.

## 5.9 Completion Instructions

Every prompt must instruct the executor to:

1. Review the final result and scope.
2. Map acceptance criteria to evidence.
3. Run the required validation and record exact outcomes.
4. Disclose failed, skipped, unavailable, or externally blocked checks accurately.
5. Update only the corresponding completion report.
6. List changed artifacts and material decisions.
7. Record limitations and pending work with impact and next action.
8. Stop without starting the next phase.

# 6. Prompt Execution Workflow

## 6.1 Step 1 — Establish the Execution Context

The executor confirms the assigned prompt, phase number, canonical phase name, repository root, corresponding completion report, and authorized scope. The current repository status is inspected so that unrelated or concurrent work is preserved.

## 6.2 Step 2 — Read Prior Evidence

The executor reads all mandatory sources and relevant predecessor completion reports in full. Earlier reports provide context and claims, but those claims must be reconciled with current files, decisions, configuration, tests, and other executable evidence.

## 6.3 Step 3 — Validate Dependencies

Every direct dependency is verified before phase work begins. Verification should confirm that required capabilities, decisions, artifacts, access, and critical quality gates are available and consistent.

If a dependency is incomplete, the executor follows the prompt’s stated dependency policy. The executor must not conceal the issue, invent missing evidence, or implement unrelated predecessor scope merely to continue.

## 6.4 Step 4 — Understand the Existing Architecture

The executor examines the current structure, ownership boundaries, conventions, applicable decisions, and behavior in the areas affected by the phase. Existing architecture and tested implementation are understood before changes are planned.

Material conflicts between the prompt and newer authoritative evidence must be resolved according to project governance and documented. The narrowest safe interpretation consistent with approved scope is preferred.

## 6.5 Step 5 — Plan Against Acceptance Criteria

Before implementation, the executor creates a working checklist that maps each task and deliverable to one or more acceptance criteria and identifies the expected validation evidence. This internal plan helps prevent requirements from being discovered only at phase closure.

## 6.6 Step 6 — Execute Only the Assigned Phase

Work proceeds within the approved scope and repository boundaries. The executor preserves unrelated changes, avoids speculative features, and does not begin capabilities assigned to later prompts.

Any material decision, deviation, risk, or migration requirement is handled through the project’s approved decision and documentation process. Temporary shortcuts, placeholders, and knowingly incomplete production paths are not accepted as completion.

## 6.7 Step 7 — Verify the Results

The executor runs all applicable quality gates and reviews the result for:

- Functional acceptance.
- Architecture and ownership conformity.
- Security, privacy, and isolation.
- Reliability, recovery, and failure behavior.
- Performance or capacity requirements.
- Compatibility and migration safety.
- Documentation accuracy.
- Scope and repository hygiene.

Exact validation commands, reviews, measurements, and outcomes are retained as completion evidence. A check that was not run is recorded as not run, not as passed.

## 6.8 Step 8 — Update the Completion Report

Only the completion report corresponding to the assigned phase is updated. It must contain factual evidence, exact repository-relative artifact paths, validation outcomes, material decisions, deviations, limitations, and any external gates.

Completion reports must distinguish:

- Completed and verified work.
- Completed but not independently verified work.
- Failed or unavailable validation.
- Deferred or blocked work.
- Follow-up recommendations that are outside the phase.

## 6.9 Step 9 — Stop at the Phase Boundary

After the prompt’s deliverables, validation, documentation, and completion report are accurate, execution stops. The executor must not start the next prompt, pre-implement later features, or update another phase’s completion report.

# 7. Prompt Quality Standards

## 7.1 Required Quality Attributes

Every implementation prompt must be:

- **Enterprise-grade:** Suitable for controlled work on a business-critical, multi-tenant ERP.
- **Production-ready:** Oriented toward complete, supportable, secure, and operational outcomes.
- **Scalable:** Written with growth, modularity, capacity, and organizational handover in mind.
- **Maintainable:** Clear, consistently structured, traceable, and easy to update safely.
- **Secure:** Explicit about security responsibilities, isolation, least privilege, validation, audit, and sensitive information.
- **Self-contained:** Complete enough to execute its phase using the referenced authoritative sources.
- **Architecture-driven:** Consistent with approved ownership, boundaries, decision records, and dependency direction.
- **Unambiguous:** Free from conflicting instructions and avoidable interpretation gaps.
- **Verifiable:** Supported by objective acceptance criteria and named evidence.
- **Scope-controlled:** Explicit about exclusions, later-phase work, and stopping conditions.

## 7.2 Prohibited Prompt Defects

Prompts must be free from:

- Placeholders, TODOs, empty headings, or incomplete checklists.
- Generic instructions that do not identify the expected outcome or evidence.
- Unsupported module behavior or invented business rules.
- Conflicting phase names, numbers, file paths, or dependencies.
- Hidden assumptions and undocumented architecture changes.
- Instructions to bypass validation, weaken quality controls, or misreport completion.
- Cross-boundary ownership that contradicts approved architecture.
- Acceptance criteria that cannot be objectively evaluated.
- Automatic continuation into another phase.
- Claims that an external system, environment, approval, or test is available when it has not been verified.

## 7.3 Clarification Standard

A production-quality prompt should be executable without additional clarification. Prompt authors must resolve foreseeable ambiguity through approved sources, explicit boundaries, and clear decision rules before approval.

This requirement does not authorize an executor to guess when a material business decision, security decision, external approval, or scope choice is genuinely missing. In those cases, the prompt must define the escalation or blocking path.

# 8. Prompt Validation Process

## 8.1 Author Self-Review

Before formal review, the prompt author verifies:

- All mandatory sections are complete.
- The phase identity and repository paths are correct.
- Scope aligns with the approved roadmap.
- Dependencies are real, ordered, and verifiable.
- Requirements are consistent with authoritative planning and architecture.
- Acceptance criteria cover every required deliverable and material risk.
- No placeholder, TODO, unsupported assumption, or later-phase work remains.

## 8.2 Architecture Consistency Review

The reviewer confirms that the prompt preserves:

- Approved capability and data ownership.
- Dependency direction and interaction boundaries.
- Tenant, branch, user, and administrative boundaries where applicable.
- Compatibility and decision-record requirements.
- Repository organization and shared standards.

Any architectural conflict must be resolved in the authoritative architecture or through an approved decision before the prompt is released for execution.

## 8.3 Dependency Verification

The reviewer confirms that:

- Every prerequisite is identified.
- Phase order is valid.
- Dependency evidence can be inspected.
- Missing dependencies have a defined response.
- No circular dependency or hidden later-phase dependency exists.

## 8.4 Documentation Completeness Review

The reviewer checks that the prompt identifies all required planning, implementation, operational, decision, validation, and completion documentation. References must exist, be relevant, and use accurate repository-relative paths.

## 8.5 Acceptance-Criteria Review

Each acceptance criterion is assessed for clarity, traceability, objectivity, and evidence. The full set must cover the objective, deliverables, critical non-functional requirements, prohibited outcomes, and completion-report accuracy.

## 8.6 Scope Verification

The reviewer compares the prompt with the roadmap and neighboring phases to confirm:

- Required work is not omitted.
- Adjacent work is not duplicated.
- Later work is not implemented early.
- Out-of-scope boundaries are explicit.
- The phase can finish coherently without unauthorized expansion.

## 8.7 Overall Quality Gate

A prompt is approved only when:

- Critical ambiguity is zero.
- Architecture and dependency reviews pass.
- Security and isolation requirements are appropriate.
- Documentation and acceptance criteria are complete.
- Execution and completion instructions are actionable.
- No placeholders, TODOs, contradictions, or unverifiable success claims remain.

Rejected prompts return to authoring with documented findings. Prompt approval status and material revisions must be visible through version control.

# 9. Prompt Library Organization

## 9.1 Repository Locations

The library should use the existing planning structure consistently:

| Location | Responsibility |
|---|---|
| `ERP-PLANNING/implementation-prompts/` | Master implementation prompt strategy, standards, templates, and governance guidance |
| `ERP-PLANNING/phase-prompts/` | One executable prompt for each approved phase and the reusable audit prompt |
| `ERP-PLANNING/phase-completions/` | One factual completion report for each executable phase |
| `ERP-PLANNING/architecture/` and project decision-record locations | Authoritative architecture guidance and approved material decisions |
| `ERP-PLANNING/prompt-engineering/` | Prompt review methodology, quality assurance, and improvement guidance |

The repository catalog should link each canonical phase to its executable prompt and matching completion report.

## 9.2 Naming Conventions

File naming must:

- Use the canonical phase number and a stable descriptive name.
- Preserve established repository filenames when renaming would break links or historical traceability.
- State the canonical identity inside a file when a legacy filename differs.
- Use uppercase phase identifiers consistently for phase prompts and completion reports.
- Make the relationship between a prompt and its completion report unambiguous.

Prompt titles, catalogs, references, and completion reports must agree on the phase’s canonical number and name.

## 9.3 Relationships Between Prompts

Each phase prompt must identify:

- Its direct predecessors and prerequisite evidence.
- The approved outcome it receives from earlier phases.
- The completion report it must update.
- The downstream phases that depend on its output, when this context is needed for compatibility.
- Shared standards or decisions that apply across the library.

Cross-references should create traceability, not duplicate entire prompts. A later prompt may rely on an earlier completed outcome but must still verify that the outcome exists.

## 9.4 Version Control

All prompt changes must be version-controlled and reviewable. Commit history should make clear:

- Why the prompt changed.
- Whether the change is editorial, clarifying, corrective, or scope-affecting.
- Which planning decision, audit finding, defect, or repository change motivated it.
- Whether approved or completed phases are affected.

Prompt updates must preserve unrelated work and must not rewrite historical completion evidence to match a new expectation.

## 9.5 Update Strategy

Prompts are updated when authoritative business requirements, architecture decisions, repository structure, dependencies, risks, or quality standards change. Updates should be made at the narrowest appropriate level:

- Change central guidance when the rule applies to the whole library.
- Change a phase prompt when the issue is specific to that phase.
- Update the prompt catalog when identity, location, or relationships change.
- Record material architectural changes through the approved decision process.

If a prompt has already been executed, a material scope change requires impact assessment. The project must decide whether the change belongs in corrective work, a new phase, or a formally re-opened phase. Completed evidence must remain factual to the work actually performed.

## 9.6 Documentation Maintenance

Prompt documentation is reviewed:

- Before a prompt is approved for execution.
- When an authoritative source or repository path changes.
- After audit findings affect prompt governance.
- Before major release gates.
- When repeated execution ambiguity reveals a weakness in the framework.

Broken links, stale terminology, contradictory requirements, and legacy naming differences should be corrected or explicitly documented. The library catalog and this framework must remain synchronized with the executable prompt set.

# 10. Expected Outcome

The completed implementation prompt library provides one independent, enterprise-quality implementation prompt for every approved Nexoraa CleanSoft ERP development phase. Each prompt converts authoritative planning into a bounded execution contract with clear objectives, scope, dependencies, architecture constraints, quality expectations, deliverables, validation, acceptance criteria, completion evidence, and stopping instructions.

AI-assisted development tools such as Claude Code or Codex can use each prompt to execute the assigned phase consistently while respecting the project’s architecture, security model, repository state, and delivery sequence. Prompt independence removes avoidable ambiguity; dependency verification and phase ordering preserve system integrity.

As a whole, the library establishes a structured and auditable development process that is:

- Consistent across modules and phases.
- Scalable across a large ERP program.
- Maintainable as requirements and architecture evolve.
- Secure and architecture-aligned by default.
- Traceable from planning through implementation and validation.
- Resistant to scope drift, incomplete work, and unsupported completion claims.

The final result is not merely a collection of instructions. It is a governed implementation methodology that enables Nexoraa CleanSoft to progress from planning to production through controlled, verifiable, and maintainable phases.

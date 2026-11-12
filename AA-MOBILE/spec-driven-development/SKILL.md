---

name: spec-driven-development
description: Use this skill when developing new features or making non-trivial changes to an existing project.
--------------------------------------------------------------------------------------------------------------

# Spec-Driven Development (SDD)

## Purpose

Ensure every non-trivial development task follows a traceable workflow:

**Specification → Technical Plan → Task Breakdown → Implementation → Validation**

This skill controls workflow sequencing and approval gates. It does not replace repository conventions, technology-specific skills, or mandatory MobiAI workflows.

Never skip stages, infer user approval, or implement without explicit authorization.

## 1. Task Classification

Use the full SDD workflow for:

* New features or changes to existing functionality.
* Bug fixes affecting application behavior.
* UI, navigation, or interaction changes.
* Data, persistence, networking, or architecture changes.
* Dependencies, security, permissions, or performance changes.
* Tasks involving multiple implementation steps.

Only trivial changes, such as typos or formatting without behavioral impact, may use a lightweight workflow.

When uncertain, use the full workflow.

## 2. Initial Requirements

Whenever this skill is invoked, immediately notify the user:

"I'm using the `spec-driven-development` skill to guide this task through the required specification, planning, approval, implementation, and validation stages."

Before investigating the project, preparing documents, planning, or modifying code:

1. Read `references/GENERIC_RULES.md` completely. If inaccessible, stop and report the blocker.
2. Initialize MobiAI Brain and query relevant project knowledge, conventions, and previous decisions. If unavailable, stop and report the blocker.
3. Discover available skills and subagents.
4. Read `using-mobiai` and all applicable mandatory skills before performing the work they govern.
5. Read the relevant reference documents and templates before using them.

For Android development, load the applicable mandatory skills:

* `mobiai-android-architecture`
* `android-jetpack-compose` when using Compose.
* `edge-to-edge` when working on Android screens.
* `one-shot-ui-events` when handling navigation, dialogs, toasts, or other one-shot UI events.
* `mobiai-mobile-verification` before declaring the task complete.

Also consult `references/MOBILE_GUIDELINES.md` for applicable mobile requirements.

All reference paths are relative to this skill's directory.

### Initial Report

Before creating feature documents or modifying code, briefly report:

* Task classification and scope.
* Generic Rules and Brain initialization status.
* Applicable skills and their loading status.
* Available subagents and proposed delegation.
* Existing SDD documents and their approval status.
* The next permitted stage.

Report actual outcomes only. If a mandatory prerequisite fails, stop the affected work and explain the blocker.

## 3. Subagent Strategy

The main agent is responsible for orchestration, user communication, approval gates, scope control, and final validation.

Use subagents only when they provide a clear benefit. Do not invoke every agent automatically.

| Stage          | Suggested Agent        | Responsibility                                 |
| -------------- | ---------------------- | ---------------------------------------------- |
| Specification  | `requirements-analyst` | Analyze requirements and identify ambiguities. |
| Technical Plan | `android-architect`    | Review architecture and technical decisions.   |
| Task Breakdown | Main agent             | Create implementation tasks.                   |
| Implementation | `android-developer`    | Implement explicitly authorized tasks.         |
| Validation     | `test-reviewer`        | Review test coverage and quality.              |
| Final Review   | `code-reviewer`        | Identify bugs and regressions.                 |

Rules:

* Subagents perform bounded tasks and report findings to the main agent.
* They cannot approve specifications, plans, or implementation.
* Implementation delegation requires explicit user authorization.
* Avoid multiple agents modifying the same files concurrently.
* The main agent must review and integrate delegated results.
* If no suitable agent is available, proceed without delegation.

When working as a subagent, follow Section 14: Subagent Compatibility.

## 4. Feature Documents

Keep feature documents together:

* `docs/features/<feature-name>/SPEC.md`
* `docs/features/<feature-name>/PLAN.md`
* `docs/features/<feature-name>/TASKS.md`

Reuse existing feature documents when continuing previous work.

Before creating them, read the corresponding templates:

* `references/SPEC_TEMPLATE.md`
* `references/PLAN_TEMPLATE.md`
* `references/MOBILE_GUIDELINES.md`

Preserve template structure and embedded comments. Follow established repository paths if they differ.

Apply relevant Generic Rules, Mobile Guidelines, Brain knowledge, and technology-specific skills throughout the workflow.

## 5. Stage 1 — Specification

1. Define the feature scope and intended behavior.
2. Analyze existing decisions and relevant project context.
3. Create or update `SPEC.md` using the specification template.
4. Define functional requirements (`RF-`) and acceptance criteria (`CA-`).
5. Identify ambiguities, edge cases, and unresolved product decisions.
6. Collaborate with the user to resolve them.
7. Present the completed specification for approval.

**STOP and wait for explicit user approval before proceeding.**

Only the user can approve the specification. A completed document or silence does not constitute approval.

## 6. Stage 2 — Technical Plan

Begin only after specification approval.

1. Inspect the relevant architecture, code, dependencies, and conventions.
2. Create or update `PLAN.md` using the approved specification.
3. Reference the relevant `RF-` and `CA-` identifiers.
4. Define affected components, implementation approach, dependencies, and testing strategy.
5. Identify technical risks and unresolved decisions.
6. Define any required subagent delegation.
7. Present the plan for approval.

**STOP and wait for explicit user approval before proceeding.**

Approval of the specification does not imply approval of the plan.

## 7. Stage 3 — Task Breakdown

Begin only after technical plan approval.

Create or update `TASKS.md`, deriving tasks exclusively from the approved specification and plan.

Each task must include:

* Unique identifier and objective.
* Implementation scope.
* Dependencies.
* Relevant `RF-` and `CA-` identifiers.
* Validation method.
* Actual progress status.

Keep tasks small and independently verifiable where practical.

**STOP until the user explicitly authorizes implementation.**

Approval of the specification and plan does not authorize code changes.

## 8. Stage 4 — Implementation

Implementation requires all three conditions:

1. Specification approved.
2. Technical plan approved.
3. Explicit user authorization to implement.

Once authorized:

* Execute tasks in dependency order.
* Follow approved documents, Generic Rules, repository conventions, and applicable skills.
* Keep changes within the approved scope.
* Update task statuses as work progresses.
* Add or update tests where appropriate.
* Ensure delegated work follows the same constraints.

If implementation reveals missing requirements, contradictory decisions, or a scope change, stop the affected work. Clarify the issue, update the relevant documents, and obtain renewed approval before continuing.

Do not request permission again for work already covered by the user's authorization.

## 9. Stage 5 — Validation and Completion

Before declaring an Android task complete:

1. Follow `mobiai-mobile-verification`.
2. Run relevant tests, builds, and static analysis.
3. Verify implementation against approved acceptance criteria.
4. Review relevant Generic Rules and Mobile Guidelines.
5. Update `TASKS.md` with actual results.
6. Report failures, limitations, and outstanding work.
7. Consider whether reusable knowledge should be contributed to MobiAI Brain.

Never claim a check passed unless it was actually executed and verified.

Clearly distinguish between:

* Implementation completed.
* Validation passed.
* Validation partially completed.
* Validation failed.
* Outstanding work.

Do not declare full completion while required checks remain outstanding.

## 10. Scope Changes

If new information changes approved requirements or acceptance criteria:

1. Stop the affected work.
2. Explain the discrepancy and its impact.
3. Clarify the intended behavior with the user.
4. Update the specification and obtain explicit approval.
5. Update the technical plan and obtain explicit approval.
6. Update the task breakdown.
7. Resume only within the newly approved scope.

Never silently change approved behavior or bypass approval gates.

## 11. Non-Negotiable Rules

* Read Generic Rules before project investigation or modification.
* Initialize and query MobiAI Brain before starting project work.
* Load applicable mandatory skills.
* Never skip required verification.
* Never create the technical plan before specif

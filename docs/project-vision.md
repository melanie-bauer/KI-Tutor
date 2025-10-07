# Project Vision: AI Tutors for Schools

## Vision Statement

Public schools across Austria and Europe are facing the same challenge: They know they must integrate artificial intelligence (AI) into teaching and learning but lack a safe, structured, and pedagogically meaningful strategy for doing so. This project aims to create an **open, privacy-compliant, and practical AI platform** for use in education. It will enable teachers to design and configure their own AI tutors, supporting students in learning and problem-solving, while ensuring data protection, transparency, and pedagogical control.

Our vision is to empower both teachers and students to engage with AI not as passive consumers, but as active creators and critical thinkers building AI literacy in the process.

## Background and Motivation

Most public schools in Austria face a combination of:

* **Didactic uncertainty** about how to use AI meaningfully in the classroom.
* **Lack of appropriate tools** that meet privacy and compliance requirements.
* **Dependence on free online AI tools** that often store user input, use it for model training, or finance themselves through advertising.

This creates a fundamental tension. Schools need access to AI but cannot ethically or legally use commercial, data-collecting systems.

HTL Leonding has emerged as a **national leader in AI education**. This project is part of that broader initiative, a pilot implementation intended to produce a working, scalable solution that can be reused by other schools.

## Objectives

### Minimal Goals

* Teachers from Mathematics, German, and Programming subjects can create AI tutors by:
  * Editing system prompts, and
  * Selecting the underlying LLM (Large Language Model) for each tutor.
* Students can use these tutors but cannot modify their configurations.
* Students in programming classes can interact with LLM APIs directly via API keys or access tokens.
* The system provides budget control, allowing schools to assign token or cost budgets per time period (hour, day, week, month).
* AI Tutors can:
  * Display mathematical formulas and code correctly.
  * Support code execution or interpretation (aka _Code Interpreter_; especially for mathematics tasks).
* The platform must:
  * Connect to at least Azure OpenAI.
  * Store only budget usage statistics.
  * Run entirely in European data centers and be self-hostable on-premises (except for the LLMs themselves).
  * Use open source components (except for the LLMs themselves).
  * Accept both text and image input (e.g., photos of handwritten work).
  * Offer desktop-friendly user interfaces.
* The school leadership (e.g., HTL management) must be able to view total budget usage on a class level via a dashboard.

### Extended Goals

* SSO integration via existing school accounts (e.g., Entra ID). API keys for programming tasks can be generated via a school web portal.
* Budget transparency: students and teachers can view their usage; class teachers can monitor class-level budgets.
* Class-based control: teachers can enable or disable tutors for specific classes.
* Support for multiple LLM providers in this priority:
  1. Azure OpenAI
  2. OpenAI
  3. Claude
  4. Gemini
  5. Mistral
* Mobile usability for teachers and students.
* Configuration flexibility so that other schools can easily adopt the solution.

## Project Scope and Deliverables

**This is not just a prototype.** The AI Tutor platform must be production-ready, fully operational, and actively used by teachers and students at HTL Leonding during the project timeline.

The project team is responsible for:

* Delivering a working system that meets all minimal goals and as many extended goals as feasible.
* Deploying the platform in a production environment (on-premises or European cloud infrastructure).
* Providing active support during rollout and use, including:
  * Technical troubleshooting and bug fixes
  * User onboarding and training materials
  * Documentation for administrators, teachers, and students
* Iterating based on real-world feedback from teachers and students during operation.
* The solution must be maintainable and transferable to other schools after the project phase ends.

Success will be measured not by technical feasibility alone, but by actual classroom adoption and sustained use.

## Educational Value

This project promotes AI literacy and responsible use of modern technologies by:

* Enabling teachers to experiment safely with AI in a pedagogically meaningful way.
* Giving students insight into how AI systems work and how to interact with them critically.
* Reducing dependency on opaque, commercial systems.
* Demonstrating digital sovereignty through open technologies hosted in Europe.
se “executive summary” version** as well (1–2 pages, for decision makers or funding applications)? It would highlight the same vision but in a more compact, narrative style.

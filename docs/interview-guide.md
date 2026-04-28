# 24-Hour Engineering Take-Home: Mobile + Backend Monorepo

## Overview

This exercise is designed to evaluate how you approach building a modern product foundation under time constraints, especially when working with unfamiliar tools or patterns.

You will build a small mobile application and a corresponding backend service in a single monorepo. The specific product idea is intentionally flexible: it could be a lightweight social app, a game, a task manager, or something similarly simple. The functionality itself is not the focus.

What we care about most is how you set up, structure, and explain the system.

This task is intentionally likely to push you outside your comfort zone. We expect you to use available tools, including AI assistants, documentation, and external references, to help you make progress quickly. We do not expect mastery of every technology you choose or encounter. We do expect thoughtful decisions, reasonable tradeoffs, and the ability to explain why something exists in the project.

---

## Time Limit

You should spend no more than **24 hours total** on this exercise.

Prioritize strong foundations, clear documentation, and sensible tradeoffs over feature completeness.

---

## Core Requirements

### 1) Monorepo setup

Create a **single monorepo** containing:

- a mobile client  
- a backend service  
- supporting shared code or libraries where appropriate  
- documentation for architecture, setup, and testing  

We want to see how you organize a codebase intended to support multiple components and future growth.

---

### 2) iOS application

Build a simple **iOS mobile application**.

The app can be minimal in scope. Examples include:

- a simple social feed  
- a task manager  
- a small game  
- a notes app  
- any similarly small interactive product  

The functionality is less important than the quality of the setup and structure.

The iOS app should demonstrate:

- a buildable, runnable client  
- sensible project structure  
- clear separation of concerns  
- at least one meaningful interaction with the backend  
- enough UI to show the system working end to end  

---

### 3) Backend in Rust

Build a corresponding **backend service in Rust**.

The backend should be designed with **low latency** in mind. The implementation and design should show that performance, scalability and responsiveness were considered.

The backend should include:

- a functional API  
- at least one set of meaningful endpoints used by the mobile app  

Deployment is not required, local-only should be the objective of the task

---

### 4) Bazel build system

Use **Bazel** to build the project.

At minimum, Bazel should be meaningfully involved in building:

- the iOS app  
- the backend  
- relevant shared modules or libraries if present  

---

### 5) Agent-optimized codebase

Design the repository so that it is **easy for AI coding agents to navigate and contribute to**.

We want to see intentionality behind the decisions made that allow for a better workflow for agents.

---

## Bonus task

Bonus credit if you build a **shared Rust platform layer** and place an **iOS and Android view layer** on top of it.

This is not required. Only attempt it if you can do so without undermining the quality of the core task.

---

## Documentation Requirements

Strong documentation is a required part of the exercise.

Your repository should include the following:

### README

A top-level README that explains:

- what the project is  
- how the repository is structured  
- how to build and run the system  
- how to run tests  
- any assumptions or limitations 

---

### System Design document

A concise document describing:

- the overall architecture  
- major components and responsibilities  
- data flow between app and backend  
- important tradeoffs  
- performance considerations  

We will consider further design during the crit, it is not required to extrapolate past your implemented design at this point 

---

### Test Plan

A document describing:

- How to test your system and evaluate stability

---

### Retrospective

A retrospective document that explains:

- key decisions you made along the way  
- what you prioritized given the 24-hour limit  
- alternatives you considered  
- why you made the choices you did  
- what worked well  
- what you would change with more time  
- what you learned, especially where the task pushed you into unfamiliar territory  

This is an important part of the submission, it will be used during the Crit session.

---

## Git Expectations

Please submit the project as a **git repository**.

We are looking for good git etiquette, including:

- sensible commit history  
- clear commit messages  
- commits that reflect meaningful steps in the build  
- evidence of iterative development rather than one final dump  

The history should help us understand how you worked.

---

## Submission Expectations

Your submission should include:

- the full repository  
- build and run instructions  
- all required documentation  
- enough implementation to demonstrate the architecture working end to end  

We expect the project to be reviewable in a live crit session, so please make choices you can explain and defend.

---

## How We Will Evaluate

We will evaluate your submission based on the overall quality of the project and your ability to explain it.

In particular, we’re looking for:

- **Clarity of thinking** — how you structure problems and make decisions under time constraints  
- **Quality of the foundation** — how the project is set up, organized, and built  
- **Pragmatism** — how you balance speed, scope, and technical choices  
- **Communication** — how well you document and explain your decisions  
- **Ownership** — how you reflect on your work, including tradeoffs and shortcomings  

There is no “perfect” solution. We care more about thoughtful decisions and clear reasoning than completeness.
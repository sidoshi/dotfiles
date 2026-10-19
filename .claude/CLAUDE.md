## Code

When writing code, follow these guidelines:

- Keep comments to absolute minimum. Use it only when absolutely necessary to explain complex logic.

## Language

Provide concise, focused responses.
Use ASD-STE100 Simplified Technical English.
Reduce the usage of adjectives to a minimal.
Skip non-essential context, and keep examples minimal.

## Structure in Long-Form Writing (Confluence / PRDs / ADRs)

Follow this pattern:

1. Business context / background
2. Objective / goal
3. Success metrics
4. Requirements or steps
5. Assumptions
6. Out of scope
7. Open questions

Do not use emojis (:dart:, :bar*chart:, :warning:) and bold for key terms. Explain the \_why*, not just the _what_.

## Tools and secrets

- Install tools with mise, not brew or other installers. Pin the tool per project in `mise.toml` when the project needs it.
- Keep secrets in fnox. Do not write secrets to `.env` files or shell profiles.

## Rex

- Do not rename Rex sessions, even when the Rex hook or skill says to. Rename only when I ask.

# Agent Guidelines for obscvratfi

This document provides guidelines for AI coding agents working in this repository.

## Project Overview

This is the obscvratfi project. As the codebase grows, maintain consistency with the patterns established in the initial implementation.

## Build, Lint, and Test Commands

### General Commands
```bash
# Install dependencies (update based on project type)
npm install          # For Node.js/TypeScript projects
pip install -r requirements.txt  # For Python projects
go mod download      # For Go projects

# Build
npm run build        # TypeScript/JavaScript
go build ./...       # Go
cargo build          # Rust

# Lint
npm run lint         # JavaScript/TypeScript with ESLint
npm run lint:fix     # Auto-fix linting issues
pylint src/          # Python
golangci-lint run    # Go

# Format
npm run format       # Prettier/dprint
black .              # Python
gofmt -w .           # Go

# Test - All
npm test             # JavaScript/TypeScript
pytest               # Python
go test ./...        # Go
cargo test           # Rust

# Test - Single File/Suite
npm test -- path/to/test.spec.ts          # Jest/Vitest
npm test -- --testNamePattern="test name" # Jest/Vitest by name
pytest path/to/test_file.py              # Python specific file
pytest path/to/test_file.py::test_name   # Python specific test
go test ./path/to/package                # Go specific package
go test -run TestName ./path/to/package  # Go specific test
cargo test test_name                     # Rust specific test

# Type checking
npm run type-check   # TypeScript
mypy .               # Python
```

### Watch Mode
```bash
npm run dev          # Development server with hot reload
npm test -- --watch  # Test watch mode
```

## Code Style Guidelines

### File Organization
- Group related functionality into modules/packages
- Keep files focused and under 500 lines when possible
- Use clear, descriptive file and directory names
- Prefer flat directory structures over deep nesting

### Imports
- Order: external dependencies first, then internal imports
- Use absolute imports for internal modules when configured
- Group imports by type: types, utilities, components, etc.
- Remove unused imports

**TypeScript/JavaScript:**
```typescript
// External dependencies
import { useState, useEffect } from 'react';
import axios from 'axios';

// Internal types
import type { User, ApiResponse } from '@/types';

// Internal utilities/modules
import { formatDate } from '@/utils/date';
import { UserService } from '@/services/user';
```

**Python:**
```python
# Standard library
import os
from typing import List, Optional

# Third-party
import requests
from fastapi import FastAPI

# Local
from .models import User
from .utils import format_date
```

### Naming Conventions

**General:**
- Use descriptive, intention-revealing names
- Avoid abbreviations unless widely understood
- Be consistent across the codebase

**TypeScript/JavaScript:**
- `camelCase` for variables, functions, methods
- `PascalCase` for classes, interfaces, types, components
- `UPPER_SNAKE_CASE` for constants
- Prefix interfaces with `I` only if there's ambiguity
- Prefix private methods with `_` (or use `#` for private fields)

**Python:**
- `snake_case` for variables, functions, methods, modules
- `PascalCase` for classes
- `UPPER_SNAKE_CASE` for constants
- Prefix private methods/attributes with `_`

**Go:**
- `camelCase` for private identifiers
- `PascalCase` for exported identifiers
- Capitalize acronyms: `HTTPServer`, `URLParser`

### Types and Type Safety

**TypeScript:**
- Enable strict mode in `tsconfig.json`
- Avoid `any` - use `unknown` when type is truly unknown
- Define interfaces for object shapes
- Use union types and type guards
- Prefer `interface` over `type` for object types
- Use `const` assertions for literal types

**Python:**
- Use type hints for function signatures
- Use `Optional[T]` for nullable values
- Use `typing` module types (List, Dict, etc.)
- Run `mypy` to validate type hints

**Go:**
- Prefer explicit types over type inference for public APIs
- Use interfaces for abstraction
- Keep interfaces small and focused

### Error Handling

**TypeScript/JavaScript:**
```typescript
// Use try-catch for async operations
try {
  const result = await fetchData();
  return result;
} catch (error) {
  if (error instanceof ApiError) {
    // Handle specific error
  }
  throw new AppError('Failed to fetch data', { cause: error });
}

// Return Result types for operations that commonly fail
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E };
```

**Python:**
```python
# Use specific exception types
try:
    result = fetch_data()
except requests.HTTPError as e:
    logger.error(f"HTTP error occurred: {e}")
    raise DataFetchError("Failed to fetch data") from e
except Exception as e:
    logger.exception("Unexpected error")
    raise
```

**Go:**
```go
// Return errors explicitly
result, err := fetchData()
if err != nil {
    return nil, fmt.Errorf("failed to fetch data: %w", err)
}

// Use custom error types for specific errors
if errors.Is(err, ErrNotFound) {
    // Handle not found
}
```

### Comments and Documentation

- Write self-documenting code; comments should explain "why", not "what"
- Add doc comments for public APIs (JSDoc, docstrings, etc.)
- Keep comments up-to-date when code changes
- Use TODO/FIXME/NOTE tags with context

```typescript
/**
 * Fetches user data with caching and retry logic.
 * 
 * @param userId - The unique identifier for the user
 * @param options - Optional configuration for the request
 * @returns Promise resolving to user data
 * @throws {NotFoundError} When user doesn't exist
 */
async function fetchUser(userId: string, options?: FetchOptions): Promise<User> {
  // TODO(author): Add rate limiting - ticket #123
}
```

## Testing Guidelines

- Write tests for new features and bug fixes
- Aim for meaningful coverage, not just high percentages
- Use descriptive test names that explain the scenario
- Follow AAA pattern: Arrange, Act, Assert
- Mock external dependencies
- Keep tests isolated and independent

## Architecture Decision Records (ADRs)

Significant architectural and technical decisions should be documented in
Architecture Decision Records (ADRs). This creates a clear history of why
decisions were made and helps maintain consistency throughout the project.

### When AI Agents Should Prompt for ADRs

As an AI agent working on this codebase, you should suggest creating an ADR when:

- **Technology/Framework Choices:** Selecting libraries, frameworks, or tools that will be core dependencies
- **Major Dependencies:** Adding significant third-party services or packages
- **Patterns & Conventions:** Establishing new code patterns, project structure, or naming conventions
- **Data Modeling:** Database schema design, API structure (REST vs GraphQL), data format decisions
- **Security Decisions:** Authentication/authorization approaches, encryption strategies
- **Performance Strategies:** Caching implementations, optimization techniques that affect architecture
- **Breaking Changes:** Changes that affect public APIs or require migration

### ADR Workflow for Agents

When an ADR-worthy decision comes up:

1. **Recognize the need:** Identify that the decision is architecturally significant
2. **Notify the user:** "This decision should be documented in an ADR. Let me help you with that."
3. **Follow the decision-making workflow:**
   - Ask relevant questions based on decision type (see ADR-0002)
   - Research and present alternatives with pros/cons
   - Use appropriate approach: present options, make recommendation, or ask Socratic questions
   - Help draft the ADR after decision is made
4. **Create the ADR:** Use `./scripts/new-adr.sh "Decision Title"` or create manually
5. **Reference the ADR:** In code comments, PR descriptions, and related documentation

### ADR Resources

- **ADR Directory:** `/docs/adr/`
- **Template:** `/docs/adr/template.md`
- **Workflow Guide:** See ADR-0002 for detailed decision-making process
- **Helper Scripts:**
  - `./scripts/new-adr.sh "Title"` - Create new ADR
  - `./scripts/list-adrs.sh [status]` - List all ADRs

### Creating ADRs

```bash
# Create a new ADR
./scripts/new-adr.sh "Choose frontend framework"

# List all ADRs
./scripts/list-adrs.sh

# List ADRs by status
./scripts/list-adrs.sh Accepted
```

Remember: Not every decision needs an ADR. Focus on decisions that:
- Have long-term implications
- Are difficult or expensive to reverse
- Affect multiple parts of the system
- Set precedents for future work
- Involve significant tradeoffs

## Git Commit Guidelines

For detailed commit message guidelines and branch naming conventions, see
[CONTRIBUTING.md](CONTRIBUTING.md).

**Quick Reference:**
- Use imperative mood: "Add feature" not "Added feature"
- Keep header under 72 characters
- Add body for non-trivial changes (wrap at 72-74 chars)
- Explain WHY, not just what
- Reference issues: `Fixes #123`
- Branch naming: `type/short-description` (e.g., `feature/user-auth`)

## When Making Changes

1. Read existing code to understand patterns
2. Follow established conventions in the codebase
3. Run linter and fix issues before committing
4. Run tests and ensure they pass
5. Update documentation if changing public APIs
6. Keep changes focused and atomic

## Additional Notes

- Prioritize code readability and maintainability
- Avoid premature optimization
- Handle edge cases and validate inputs
- Log errors with sufficient context
- Keep dependencies up-to-date and minimal

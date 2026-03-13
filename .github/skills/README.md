# FlutterPOS Agent Skills

Professional-grade agent skills for Flutter and Dart development, specialized for POS (Point of Sale) applications.

## 🎯 Available Skills

### 1. [flutter-architecture-refactoring](flutter-architecture-refactoring/)
Refactor Flutter code using three-layer modular architecture. Enforce 500-line file limits. Split monolithic widgets into focused services, widgets, and screens.

**Use when**: Refactoring large files, planning features, improving code organization

---

### 2. [pos-business-logic-calculations](pos-business-logic-calculations/)
Build accurate POS business logic for cart operations, tax/discount calculations, payment processing, and financial workflows.

**Use when**: Implementing cart, pricing, discounts, payments, receipts

---

### 3. [pos-ui-responsive-design](pos-ui-responsive-design/)
Build responsive POS interfaces for Windows desktop and Android tablets. Adaptive layouts, touch optimization, multi-orientation support.

**Use when**: Creating screens, layout problems, responsive grids, touch targets

---

### 4. [flutter-testing-quality](flutter-testing-quality/)
Write comprehensive tests: unit tests for Layer A (100% coverage), widget tests for Layer B (80%+), integration tests for workflows.

**Use when**: Writing tests, improving coverage, mocking services

---

### 5. [pos-hardware-integration](pos-hardware-integration/)
Integrate thermal printers (58mm/80mm), barcode scanners, and payment terminals. Handle device discovery, connection, error recovery.

**Use when**: Integrating hardware, receipt printing, barcode scanning

---

### 6. [gemini-cli-heavy-lifting](gemini-cli-heavy-lifting/)
Use Gemini CLI for high-context analysis and implementation across large code areas. Includes task routing rules, prompt templates, and a safe execution sequence for heavy bug fixing.

**Use when**: Cross-file bug hunts, large refactors, release blockers, oversized context tasks

---

## 📋 Quick Reference

| Task | Skill |
|------|-------|
| Refactor 800-line screen | flutter-architecture-refactoring |
| Implement loyalty points | pos-business-logic-calculations |
| Fix responsive grid | pos-ui-responsive-design |
| Write unit tests | flutter-testing-quality |
| Connect thermal printer | pos-hardware-integration |
| Analyze large cross-file bug | gemini-cli-heavy-lifting |

---

## 🚀 Getting Started

1. **Load a skill**: When you ask a question, the agent automatically loads the relevant skill
2. **Follow guidance**: Each skill provides patterns, examples, and best practices
3. **Build systematically**: Use skills in order (Architecture → Logic → UI → Testing)

---

## 📚 Skill Structure

Each skill includes:
```
skill-name/
├── SKILL.md           # Quick reference and core instructions
├── references/        # Detailed guides (loaded on demand)
│   ├── DETAILED.md    # Complete patterns and examples
│   ├── EXAMPLES.md    # Working code samples
│   └── GUIDE.md       # Step-by-step instructions
└── scripts/           # Executable tools (if applicable)
```

---

## 💡 Example Workflows

### Adding a New Feature
```
1. Design architecture (flutter-architecture-refactoring)
2. Implement logic (pos-business-logic-calculations)
3. Build UI (pos-ui-responsive-design)
4. Write tests (flutter-testing-quality)
```

### Debugging a Bug
```
Identify root cause → Relevant skill → Fix → Add tests
```

### Large-Context Debugging
```
Package context → Use gemini-cli-heavy-lifting → Apply minimal patches → Validate
```

### Improving Code Quality
```
Analyze codebase → Flask of skills → Refactor progressively
```

---

## 📖 Project Context

**Your FlutterPOS App**:
- Multi-flavor Flutter app (POS/KDS/Backend/KeyGen)
- Windows desktop primary, Android tablets secondary
- Three-layer architecture with 500-line file limits
- 100+ unit/integration tests
- SQLite database (sqflite)

All skills are designed specifically for your FlutterPOS codebase patterns.

---

## ✅ Specification Compliance

These skills follow the [Agent Skills Specification](https://agentskills.io/specification):
- ✅ Proper YAML frontmatter with `name`, `description`, `license`, `metadata`
- ✅ Organized directory structure
- ✅ Progressive disclosure (SKILL.md < 500 lines, details in references/)
- ✅ File references use relative paths
- ✅ Clear when-to-use guidance

---

## 🎓 Learning Path

1. **Start with architecture** - Understand three-layer pattern
2. **Learn business logic** - Implement calculations correctly
3. **Master responsive UI** - Build for all screen sizes
4. **Write quality tests** - Ensure code reliability
5. **Integrate hardware** - Complete POS feature set

---

**Last updated**: March 5, 2026  
**FlutterPOS Version**: 1.0.28+  
**Skill Format Version**: 1.0 (Agent Skills Specification)

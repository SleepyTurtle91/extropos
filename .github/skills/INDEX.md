---
name: flutterpos-agent-skills
description: Complete agent skills system for Flutter/Dart development and POS app building. 5 specialized skills covering architecture, business logic, UI design, testing, and hardware integration.
license: Proprietary
compatibility: Flutter 3.0+, Dart 3.0+. Designed for professional POS applications with Windows desktop and Android tablet support.
metadata:
  author: FlutterPOS
  version: "1.0"
  project: FlutterPOS
  totalSkills: 5
---

# FlutterPOS Agent Skills System

Complete, professional-grade agent skills for building and improving your FlutterPOS application.

## 📚 Skills Overview

### 1. **flutter-architecture-refactoring**
```
name: flutter-architecture-refactoring
description: Three-layer architecture, 500-line enforcement, refactoring large files
focus: Code design, organization, maintainability
when: "Help me refactor this 800-line screen", "Design architecture for new feature"
```

**Key Capabilities**:
- Enforce three-layer modular pattern (Layer A/B/C)
- Split monolithic code into focused files
- Plan feature architecture
- Code review against standards

---

### 2. **pos-business-logic-calculations**
```
name: pos-business-logic-calculations
description: Cart operations, tax/discount calculations, payment processing
focus: Accurate financial logic, calculations, validations
when: "Implement loyalty points", "Tax calculation bug", "Payment validation"
```

**Key Capabilities**:
- Cart management patterns
- Price calculations (subtotal, tax, service charge)
- Discount logic
- Payment processing and validation
- Receipt generation

---

### 3. **pos-ui-responsive-design**
```
name: pos-ui-responsive-design
description: Responsive layouts, touch optimization, adaptive design
focus: User interface, responsive design, multiscreen support
when: "Grid looks bad on mobile", "Create responsive screen", "Touch targets too small"
```

**Key Capabilities**:
- Adaptive grid layouts (LayoutBuilder)
- Touch target optimization (48x48 dp)
- Responsive breakpoints
- Multi-orientation support
- POS mode-specific layouts

---

### 4. **flutter-testing-quality**
```
name: flutter-testing-quality
description: Unit tests, widget tests, integration tests, coverage
focus: Code quality, testing, validation
when: "Write tests for service", "Improve coverage", "Test this workflow"
```

**Key Capabilities**:
- Unit testing Layer A (100% target)
- Widget testing Layer B (80%+ target)
- Integration testing workflows
- Mocking and test doubles
- Coverage metrics and goals

---

### 5. **pos-hardware-integration**
```
name: pos-hardware-integration
description: Thermal printers, barcode scanners, payment terminals
focus: Hardware integration, device communication
when: "Connect thermal printer", "Barcode scanner setup", "Handle printer error"
```

**Key Capabilities**:
- Thermal printer integration (58mm/80mm)
- Receipt formatting and printing
- Barcode scanner setup
- Payment terminal integration
- Device discovery and error handling

---

## 🚀 Quick Start

### How Skills Work

1. **Agent loads skills**: When activated, agent reads SKILL.md (this file's sibling)
2. **Provides guidance**: Skill content and patterns loaded on demand
3. **References**: Detailed guides in references/ folder loaded only when needed
4. **Progressive disclosure**: Keep main SKILL.md concise, details in references/

### Example Interaction

```
User: "I have a 750-line CheckoutScreen. Help me refactor it."

Agent:
1. Identifies relevant skill: flutter-architecture-refactoring
2. Loads SKILL.md (checks three-layer architecture rules)
3. References ARCHITECTURE_DETAILED.md for examples
4. Guides refactoring into: CartSummaryService + PaymentWidgets + CheckoutScreen
5. Provides code templates for each layer
6. Recommends unit tests for services
```

---

## 💡 Common Use Cases

### Building a New Feature

**Workflow**: Architecture → Logic → UI → Testing

1. **Plan Architecture** (flutter-architecture-refactoring)
   - Identify concerns (logic, UI, orchestration)
   - Decide file organization
   - Define Layer A services, Layer B widgets, Layer C screens

2. **Implement Logic** (pos-business-logic-calculations)
   - Write pure Dart services
   - Unit test all calculations
   - Validate financial accuracy

3. **Build UI** (pos-ui-responsive-design)
   - Create reusable widgets
   - Implement responsive layouts
   - Test on multiple screen sizes

4. **Write Tests** (flutter-testing-quality)
   - Complete test coverage
   - Unit tests for Layer A
   - Widget/integration tests for UI

### Fixing a Bug

**Workflow**: Identify root → Find right skill → Fix → Test

```
Bug: "Cart total calculation wrong with discount"

→ Check which skill: pos-business-logic-calculations
→ Review: "Tax before or after discount" section
→ Fix: Double-check discount application order
→ Test: Run unit tests in test/services/

Bug: "Grid broken on mobile"

→ Check which skill: pos-ui-responsive-design
→ Review: "Responsive Grid Pattern" section
→ Fix: Add LayoutBuilder with adaptive columns
→ Test: Verify on 400px, 600px, 900px widths
```

### Improving Code Quality

**Workflow**: Analyze → Identify issues → Apply patterns

```
Analysis: File is 850 lines

→ Skill: flutter-architecture-refactoring
→ Action: Run through refactoring checklist
→ Outcome: Split into 5 focused files

Analysis: No tests for payment logic

→ Skill: flutter-testing-quality
→ Action: Follow test patterns
→ Outcome: 100% coverage for payment service
```

---

## 📖 Skill Directory Structure

```
skills/
├── README.md                                  # Main overview
├── INDEX.md                                   # This guide
├── IMPLEMENTATION_CHECKLIST.md                # ✅ Best practices checklist
├── SCRIPTS_IMPLEMENTATION_GUIDE.md            # 📝 Create automated scripts
│
├── flutter-architecture-refactoring/
│   ├── SKILL.md                              # (300 lines) Quick reference
│   ├── scripts/                              # ⏳ Automated validation tools
│   │   ├── validate-architecture.py
│   │   ├── refactor-check.sh
│   │   └── extract-widget.py
│   └── references/
│       ├── ARCHITECTURE_DETAILED.md          # Complete patterns
│       └── REFACTORING_EXAMPLES.md           # Step-by-step examples
│
├── pos-business-logic-calculations/
│   ├── SKILL.md                              # (250 lines) Core patterns
│   ├── scripts/                              # ⏳ Calculation validators
│   │   ├── validate-calculations.py
│   │   ├── test-rounding.py
│   │   └── payment-audit.py
│   └── references/
│       ├── CALCULATIONS_DETAILED.md          # Math explanations
│       ├── PAYMENT_EXAMPLES.md               # Payment flows
│       └── RECEIPT_GUIDE.md                  # Receipt generation
│
├── pos-ui-responsive-design/
│   ├── SKILL.md                              # (280 lines) UI patterns
│   ├── scripts/                              # ⏳ UI validators
│   │   ├── layout-validator.py
│   │   ├── breakpoint-calc.sh
│   │   └── touch-target-auditor.py
│   └── references/
│       ├── UI_PATTERNS.md                    # Component patterns
│       └── RESPONSIVE_EXAMPLES.md            # Responsive code
│
├── flutter-testing-quality/
│   ├── SKILL.md                              # (250 lines) Testing setup
│   ├── scripts/                              # ⏳ Test generators
│   │   ├── coverage-checker.py
│   │   ├── mock-generator.py
│   │   └── test-structure-validator.sh
│   └── references/
│       ├── TEST_PATTERNS.md                  # Test examples
│       └── MOCKING_GUIDE.md                  # Mock patterns
│
└── pos-hardware-integration/
    ├── SKILL.md                              # (300 lines) Integration
    ├── scripts/                              # ⏳ Device tools
    │   ├── printer-discovery.py
    │   ├── receipt-formatter.py
    │   └── device-tester.sh
    └── references/
        ├── PRINTER_SETUP.md                  # Printer configuration
        └── DEVICE_TROUBLESHOOTING.md         # Common issues
```

**Legend**:
- ✅ Complete and ready to use
- ⏳ Planned (SKILL.md ready, scripts pending)

---

## ✨ Key Design Principles

### All Skills Align With Your Project

✅ **FlutterPOS Architecture**
- Three-layer pattern (Layer A/B/C)
- 500-line file maximum
- Dependency injection pattern
- Local setState() state management

✅ **Your Tech Stack**
- Flutter 3.0+, Dart 3.0+
- SQLite (sqflite)
- Android tablets + Windows desktop
- 100+ existing unit/integration tests

✅ **Your Business Domain**
- Multi-flavor POS app (POS/KDS/Backend/KeyGen)
- Cart, payments, receipts, discounts
- Tax/service charge calculations
- Hardware integration (printers, scanners)

### Progressive Disclosure

- **SKILL.md** (~300 lines): Loaded immediately with skill activation
- **references/** files: Loaded on-demand for details
- **Low cognitive load**: Focus on what you need, when you need it

### Practical, Not Theoretical

Every pattern includes:
- ✅ Complete working code examples
- ✅ Integration with your actual project
- ✅ Common mistakes to avoid
- ✅ Testing examples
- ✅ Real-world scenarios

---

## 🎯 Choosing the Right Skill

```
Question: "How do I...?"

├─ "...refactor my code?"
│  └─ flutter-architecture-refactoring
├─ "...calculate totals with tax/discount?"
│  └─ pos-business-logic-calculations
├─ "...make responsive layouts?"
│  └─ pos-ui-responsive-design
├─ "...write unit tests?"
│  └─ flutter-testing-quality
└─ "...connect a printer?"
   └─ pos-hardware-integration
```

---

## 📊 Skills Summary Table

| Skill | Focus | When To Use | Key Files |
|-------|-------|-----------|-----------|
| flutter-architecture-refactoring | Code design | Refactoring, planning | SKILL.md, ARCHITECTURE_DETAILED.md |
| pos-business-logic-calculations | Accurate math | Cart, payments, tax | SKILL.md, CALCULATIONS_DETAILED.md |
| pos-ui-responsive-design | Responsive UI | Screens, layouts, mobile | SKILL.md, RESPONSIVE_EXAMPLES.md |
| flutter-testing-quality | Code quality | Writing tests, coverage | SKILL.md, TEST_PATTERNS.md |
| pos-hardware-integration | Device integration | Printers, scanners | SKILL.md, PRINTER_SETUP.md |

---

## 🔄 Workflow Examples

### Example 1: Add Loyalty Points Feature

```
Step 1: Design (flutter-architecture-refactoring)
  → Create LoyaltyPointsService (Layer A)
  → Create LoyaltyPointsCard (Layer B)
  → Integrate in CheckoutScreen (Layer C)

Step 2: Implement Logic (pos-business-logic-calculations)
  → Implement earnPoints() service
  → Implement redeemPoints() service  
  → Handle discount calculation

Step 3: Build UI (pos-ui-responsive-design)
  → Create responsive card showing points
  → Handle dialog for redemption
  → Test on desktop/tablet

Step 4: Test (flutter-testing-quality)
  → Unit test earning/redemption logic
  → Widget test points display
  → Integration test checkout flow
```

### Example 2: Fix Receipt Calculation Bug

```
Step 1: Identify (pos-business-logic-calculations)
  → Check calculation order
  → Verify tax calculation
  → Review discount application

Step 2: Implement Fix
  → Update CartCalculationService
  → Adjust test expectations

Step 3: Verify (flutter-testing-quality)
  → Run receipt calculation tests
  → Integration test full checkout
  → Validate receipt printing
```

---

## 💻 Using Skills With Your Code

Each skill is designed around your actual FlutterPOS structure:

```
Your Project:
lib/
├── services/              ← Layer A (Skills cover these)
├── widgets/               ← Layer B (Skills cover these)
├── screens/               ← Layer C (Skills cover these)
└── models/

test/
├── services/              ← Skills have test patterns
└── widgets/               ← Skills have test patterns
```

Skills reference your actual:
- Service architecture (`CartService`, `PaymentService`)
- Widget patterns (`CartItemCard`, `PaymentDialog`)
- Screen implementations (`CheckoutScreen`, `RetailPOSScreen`)
- Test organization

---

## � Implementation Guides

**Want to enhance your skills?** See these guides:

- **[IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)** — Best practices from official Agent Skills specification
  - Official guidelines (vs. best practices)
  - Script requirements and patterns
  - VS Code integration setup
  - Success criteria checklist

- **[SCRIPTS_IMPLEMENTATION_GUIDE.md](SCRIPTS_IMPLEMENTATION_GUIDE.md)** — Step-by-step script creation
  - Complete working examples
  - PEP 723 inline dependencies
  - Error handling patterns
  - Testing strategies
  - Quick reference templates

---

## �🚀 Getting Started Now

### You Can Immediately:

1. ✅ Ask to refactor a large file
   - "Refactor my 800-line CheckoutScreen"
   - Agent loads flutter-architecture-refactoring

2. ✅ Request business logic help
   - "How do I apply discounts before tax?"
   - Agent loads pos-business-logic-calculations

3. ✅ Ask about responsive layouts
   - "Make my product grid work on mobile"
   - Agent loads pos-ui-responsive-design

4. ✅ Request test guidance
   - "Write tests for PaymentService"
   - Agent loads flutter-testing-quality

5. ✅ Integrate hardware
   - "Connect a thermal printer"
   - Agent loads pos-hardware-integration

---

## 📞 Quick Help

**"What skill should I use?"** → Check skills table above

**"Where is the detailed version?"** → See references/ folder in skill directory

**"How do I test this?"** → Go to flutter-testing-quality skill

**"Is my design correct?"** → Check flutter-architecture-refactoring for patterns

**"Why is my calculation wrong?"** → Review pos-business-logic-calculations examples

---

## 🎓 Your Advantage

With this complete skill system, you can:

✅ **Build faster** - Patterns and templates reduce decision time  
✅ **Code better** - Proven practices ensure maintainability  
✅ **Test thoroughly** - Complete test patterns included  
✅ **Avoid mistakes** - Anti-patterns highlighted explicitly  
✅ **Scale easily** - Architecture supports growth  
✅ **Debug faster** - Know which skill has the answer  

---

**Ready to level up your FlutterPOS development?**

Start with your next question, and the agent will automatically route you to the right skill! 🚀

---

*FlutterPOS Agent Skills v1.0*  
*Last Updated: March 5, 2026*  
*Specification: Agent Skills v1.0 (agentskills.io)*

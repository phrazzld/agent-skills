# Critique Personas

Channel a specific expert for adversarial feedback on specs, designs, or code.

## Usage

```
/shape --critique <persona> [target]
```

## Personas

| Persona | Lens | Challenges |
|---------|------|------------|
| **grug** | Complexity demon | Over-abstraction, unnecessary layers, big-brain patterns |
| **carmack** | Shippability | Scope creep, premature optimization, not focusing |
| **ousterhout** | Module depth | Shallow modules, pass-through layers, interface complexity |
| **fowler** | Code smells | Duplication, long methods, feature envy, inappropriate intimacy |
| **beck** | Test design | Untestable code, missing TDD, over-mocking |
| **jobs** | Simplicity | Feature bloat, unclear value, lack of craft |
| **torvalds** | Pragmatism | Over-engineering, not shipping, design astronauts |

## Process

1. **Load persona** — Channel the expert's perspective and values
2. **Analyze target** — Review code, design, or plan through their lens
3. **Challenge ruthlessly** — Find flaws the persona would hate
4. **Recommend** — What would they demand you change?

## Output

Structured critique:
- **This {persona} hates:** Specific issues found
- **{Persona} demands:** Required changes
- **{Persona} would approve if:** Conditions for acceptance

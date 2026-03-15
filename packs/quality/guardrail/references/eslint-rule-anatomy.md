# ESLint Custom Rule Anatomy (Flat Config, Local Plugin)

## Overview

ESLint flat config supports local plugins — no npm package needed. Rules live in
your repo, import directly, and run alongside official rules.

## Rule Structure

```javascript
// guardrails/rules/no-direct-db-import.js
export default {
  meta: {
    type: "problem",           // "problem" | "suggestion" | "layout"
    docs: {
      description: "Disallow direct database imports outside repository layer",
      recommended: true,
    },
    fixable: "code",           // "code" | "whitespace" | null
    messages: {
      noDirectDb: "Import db through repository layer: import { db } from '@/lib/repository'. Direct import from '{{source}}' bypasses validation.",
    },
    schema: [],                // JSON Schema for rule options
  },

  create(context) {
    return {
      // AST visitor — node types from estree
      ImportDeclaration(node) {
        const source = node.source.value;

        if (source.includes("/db") && !context.filename.includes("repository")) {
          context.report({
            node,
            messageId: "noDirectDb",
            data: { source },
            fix(fixer) {
              // Optional: auto-fix
              return fixer.replaceText(node.source, "'@/lib/repository'");
            },
          });
        }
      },
    };
  },
};
```

## Key AST Node Types

| Pattern | Node Type | Key Properties |
|---------|-----------|----------------|
| `import { x } from "y"` | `ImportDeclaration` | `source.value`, `specifiers` |
| `require("y")` | `CallExpression` | `callee.name === "require"`, `arguments[0].value` |
| `x.method()` | `MemberExpression` | `object.name`, `property.name` |
| `function f()` | `FunctionDeclaration` | `id.name`, `params`, `body` |
| `const x = ...` | `VariableDeclaration` | `declarations[0].id.name` |

Use https://astexplorer.net with `@typescript-eslint/parser` to explore AST.

## Local Plugin Barrel

```javascript
// guardrails/index.js
import noDirectDbImport from "./rules/no-direct-db-import.js";
import enforceApiPrefix from "./rules/enforce-api-prefix.js";

export default {
  rules: {
    "no-direct-db-import": noDirectDbImport,
    "enforce-api-prefix": enforceApiPrefix,
  },
};
```

## Flat Config Integration

```javascript
// eslint.config.js
import guardrails from "./guardrails/index.js";

export default [
  // ... existing config entries
  {
    plugins: { guardrails },
    rules: {
      "guardrails/no-direct-db-import": "error",
      "guardrails/enforce-api-prefix": ["error", { prefix: "/api/v1" }],
    },
  },
];
```

## Testing with RuleTester

```javascript
// guardrails/rules/no-direct-db-import.test.js
import { RuleTester } from "eslint";
import rule from "./no-direct-db-import.js";

const tester = new RuleTester({ languageOptions: { ecmaVersion: 2022, sourceType: "module" } });

tester.run("no-direct-db-import", rule, {
  valid: [
    { code: `import { db } from "@/lib/repository";` },
    { code: `import { db } from "./db";`, filename: "repository.ts" },
  ],
  invalid: [
    {
      code: `import { db } from "./db";`,
      filename: "service.ts",
      errors: [{ messageId: "noDirectDb" }],
    },
  ],
});
```

Run: `node guardrails/rules/no-direct-db-import.test.js`

## Tips

- **Error messages matter.** Claude reads them to self-correct. Include the fix in the message.
- **Use `messageId`** over inline strings — enables i18n and testing by ID.
- **`context.filename`** gives the file being linted — use for exception logic.
- **`context.options`** gives rule config from eslint.config.js — use for parameterization.
- **Fixable rules** run with `eslint --fix`. Great for mechanical transforms.

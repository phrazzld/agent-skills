// guardrails/rules/RULE_NAME.test.js
import { RuleTester } from "eslint";
import rule from "./RULE_NAME.js";

const tester = new RuleTester({
  languageOptions: { ecmaVersion: 2022, sourceType: "module" },
});

tester.run("RULE_NAME", rule, {
  valid: [
    // Cases that should NOT trigger the rule
    { code: `import { x } from "ALLOWED_SOURCE";` },
    // Exception case (e.g., the module itself)
    { code: `import { x } from "FORBIDDEN_SOURCE";`, filename: "EXCEPTION_FILE" },
  ],
  invalid: [
    // Cases that SHOULD trigger the rule
    {
      code: `import { x } from "FORBIDDEN_SOURCE";`,
      errors: [{ messageId: "violation" }],
    },
  ],
});

console.log("All tests passed.");

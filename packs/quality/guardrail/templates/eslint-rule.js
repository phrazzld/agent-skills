// guardrails/rules/RULE_NAME.js
//
// RULE_DESCRIPTION
//
// Bad:  EXAMPLE_BAD
// Good: EXAMPLE_GOOD

export default {
  meta: {
    type: "problem",
    docs: {
      description: "RULE_DESCRIPTION",
      recommended: true,
    },
    fixable: null, // Set to "code" if auto-fixable
    messages: {
      violation: "MESSAGE_WITH_{{placeholder}}. Fix: SUGGESTION.",
    },
    schema: [],
  },

  create(context) {
    return {
      // Choose the right AST visitor for your pattern:
      // ImportDeclaration, CallExpression, MemberExpression, etc.
      // Use https://astexplorer.net to explore the AST.

      ImportDeclaration(node) {
        const source = node.source.value;

        // Skip exceptions (test files, the module itself, etc.)
        // if (context.filename.includes("EXCEPTION")) return;

        if (/* violation condition */) {
          context.report({
            node,
            messageId: "violation",
            data: { placeholder: source },
            // Uncomment for auto-fix:
            // fix(fixer) {
            //   return fixer.replaceText(node.source, "'CORRECT_IMPORT'");
            // },
          });
        }
      },
    };
  },
};

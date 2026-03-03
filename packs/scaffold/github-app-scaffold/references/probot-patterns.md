# Probot Patterns

Focus on thin webhook glue + deep decision modules.

## Webhook Handler Patterns

Register only the events you need. Keep handlers small.

```ts
import { Probot } from "probot";

export default (app: Probot) => {
  app.on("pull_request.opened", handlePullRequestOpened);
  app.on("issues.opened", handleIssueOpened);
  app.on("push", handlePush);
};
```

PR events:
- Common triggers: `opened`, `reopened`, `synchronize`, `ready_for_review`, `labeled`.
- Use guards early: draft PRs, forks, branch filters, repo allowlists.

Issue events:
- Common triggers: `opened`, `edited`, `labeled`, `closed`, `reopened`.
- Treat edits as partial updates. Re-check all invariants.

Push events:
- Keep minimal. Push can be noisy.
- Prefer branch filters and repo filters.

## Context Usage Patterns

The context gives you routing + auth + helpers.

Useful helpers:
- `context.repo()` for `{ owner, repo }`.
- `context.issue()` for `{ owner, repo, issue_number }`.
- `context.pullRequest()` for PR-scoped params.

```ts
async function handlePullRequestOpened(context: Parameters<Probot["on"]>[1]) {
  const { owner, repo } = context.repo();
  const pr = context.payload.pull_request;

  if (pr.draft) return;

  await context.octokit.issues.createComment({
    ...context.issue({ body: "Thanks for the PR. Running checks." }),
  });
}
```

Pattern:
- Extract `owner/repo` once.
- Normalize payload into a small domain input.
- Pass domain input to pure logic.
- Only then call GitHub APIs.

## GitHub API Patterns with Octokit

Default: use `context.octokit`. It is installation-scoped.

Common calls:

```ts
await context.octokit.issues.addLabels({
  ...context.issue(),
  labels: ["triage", "needs-review"],
});

await context.octokit.pulls.requestReviewers({
  ...context.repo(),
  pull_number: context.payload.pull_request.number,
  reviewers: ["octocat"],
});
```

Patterns that reduce pain:
- Prefer REST endpoints that match your permission scopes.
- Use pagination helpers for lists.
- Use conditional updates when possible (avoid races).
- Make writes idempotent (re-runs should be safe).

Pagination:

```ts
const files = await context.octokit.paginate(
  context.octokit.pulls.listFiles,
  {
    ...context.repo(),
    pull_number: context.payload.pull_request.number,
    per_page: 100,
  },
);
```

## Authentication Handling

Inside handlers:
- Use `context.octokit` for installation auth.

Outside handlers (cron, queues, backfills):
- Use `@octokit/app` and auth per installation.

```ts
import { App } from "@octokit/app";
import { Octokit } from "@octokit/rest";

const app = new App({
  appId: Number(process.env.APP_ID),
  privateKey: process.env.PRIVATE_KEY!,
});

const installationAuth = await app.getInstallationOctokit(installationId);
// installationAuth is an Octokit instance
```

Rule:
- Never share installation tokens across tenants.
- Keep installationId explicit at module boundaries.

## Rate Limiting Strategies

Expect bursts on large orgs.

Tactics:
- Minimize API calls per event.
- Cache cheap reads within a handler.
- Prefer bulk endpoints when available.
- Defer heavy work to queues.
- Use Octokit throttling/retry plugins when needed.

Practical guards:
- Drop events you do not act on.
- Use repo/org allowlists.
- Skip unchanged work (labels already applied, comment exists).

## Testing with probot-testing

Test the webhook surface, not only pure logic.

Typical approach:
- Spin up Probot app in tests.
- Feed webhook payload fixtures.
- Assert on Octokit calls or resulting state.

Keep most logic in pure modules:
- Unit test decision logic first.
- Use Probot tests to cover integration glue.

## Error Handling

Most errors are permission, race, or missing state.

Pattern:

```ts
try {
  // GitHub writes
} catch (err: any) {
  const status = err?.status;

  // Common non-fatal cases
  if (status === 404 || status === 422) {
    context.log.warn({ err }, "Non-fatal GitHub API error");
    return;
  }

  context.log.error({ err }, "Unhandled GitHub App error");
  throw err;
}
```

Guidelines:
- Treat 404/422 as common and often safe to swallow.
- Fail loud on unexpected statuses.
- Make side effects idempotent to survive retries.
- Log with context (owner, repo, event, installationId).


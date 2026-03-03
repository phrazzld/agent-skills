# Bolt Patterns (JavaScript)

Use these as defaults. Keep listeners thin, push logic into services.

## Event Handling Patterns

```js
// app/listeners/events/app_mention.js
module.exports = (app, services) => {
  app.event("app_mention", async ({ event, say, logger }) => {
    try {
      const reply = await services.mentions.handle(event);
      await say(reply);
    } catch (err) {
      logger.error(err);
      await say("Something went wrong.");
    }
  });
};
```

Notes:
- Filter early. Ignore bot messages and noise.
- Pass `event` into a service, return a user-safe response.

## Slash Command Patterns

```js
// app/listeners/commands/run_report.js
module.exports = (app, services) => {
  app.command("/run-report", async ({ command, ack, respond, logger }) => {
    await ack();

    try {
      const result = await services.reports.run(command);
      await respond(result.message);
    } catch (err) {
      logger.error(err);
      await respond("Report failed. Try again.");
    }
  });
};
```

Notes:
- `ack()` immediately.
- Use `respond()` for follow-ups.

## Modal / View Patterns

```js
// open modal
app.command("/intake", async ({ ack, body, client, logger }) => {
  await ack();

  try {
    await client.views.open({
      trigger_id: body.trigger_id,
      view: services.intake.buildModal(),
    });
  } catch (err) {
    logger.error(err);
  }
});

// handle submit
app.view("intake_submit", async ({ ack, view, body, client, logger }) => {
  await ack();

  try {
    const payload = services.intake.parseSubmission(view);
    await services.intake.handle(payload, body.user.id);
    await client.chat.postMessage({
      channel: body.user.id,
      text: "Received.",
    });
  } catch (err) {
    logger.error(err);
  }
});
```

Notes:
- Build views in services.
- Parse submissions in one place.

## Action Handlers

```js
app.action("approve_request", async ({ ack, body, client, logger }) => {
  await ack();

  try {
    await services.approvals.approve(body);
    await client.chat.postMessage({
      channel: body.user.id,
      text: "Approved.",
    });
  } catch (err) {
    logger.error(err);
  }
});
```

Notes:
- Action IDs are stable interface contracts.
- Keep action handlers short; delegate.

## Middleware Patterns

```js
// app/middleware/require_workspace.js
module.exports = (allowedTeamIds) => {
  return async ({ body, context, next, logger }) => {
    const teamId = body.team?.id || context.teamId;
    if (!allowedTeamIds.includes(teamId)) {
      logger.warn({ teamId }, "Blocked workspace");
      return;
    }
    await next();
  };
};
```

Usage:

```js
app.use(requireWorkspace(["T123", "T456"]));
```

## Error Handling

```js
// top-level handler
app.error(async (error) => {
  console.error("Bolt error", error);
});
```

Guidelines:
- Always `ack()` before slow work.
- Fail user-visible, not silent.
- Log raw errors; show safe messages.

## Testing Strategies

- Unit test services first (pure logic).
- Listener tests: mock Bolt args (`ack`, `say`, `client`).
- Contract tests: assert required scopes and IDs exist in manifest.

Minimal listener test shape:

```js
test("run-report command responds", async () => {
  const ack = jest.fn();
  const respond = jest.fn();
  const services = { reports: { run: async () => ({ message: "ok" }) } };

  await handler({ command: { text: "" }, ack, respond, logger: console });

  expect(ack).toHaveBeenCalled();
  expect(respond).toHaveBeenCalledWith("ok");
});
```


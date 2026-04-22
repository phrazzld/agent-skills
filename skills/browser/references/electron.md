# Electron Testing

Electron is Chromium + Node in one process tree. Testing needs to reach
**both**: renderer (the web UI) and main (the Node side: menus, IPC,
dialogs, native integrations).

## Spectron is deprecated

Spectron was the original Electron test framework. It was archived in
2022 and has been broken for modern Electron for years. Migrate away
from any Spectron setup you encounter. The one-line answer to "how do
I test Electron" is **Playwright**.

## Playwright is the canonical answer

Playwright ships `_electron` — first-class Electron support from the
same vendor that builds Chromium. Launch the app, get the main process,
iterate the renderer windows, and interact with either side.

### Minimal setup

```typescript
import { _electron as electron, ElectronApplication, Page } from 'playwright';
import { test, expect } from '@playwright/test';

let app: ElectronApplication;
let window: Page;

test.beforeAll(async () => {
  app = await electron.launch({ args: ['main.js'] });
  window = await app.firstWindow();
});

test.afterAll(async () => {
  await app.close();
});

test('app boots and shows login', async () => {
  await expect(window.getByRole('heading', { name: 'Log in' })).toBeVisible();
});
```

### Evaluating in the main process

The `app.evaluate()` method runs a function in the main Electron
process. Use it to inspect the real `app` module (version, paths,
menus) or to drive main-side APIs.

```typescript
const appPath = await app.evaluate(({ app }) => app.getAppPath());
```

## electron-playwright-helpers

Third-party helper library (`spaceagetv/electron-playwright-helpers`).
Bridges the gaps Playwright itself doesn't cover:

- **Menu clicks** — `clickMenuItemById(app, 'file.open')` triggers a
  native menu item from its id.
- **IPC** — send / stub IPC messages between main and renderer under
  test control.
- **Dialog stubbing** — pre-load return values for
  `dialog.showOpenDialog()` so the test doesn't hang on the native
  picker.
- **Menu introspection** — read the full menu structure for assertion.
- **Packaged-app parsing** — auto-locate the built binary in
  `dist/`/`out/` so CI tests the packaged artifact, not the source.

### Install

```bash
npm i -D electron-playwright-helpers
```

### Example — click a menu item

```typescript
import { clickMenuItemById } from 'electron-playwright-helpers';
await clickMenuItemById(app, 'file.newWindow');
```

### Example — stub a file-picker dialog

```typescript
import { stubDialog } from 'electron-playwright-helpers';
await stubDialog(app, 'showOpenDialog', {
  filePaths: ['/tmp/fixture.json'],
  canceled: false,
});
```

## Testing the packaged binary, not the source

Playwright's `electron.launch({ args: ['main.js'] })` runs your source
tree under Node. This is fine for development but misses regressions
that only surface after packaging (ASAR issues, native modules,
resource paths, code-signing hooks).

`electron-playwright-helpers` exposes `findLatestBuild()` +
`parseElectronApp()` to point Playwright at the actual packaged app:

```typescript
import { findLatestBuild, parseElectronApp } from 'electron-playwright-helpers';

const latestBuild = findLatestBuild();
const appInfo = parseElectronApp(latestBuild);
const app = await electron.launch({
  args: [appInfo.main],
  executablePath: appInfo.executable,
});
```

Run this variant in CI on the packaged artifact as a separate job from
source tests.

## Cross-platform gotchas

- **Menu ids differ by OS.** macOS has an app menu (`My App ▸ Quit`)
  that Windows/Linux don't. Gate menu tests by `process.platform` or
  test both.
- **Native dialogs block the test process** if not stubbed. Always stub
  `dialog.showOpenDialog`, `dialog.showSaveDialog`,
  `dialog.showMessageBox` before triggering them.
- **Auto-updater** must be disabled in test builds — Squirrel events
  fire on launch and can block or alter behavior.
- **DevTools auto-open** (common dev-time default) can steal focus from
  `firstWindow()`. Disable in test builds or call `close()` on the
  DevTools page.
- **BrowserWindow race** — if your app creates multiple windows on
  launch, `firstWindow()` returns whichever is ready first. Use
  `app.waitForEvent('window')` for deterministic ordering.

## What this does **not** cover

- **Visual regression of native chrome** — Playwright sees the renderer
  content, not the OS-drawn title bar. If you need to assert the native
  frame, reach for a platform-native tool (macOS: XCUITest; Windows:
  WinAppDriver).
- **macOS keychain / Windows credential manager** — test-double at the
  module level instead.

## What about AI wrappers for Electron?

Stagehand and Browser Use target web pages, not Electron main processes.
You can point either at an already-running Electron window by connecting
over CDP (Electron exposes CDP on a port when launched with
`--remote-debugging-port=<port>`), but you lose main-process access
and dialog/menu control. **For Electron: just use Playwright.**

## Docs

- https://playwright.dev/docs/api/class-electronapplication
- https://github.com/spaceagetv/electron-playwright-helpers
- https://github.com/spaceagetv/electron-playwright-example

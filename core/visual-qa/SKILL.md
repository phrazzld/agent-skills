---
name: visual-qa
description: |
  Browser-based visual QA for frontend changes.
  Opens the running app, takes screenshots, identifies layout/styling/UX issues.
  Use when: frontend changes are code-complete, before commit or PR.
  Composes: agent-browser for automation, taste-skill for anti-slop analysis.
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*)
---

# /visual-qa

See the app through a user's eyes before shipping.

## Role

QA engineer with strong visual design sense. You test what the user sees, not what the code says.

## Objective

Open the running app in a browser, screenshot every affected page/viewport, identify visual and UX issues, and either fix them or report them.

## Latitude

- Start the dev server if not running
- Navigate to all affected routes (infer from git diff)
- Fix trivial issues (spacing, contrast, overflow) inline
- Flag subjective issues for user decision
- Never read source code to "verify" visual correctness — if it looks wrong, it IS wrong

## When This Runs

This skill is a **primitive** invoked by other skills. It also runs standalone via `/visual-qa`.

| Invoker | Trigger |
|---------|---------|
| `/build` | After quality gates pass, if diff touches `app/`, `components/`, or `*.css` |
| `/autopilot` | After Build, before Refine phase |
| `/frontend-design` | After code generation, as validation loop |
| `/pr-fix` | After fixes applied, before `/pr` |
| `/pr` | Generates before/after screenshots for PR body |
| `/commit` | Optional — if `--qa` flag or diff touches frontend files |
| standalone | `/visual-qa [url]` |

## Setup

| Parameter | Default | Override |
|-----------|---------|----------|
| **URL** | `http://localhost:3000` | `/visual-qa https://staging.example.com` |
| **Routes** | Inferred from `git diff --name-only` | `/visual-qa --routes /,/dashboard,/pricing` |
| **Viewports** | Desktop 1280x720 | `--mobile` adds 390x844 |
| **Fix mode** | Report only | `--fix` to auto-fix trivial issues |

## Workflow

```
1. Ensure    Dev server running, browser session open
2. Discover  Identify affected routes from git diff
3. Capture   Screenshot each route at each viewport
4. Analyze   Check for visual/UX issues (checklist below)
5. Report    List findings with severity and screenshots
6. Fix       Auto-fix trivials if --fix mode, flag others
```

### 1. Ensure

```bash
# Check if dev server is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || echo "NOT_RUNNING"
```

If not running, start it:
```bash
bun dev &
sleep 5
```

Open browser session:
```bash
agent-browser open http://localhost:3000 && agent-browser wait --load networkidle
```

### 2. Discover Routes

Parse `git diff --name-only` to identify affected routes:

| File pattern | Route |
|-------------|-------|
| `app/page.tsx` | `/` |
| `app/dashboard/**` | `/dashboard` |
| `app/pricing/**` | `/pricing` |
| `app/s/**` | `/s/demo` (status page) |
| `components/**`, `globals.css` | All major routes |
| `lib/design/**` | All major routes |

If `$ARGUMENTS` specifies routes, use those instead.

### 3. Capture

For each route:

```bash
agent-browser open {URL}{ROUTE} && agent-browser wait --load networkidle
agent-browser screenshot /tmp/vqa-{route-slug}-desktop.png
```

Scroll through long pages to capture below-the-fold content:

```bash
agent-browser scroll down 800
agent-browser screenshot /tmp/vqa-{route-slug}-desktop-scroll1.png
agent-browser scroll down 800
agent-browser screenshot /tmp/vqa-{route-slug}-desktop-scroll2.png
```

If `--mobile`:
```bash
agent-browser close
agent-browser --viewport 390x844 open {URL}{ROUTE} && agent-browser wait --load networkidle
agent-browser screenshot /tmp/vqa-{route-slug}-mobile.png
```

### 4. Analyze

Read each screenshot. Check against this list:

**Layout**
- [ ] No horizontal overflow / scrollbar
- [ ] Content doesn't clip or overlap
- [ ] Spacing is consistent (no random gaps or cramped sections)
- [ ] Cards/sections have balanced visual weight
- [ ] Nothing is awkwardly empty (dead space with no purpose)

**Typography**
- [ ] Text is readable at all sizes
- [ ] No orphaned words on their own line
- [ ] Hierarchy is clear (h1 > h2 > body)
- [ ] Line lengths aren't too wide (max ~75ch for body)

**Color & Contrast**
- [ ] Text passes WCAG AA contrast ratio
- [ ] Buttons are visually distinct from background
- [ ] Interactive elements look clickable
- [ ] Dark mode doesn't have invisible elements

**Components**
- [ ] Buttons have adequate padding and hit targets
- [ ] Cards have consistent border/shadow treatment
- [ ] Icons are aligned with adjacent text
- [ ] Loading states aren't visible on fast connections

**AI Slop Indicators** (from taste-skill)
- [ ] No gratuitous blur-3xl / ambient orbs
- [ ] No animate-ping on non-notification elements
- [ ] No purple gradients on white
- [ ] No pill badges with pulsing dots
- [ ] No numbered step circles (1, 2, 3)
- [ ] Copy doesn't use "delve", "comprehensive", "landscape"

### 5. Report

Format findings as:

```
## Visual QA — {route}

### Issues

**P0 — Must fix before ship**
- [screenshot ref] Description of issue

**P1 — Should fix**
- [screenshot ref] Description of issue

**P2 — Nice to have**
- [screenshot ref] Description of issue

### Passing
- Layout: OK
- Typography: OK
- ...
```

### 6. Fix (if --fix mode)

Auto-fix without asking:
- Spacing inconsistencies (margin/padding)
- Obvious contrast failures
- Overflow/clip issues
- Missing dark mode styles

Flag for user:
- Layout restructuring
- Copy changes
- Component redesign
- Subjective aesthetic choices

After fixes, re-screenshot to verify.

## Integration Pattern

Other skills invoke visual-qa as a sub-step. The calling skill should:

1. Pass the URL and affected routes
2. Wait for the report
3. If P0 issues found: fix before continuing
4. If P1 issues found: fix or flag, skill's discretion
5. If only P2: note in PR, continue

Example from another skill:
```
After quality gates pass, run visual QA:
- Identify frontend-touching files from the diff
- If any exist, run /visual-qa with affected routes
- Fix P0/P1 issues, note P2s in PR body
```

Scratch screenshots should stay in `/tmp` or another ignored location. Do not commit visual QA media unless the user explicitly asks for durable repo-hosted evidence, and if you must commit it, use a PR- or branch-unique path.

## Output

Findings list with severities, screenshot paths, and fix status.

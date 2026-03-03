# Expo + Turborepo Monorepo Reference

Goal: make Expo apps resolve shared packages predictably.

## metro.config.js for monorepo

Put this in each Expo app (for example `apps/mobile/metro.config.js`).

```js
// apps/mobile/metro.config.js
const path = require("path");
const { getDefaultConfig } = require("@expo/metro-config");

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, "../..");

const config = getDefaultConfig(projectRoot);

config.watchFolders = [
  workspaceRoot,
];

config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules"),
];

// Avoid Metro walking up random parent folders.
config.resolver.disableHierarchicalLookup = true;

module.exports = config;
```

## package.json watchFolders

Keep watch folders centralized, then read them in Metro.

```json
{
  "name": "@acme/mobile",
  "private": true,
  "expo": {
    "watchFolders": ["../.."]
  }
}
```

Then in `metro.config.js`, replace the `watchFolders` block:

```js
const pkg = require("./package.json");
config.watchFolders = (pkg.expo?.watchFolders || []).map((folder) =>
  path.resolve(projectRoot, folder)
);
```

## Shared package imports

Prefer workspace packages, not relative deep paths.

```ts
// good
import { Button } from "@acme/ui";
import { api } from "@acme/api";
```

Checklist for shared packages:

- Every shared package has a `name` like `@acme/ui`.
- Every shared package has a clear entry (`main`, `module`, or `exports`).
- Avoid React Native code that runs at import-time in shared packages.
- Keep shared packages platform-agnostic unless clearly labeled.

## TypeScript path aliases across apps

Unify at repo root, then extend per app.

Root `tsconfig.base.json`:

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@acme/ui": ["packages/ui/src/index.ts"],
      "@acme/api": ["packages/api/src/index.ts"],
      "@acme/config/*": ["packages/config/src/*"]
    }
  }
}
```

App `tsconfig.json`:

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "baseUrl": "."
  },
  "include": ["**/*.ts", "**/*.tsx"]
}
```

Make Babel agree (Expo uses Babel at runtime):

```js
// apps/mobile/babel.config.js
const path = require("path");

module.exports = function (api) {
  api.cache(true);

  const projectRoot = __dirname;
  const workspaceRoot = path.resolve(projectRoot, "../..");

  return {
    presets: ["babel-preset-expo"],
    plugins: [
      [
        "module-resolver",
        {
          root: [projectRoot],
          alias: {
            "@acme/ui": path.resolve(workspaceRoot, "packages/ui/src"),
            "@acme/api": path.resolve(workspaceRoot, "packages/api/src"),
          },
        },
      ],
    ],
  };
};
```

## Common issues and fixes

Symptom: “Tried to register two views with the same name” or hooks break.

- Cause: multiple React or React Native copies.
- Fix: ensure `react`, `react-native`, and `expo` are only in app deps, and shared packages list them as `peerDependencies`.

Symptom: Metro cannot resolve a shared package.

- Fix: confirm package `name`, entry file, and that Metro `watchFolders` includes the workspace root.
- Fix: clear caches: run `expo start -c`.

Symptom: TypeScript compiles but runtime fails.

- Cause: TS path aliases not mirrored in Babel.
- Fix: add `module-resolver` aliases that point to real paths.

Symptom: Changes in `packages/*` are not picked up.

- Fix: ensure `watchFolders` includes the workspace root, not only `packages`.
- Fix: avoid generated files outside the workspace root.


# EAS Setup Reference

Goal: ship repeatable builds with clear profiles and secrets.

## eas.json profiles

Start here, then tune per app.

```json
{
  "cli": {
    "version": ">= 12.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "channel": "development",
      "env": {
        "APP_ENV": "development"
      }
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview",
      "env": {
        "APP_ENV": "preview"
      }
    },
    "production": {
      "autoIncrement": true,
      "channel": "production",
      "env": {
        "APP_ENV": "production"
      }
    }
  },
  "submit": {
    "production": {}
  }
}
```

Recommended mapping:

- `development`: dev client + internal distribution.
- `preview`: QA and stakeholder builds.
- `production`: store-ready builds and submissions.

## Build configuration options

Common toggles you will actually use:

- `developmentClient`: true for dev client builds.
- `distribution`: `internal` for non-store installs.
- `autoIncrement`: bump versions safely in CI.
- `channel`: pair with OTA updates strategy.
- `env`: per-profile environment variables.

Typical build commands:

```bash
npx eas-cli@latest login
npx eas-cli@latest build:configure
npx eas-cli@latest build --platform ios --profile preview
npx eas-cli@latest build --platform android --profile production
```

## Environment variables and secrets

Use EAS secrets for sensitive values. Use `env` for non-sensitive toggles.

Create secrets:

```bash
npx eas-cli@latest secret:create --name SENTRY_AUTH_TOKEN --value "$SENTRY_AUTH_TOKEN"
npx eas-cli@latest secret:list
```

Pull secrets locally when needed:

```bash
npx eas-cli@latest secret:pull --environment preview
```

Rules:

- Never commit secrets.
- Use `APP_ENV` to branch behavior, not many flags.
- Keep per-profile `env` small and obvious.

## Credentials management

Let EAS manage credentials unless you have a strong reason not to.

Key flows:

```bash
npx eas-cli@latest credentials
npx eas-cli@latest build --platform ios --profile production
npx eas-cli@latest build --platform android --profile production
```

Guidance:

- For iOS, EAS can create and store certificates and profiles.
- For Android, EAS can manage the keystore. Back it up once.
- If you bring your own credentials, document where they live.

## OTA updates configuration

Use channels deliberately. Treat them like environments.

Minimal strategy:

- `development` channel: fast iteration.
- `preview` channel: QA validation.
- `production` channel: customer traffic.

Common commands:

```bash
npx eas-cli@latest update:configure
npx eas-cli@latest update --branch preview --message "QA: build 123"
npx eas-cli@latest channel:edit production --branch production
```

Keep update targeting simple:

- Align `build.production.channel` with your production OTA channel.
- Avoid many branches; it becomes invisible coupling.

## CI/CD integration with EAS

Make CI explicit and boring.

Baseline CI steps:

1. Install deps with the repo’s package manager.
2. Run typecheck and tests.
3. Run `eas build` with a clear profile.
4. Optionally run `eas submit`.

Example CI build step:

```bash
npx eas-cli@latest build --non-interactive --platform all --profile preview
```

Notes:

- Use `--non-interactive` in CI.
- Use EAS secrets, not CI plaintext env vars, for sensitive values.
- Keep build profiles stable; change code, not infra knobs.


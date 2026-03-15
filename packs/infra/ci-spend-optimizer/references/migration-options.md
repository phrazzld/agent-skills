# CI Runner and Platform Options

Use this matrix when GitHub Actions minutes become the bottleneck.

## Decision matrix

| Option | Best for | Strengths | Risks |
|---|---|---|---|
| GitHub-hosted Actions only | Small/medium repos, simple pipelines | Zero infra, best GitHub UX, fastest setup | Minute caps/cost, limited control on large workloads |
| GitHub Actions + self-hosted runners | Heavy integration/e2e, private infra access | Keep Actions UX/checks, avoid hosted-minute burn, custom hardware | Runner security hardening, autoscaling ops burden |
| Buildkite + GitHub checks | High-volume orgs with mature infra | Strong queue control, elastic agent fleets, deep pipeline control | New platform to operate, migration complexity |
| CircleCI + GitHub app/checks | Teams already using CircleCI orbs/features | Rich ecosystem, dynamic config support | Credit model and config divergence from Actions |
| Azure Pipelines + GitHub | Microsoft-heavy stack, enterprise governance | Enterprise policy controls, GitHub integration | Additional platform and YAML model to maintain |

## Practical split pattern

1. Keep PR lint/unit/typecheck in GitHub Actions.
2. Move long-running integration/e2e/perf jobs off GitHub-hosted runners.
3. Report results back as GitHub checks on the same PR.
4. Keep one merge gate that is stable and deterministic.

## Migration readiness checklist

- Current top 10 workflows account for >=70% of minute burn.
- Workloads selected for migration are deterministic and cache-friendly.
- Secrets and network requirements documented.
- Rollback path defined (one-click re-enable old workflow).
- SLO defined for queue latency and median feedback time.

# Structured Logging

Best practices for production-ready logging in Node.js applications using Pino and structured JSON output.

## Philosophy

**Logs are data, not text.** Structured logging treats every log entry as a queryable data point.

1. **Machine-readable first**: JSON structure enables programmatic querying
2. **Context-rich**: Include all relevant metadata (correlation IDs, user IDs, request info)
3. **Security-conscious**: Never log sensitive data (passwords, tokens, PII)

## Why Pino

- **5x faster than Winston**: Minimal CPU overhead, async by default
- **Structured JSON**: Every log is a JSON object, no string templates
- **Async transports**: Heavy operations in worker threads
- **Child loggers**: Easy context propagation
- **Redaction built-in**: Automatic sensitive data removal

## Basic Configuration

```typescript
// lib/logger.ts
import pino from 'pino'

const isDevelopment = process.env.NODE_ENV === 'development'

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: isDevelopment
    ? { target: 'pino-pretty', options: { colorize: true, translateTime: 'SYS:standard', ignore: 'pid,hostname' } }
    : undefined,
  base: {
    env: process.env.NODE_ENV || 'development',
    revision: process.env.VERCEL_GIT_COMMIT_SHA || 'local',
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  redact: {
    paths: [
      'password', 'passwordHash', 'secret', 'apiKey', 'token',
      'accessToken', 'refreshToken', 'authorization', 'cookie',
      'req.headers.authorization', 'req.headers.cookie',
      '*.password', '*.passwordHash', '*.secret', '*.apiKey', '*.token',
    ],
    censor: '[REDACTED]',
  },
})
```

## Log Levels

```typescript
logger.trace('Extremely detailed debugging')  // Level 10
logger.debug('Detailed debugging')            // Level 20
logger.info('General information')            // Level 30
logger.warn('Warning, non-critical issue')    // Level 40
logger.error('Error, requires attention')     // Level 50
logger.fatal('Fatal error, app cannot continue') // Level 60
```

**Production recommendation**: Set `LOG_LEVEL=info` by default.

## Child Loggers (Context Propagation)

```typescript
const requestLogger = logger.child({ userId: '123', requestId: 'abc' })
requestLogger.info('User logged in')
requestLogger.info('Profile fetched')
```

### Middleware Pattern

```typescript
import { v4 as uuidv4 } from 'uuid'

export function createRequestLogger(req: NextRequest) {
  const correlationId = req.headers.get('x-correlation-id') || uuidv4()
  return logger.child({
    correlationId,
    method: req.method,
    path: req.nextUrl.pathname,
  })
}
```

## Patterns

### Good: Structured Fields
```typescript
logger.info({
  event: 'user_login',
  userId: user.id,
  provider: 'google',
  duration: 150,
}, 'User authenticated')
```

### Bad: String Templates
```typescript
logger.info(`User ${user.email} logged in via ${provider} in ${duration}ms`)
```

### Error Logging
```typescript
try {
  await riskyOperation()
} catch (error) {
  logger.error({
    error,
    operation: 'riskyOperation',
    userId: user.id,
    retryCount: 3,
  }, 'Operation failed after retries')
}
```

**Note on Error serialization:** `JSON.stringify(new Error("msg"))` returns `{}` because `message`, `name`, `stack` are non-enumerable. Pino handles this natively. For custom loggers:

```typescript
function serializeError(err: unknown): Record<string, unknown> {
  if (err instanceof Error) {
    return { name: err.name, message: err.message, stack: err.stack };
  }
  return { value: String(err) };
}
```

## Correlation IDs

```typescript
export function correlationMiddleware(req, res, next) {
  const correlationId = req.headers['x-correlation-id'] || uuidv4()
  res.setHeader('x-correlation-id', correlationId)
  req.log = logger.child({ correlationId })
  next()
}
```

## Centralization

### Datadog
```typescript
const logger = pino({
  transport: {
    target: 'pino-datadog-transport',
    options: { apiKey: process.env.DATADOG_API_KEY, service: 'my-app', env: process.env.NODE_ENV },
  },
})
```

### Vercel Log Drains
Vercel automatically collects logs and can forward to Datadog, LogDNA, Logtail, New Relic, Sentry, or custom HTTPS endpoints.

## Rules

- **Do**: Use structured JSON, include context, use correlation IDs, redact sensitive data, use child loggers, centralize in production
- **Don't**: Use string templates, log sensitive data, log in tight loops, ignore log levels, use console.log in production, skip correlation IDs

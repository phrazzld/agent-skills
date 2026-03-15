# Architecture Decisions

## Port vs System.cmd for CLI Agent Dispatch

**Use Port, not System.cmd.** Agent CLIs (pi, aider, codex) are long-running processes.
System.cmd blocks the calling process until completion. Port gives you:
- Streaming stdout/stderr (progress tracking, token counting)
- Ability to kill the process on timeout
- Non-blocking — the GenServer remains responsive

```elixir
defmodule Amos.Agent.Run do
  use GenServer

  def init(state) do
    port = Port.open({:spawn_executable, pi_path()}, [
      :binary, :exit_status, :stderr_to_stdout,
      args: ["-p", "--no-session", "--mode", "json",
             "--model", state.model,
             "--append-system-prompt", state.prompt_file,
             state.task]
    ])
    {:ok, %{state | port: port}}
  end

  def handle_info({port, {:data, data}}, %{port: port} = state) do
    # Parse Pi JSON events, track tokens, detect progress
    {:noreply, process_agent_output(state, data)}
  end

  def handle_info({port, {:exit_status, code}}, %{port: port} = state) do
    # Agent finished — validate, create PR, cleanup
    {:stop, :normal, handle_completion(state, code)}
  end
end
```

## GenServer vs Task for Agent Runs

**Use GenServer.** Tasks are for fire-and-forget or short-lived work.
Agent runs need:
- Internal state machine (triage → fix → validate → PR)
- Timeout management (Process.send_after for watchdogs)
- Graceful cleanup on shutdown (terminate/2 for worktree cleanup)
- Progress querying (handle_call for status checks)

```elixir
# State machine inside the GenServer
defp advance(%{phase: :triage} = state, result) do
  case parse_triage(result) do
    {:fixable, triage} -> start_fixer(state, triage)
    {:unfixable, reason} -> comment_and_stop(state, reason)
    :malformed -> comment_and_stop(state, "triage failed")
  end
end

defp advance(%{phase: :fix} = state, result) do
  case validate_fix(state) do
    :clean -> create_pr(state)
    {:violation, details} -> comment_and_stop(state, details)
    :no_changes -> comment_and_stop(state, "no fix produced")
  end
end
```

## ETS vs GenServer for Registry

**Use ETS.** The registry maps repos to active runs and attempt counts.
- Reads are concurrent (many agent runs checking cooldowns)
- Writes are infrequent (only on start/stop)
- ETS reads don't serialize through a single process
- Survives agent crashes (owned by the supervisor, not the agent)

```elixir
defmodule Amos.Registry do
  def init do
    :ets.new(__MODULE__, [:set, :public, :named_table,
                           read_concurrency: true])
  end

  def can_attempt?(repo, max_attempts) do
    case :ets.lookup(__MODULE__, repo) do
      [{^repo, count, _last}] -> count < max_attempts
      [] -> true
    end
  end

  def record_attempt(repo) do
    :ets.update_counter(__MODULE__, repo, {2, 1}, {repo, 0, nil})
    :ets.update_element(__MODULE__, repo, {3, DateTime.utc_now()})
  end
end
```

## Rate Limiter Design

Token bucket per model, shared across all agent runs:

```elixir
defmodule Amos.RateLimiter do
  use GenServer

  def request_tokens(model, tokens_needed) do
    GenServer.call(__MODULE__, {:request, model, tokens_needed}, :infinity)
  end

  def handle_call({:request, model, needed}, from, state) do
    bucket = Map.get(state.buckets, model, new_bucket(model))
    bucket = refill(bucket)

    if bucket.tokens >= needed do
      bucket = %{bucket | tokens: bucket.tokens - needed}
      {:reply, :ok, put_in(state.buckets[model], bucket)}
    else
      # Queue the request, reply when tokens available
      queue = [{from, needed} | Map.get(state.queues, model, [])]
      {:noreply, put_in(state.queues[model], queue)}
    end
  end
end
```

## Graceful Shutdown

The terminate/2 callback handles cleanup:

```elixir
def terminate(_reason, state) do
  # Kill the Pi process if still running
  if state.port, do: Port.close(state.port)

  # Clean up git worktree
  if state.worktree do
    System.cmd("git", ["worktree", "remove", "--force", state.worktree])
  end

  # Clean up temp files
  File.rm_rf(state.temp_dir)
end
```

## Why Not Go/Rust/Python?

| Concern | Elixir/OTP | Go | Python | Rust |
|---|---|---|---|---|
| Process supervision | Built-in (OTP) | Manual goroutine mgmt | Celery/dramatiq | Tokio tasks |
| Crash isolation | Process boundaries | Goroutine panic kills process | Exception propagation | panic! kills thread |
| Rate limiting | GenServer (trivial) | Channel-based (manual) | asyncio.Semaphore | tokio::sync |
| Hot config reload | Built-in | Requires restart | Requires restart | Requires restart |
| Long-running process mgmt | First-class (GenServer) | Context cancellation | asyncio tasks | tokio::spawn |
| Webhook handling | Phoenix (battle-tested) | net/http (fine) | FastAPI (fine) | Axum (fine) |
| CLI subprocess streaming | Port (first-class) | os/exec (fine) | subprocess (fine) | Command (fine) |

Go is the closest competitor. The key Elixir advantage: **supervision trees make crash recovery declarative, not imperative.** With 200 concurrent agent processes, you don't write recovery code — you declare restart strategies.

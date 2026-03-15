# Domain State Machine Skeletons

Copy-paste PlusCal skeletons for common domains.

## Payment Flow

```
(*--algorithm PaymentFlow
variables
  payment_state = "created",
  charge_count = 0,
  refund_requested = FALSE;

process gateway = "gateway"
begin
  Loop:
    while payment_state \notin {"completed", "failed", "refunded"} do
      either
        \* Attempt charge
        await payment_state = "created" \/ payment_state = "retry";
        either
          payment_state := "completed";
          charge_count := charge_count + 1;
        or
          payment_state := "retry";
        end either;
      or
        \* Timeout
        await payment_state = "retry";
        payment_state := "failed";
      end either;
    end while;

  Refund:
    await refund_requested /\ payment_state = "completed";
    payment_state := "refunded";
end process;

end algorithm; *)

NoDoubleCharge == charge_count <= 1
RefundOnlyAfterCharge == payment_state = "refunded" => charge_count = 1
```

## Auth Session

```
(*--algorithm AuthSession
variables
  session_state = "unauthenticated",
  token_valid = FALSE,
  refresh_count = 0;

process user_session = "session"
begin
  Loop:
    while session_state /= "terminated" do
      either
        \* Login
        await session_state = "unauthenticated";
        session_state := "authenticated";
        token_valid := TRUE;
      or
        \* Token expires
        await session_state = "authenticated" /\ token_valid;
        token_valid := FALSE;
      or
        \* Refresh
        await session_state = "authenticated" /\ ~token_valid /\ refresh_count < 3;
        token_valid := TRUE;
        refresh_count := refresh_count + 1;
      or
        \* Logout
        await session_state = "authenticated";
        session_state := "terminated";
      or
        \* Max refresh exceeded
        await ~token_valid /\ refresh_count >= 3;
        session_state := "terminated";
      end either;
    end while;
end process;

end algorithm; *)

NoUnauthenticatedAccess == token_valid => session_state = "authenticated"
```

## OTP Supervisor (Elixir)

```
(*--algorithm Supervisor
variables
  children = [c \in {"worker1", "worker2"} |-> "running"],
  restart_counts = [c \in {"worker1", "worker2"} |-> 0],
  supervisor_state = "running";

define
  MaxRestarts == 3
end define;

process supervisor = "sup"
begin
  Monitor:
    while supervisor_state = "running" do
      with child \in {"worker1", "worker2"} do
        either
          \* Child crashes
          await children[child] = "running";
          children[child] := "crashed";
        or
          \* Restart child
          await children[child] = "crashed" /\ restart_counts[child] < MaxRestarts;
          children[child] := "running";
          restart_counts[child] := restart_counts[child] + 1;
        or
          \* Max restarts exceeded — supervisor dies
          await children[child] = "crashed" /\ restart_counts[child] >= MaxRestarts;
          supervisor_state := "shutdown";
        end either;
      end with;
    end while;
end process;

end algorithm; *)

RestartsBounded == \A c \in {"worker1", "worker2"}: restart_counts[c] <= MaxRestarts
SupervisorShutdownOnMaxRestarts ==
  supervisor_state = "shutdown" =>
    \E c \in {"worker1", "worker2"}: restart_counts[c] >= MaxRestarts
```

## Agent Orchestration

```
(*--algorithm AgentOrchestrator
variables
  agents = [a \in {"agent1", "agent2"} |-> "idle"],
  tasks = <<"task1", "task2", "task3">>,
  completed = {},
  task_idx = 1;

process orchestrator = "orch"
begin
  Dispatch:
    while task_idx <= Len(tasks) do
      with agent \in {"agent1", "agent2"} do
        await agents[agent] = "idle";
        agents[agent] := "working";
      end with;
      task_idx := task_idx + 1;
    end while;

  Wait:
    await \A a \in {"agent1", "agent2"}: agents[a] \in {"idle", "completed"};
end process;

process worker \in {"agent1", "agent2"}
begin
  Work:
    while TRUE do
      await agents[self] = "working";
      either
        agents[self] := "completed";
      or
        agents[self] := "failed";
      end either;
      agents[self] := "idle";
    end while;
end process;

end algorithm; *)

NoTaskLost == task_idx > Len(tasks) => Cardinality(completed) = Len(tasks)
```

## Tool-Calling Protocol

```
(*--algorithm ToolCalling
variables
  llm_state = "thinking",
  tool_state = "idle",
  tool_result = "none",
  iteration = 0;

process llm = "llm"
begin
  Loop:
    while iteration < 5 do
      either
        \* Decide to call tool
        await llm_state = "thinking";
        llm_state := "waiting_for_tool";
        tool_state := "executing";
      or
        \* Decide to respond (no tool needed)
        await llm_state = "thinking";
        llm_state := "responding";
      or
        \* Process tool result
        await llm_state = "waiting_for_tool" /\ tool_result /= "none";
        llm_state := "thinking";
        tool_result := "none";
        iteration := iteration + 1;
      end either;
    end while;
end process;

process tool = "tool"
begin
  Execute:
    while TRUE do
      await tool_state = "executing";
      either
        tool_result := "success";
      or
        tool_result := "error";
      end either;
      tool_state := "idle";
    end while;
end process;

end algorithm; *)

NoOrphanedToolCall == llm_state = "waiting_for_tool" => tool_state \in {"executing", "idle"}
IterationBounded == iteration <= 5
```

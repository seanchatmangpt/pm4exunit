defmodule Pm4ExUnit.Conformance do
  @moduledoc """
  Formal Token-Based Replay and FSM Conformance Engine for Elixir / ExUnit.
  Validates traces against allowed finite state machine transitions and execution paths.
  Calculates token replay fitness:
    fitness = 0.5 * (1 - missing / consumed) + 0.5 * (1 - remaining / produced)
  """

  @type conformance_result :: %{
          success: boolean(),
          fitness: float(),
          violations: list(String.t()),
          diagnostics: map()
        }

  @doc """
  Evaluates a sequence of events/activities against a set of valid paths or allowed transitions.
  """
  def evaluate(events, valid_paths, opts \\ []) do
    min_fitness = Keyword.get(opts, :min_fitness, 1.0)
    trace = extract_activity_sequence(events)

    # Normalize valid paths
    paths = Enum.map(valid_paths, fn path -> Enum.map(path, &to_string/1) end)

    # Check exact path match first
    if trace in paths do
      %{
        success: true,
        fitness: 1.0,
        violations: [],
        diagnostics: %{
          trace: trace,
          matched_path: trace,
          missing_tokens: 0,
          remaining_tokens: 0
        }
      }
    else
      # Compute Token-Based Replay across candidate paths to find maximal alignment
      best_evaluation =
        paths
        |> Enum.map(&replay_trace_against_path(trace, &1))
        |> Enum.max_by(fn res -> res.fitness end, fn ->
          replay_trace_against_path(trace, [])
        end)

      success = best_evaluation.fitness >= min_fitness and best_evaluation.missing_tokens == 0

      violations =
        if success do
          []
        else
          reasons = []

          reasons =
            if best_evaluation.fitness < min_fitness do
              [
                "Conformance fitness #{Float.round(best_evaluation.fitness, 4)} is below required minimum #{min_fitness}."
                | reasons
              ]
            else
              reasons
            end

          reasons =
            if best_evaluation.missing_tokens > 0 do
              [
                "Trace missed #{best_evaluation.missing_tokens} mandatory transition(s) in path: #{inspect(best_evaluation.target_path)}."
                | reasons
              ]
            else
              reasons
            end

          reasons =
            if best_evaluation.remaining_tokens > 0 do
              [
                "Trace ended with #{best_evaluation.remaining_tokens} unconsumed token(s) (premature termination or superfluous transitions)."
                | reasons
              ]
            else
              reasons
            end

          Enum.reverse(reasons)
        end

      %{
        success: success,
        fitness: best_evaluation.fitness,
        violations: violations,
        diagnostics: %{
          trace: trace,
          target_path: best_evaluation.target_path,
          produced: best_evaluation.produced,
          consumed: best_evaluation.consumed,
          missing_tokens: best_evaluation.missing_tokens,
          remaining_tokens: best_evaluation.remaining_tokens
        }
      }
    end
  end

  defp extract_activity_sequence(events) when is_list(events) do
    Enum.map(events, fn
      %{activity: act} -> to_string(act)
      %{"concept:name" => act} -> to_string(act)
      %{name: act} -> to_string(act)
      act when is_binary(act) or is_atom(act) -> to_string(act)
      other -> to_string(other)
    end)
  end

  # Token-based replay algorithm along a sequential state machine / path
  defp replay_trace_against_path(trace, path) do
    # For a path [p1, p2, ..., pn], each transition consumes from previous place and produces to next.
    # We trace tokens through the places.
    # Total transitions in model = length(path)
    # Total transitions fired in trace = length(trace)

    # Initial marking has 1 token in source
    initial_marking = 1

    {missing, remaining, consumed, produced} =
      simulate_replay(trace, path, initial_marking)

    # Standard TBR Fitness formula:
    # f = 0.5 * (1 - missing/consumed) + 0.5 * (1 - remaining/produced)
    fitness =
      if consumed == 0 or produced == 0 do
        0.0
      else
        c_part = 1.0 - missing / max(consumed, 1)
        p_part = 1.0 - remaining / max(produced, 1)
        max(0.0, 0.5 * c_part + 0.5 * p_part)
      end

    %{
      fitness: fitness,
      missing_tokens: missing,
      remaining_tokens: remaining,
      consumed: consumed,
      produced: produced,
      target_path: path
    }
  end

  defp simulate_replay(trace, path, initial_tokens) do
    # Step through trace events, matching against expected sequential path places
    # Tokens represent current active place index (0 = start, length(path) = end)
    step_replay(trace, path, 0, initial_tokens, 0, 0, 0, 0)
  end

  defp step_replay([], path, current_idx, current_tokens, missing, remaining, consumed, produced) do
    # When trace ends, any tokens not at final state length(path) are considered remaining / incomplete
    target_idx = length(path)

    extra_missing =
      if current_idx < target_idx do
        target_idx - current_idx
      else
        0
      end

    final_missing = missing + extra_missing
    final_remaining = remaining + current_tokens
    final_consumed = consumed + extra_missing
    final_produced = produced + initial_produced(path)

    {final_missing, final_remaining, max(final_consumed, 1), max(final_produced, 1)}
  end

  defp step_replay(
         [act | rest_trace],
         path,
         current_idx,
         current_tokens,
         missing,
         remaining,
         consumed,
         produced
       ) do
    expected_act = Enum.at(path, current_idx)

    cond do
      act == expected_act ->
        # Perfect step: consume 1 token, produce 1 token to next place
        step_replay(
          rest_trace,
          path,
          current_idx + 1,
          current_tokens,
          missing,
          remaining,
          consumed + 1,
          produced + 1
        )

      true ->
        # Mismatch: look ahead in path or consider out-of-order / unexpected event
        case Enum.find_index(Enum.drop(path, current_idx), &(&1 == act)) do
          nil ->
            # Unmapped / illegal activity executed
            step_replay(
              rest_trace,
              path,
              current_idx,
              current_tokens + 1,
              missing,
              remaining + 1,
              consumed,
              produced + 1
            )

          lookahead_offset ->
            # Skipped transitions: account for missing tokens
            skipped_count = lookahead_offset
            new_idx = current_idx + lookahead_offset + 1

            step_replay(
              rest_trace,
              path,
              new_idx,
              current_tokens,
              missing + skipped_count,
              remaining,
              consumed + skipped_count + 1,
              produced + skipped_count + 1
            )
        end
    end
  end

  defp initial_produced(path) do
    length(path) + 1
  end
end

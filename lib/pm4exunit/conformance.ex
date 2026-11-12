defmodule Pm4ExUnit.Conformance do
  @moduledoc """
  Formal Token-Based Replay and FSM Conformance Engine for Elixir / ExUnit.
  Validates traces against allowed finite state machine transitions and execution paths.
  Calculates token replay fitness:
    fitness = 0.5 * (1 - missing / consumed) + 0.5 * (1 - remaining / produced)

  Replay semantics are a faithful port of pm4vitest's standard TBR engine
  (servengine-frontend/packages/pm4vitest/src/conformance.ts): each valid path
  becomes a parallel branch in a block-structured Petri net (shared source place,
  per-activity transitions, shared sink place); a trace is replayed with bounded
  backtracking choosing the firing sequence minimizing (missing, remaining)
  lexicographically.
  """

  @type conformance_result :: %{
          success: boolean(),
          fitness: float(),
          violations: list(String.t()),
          diagnostics: map()
        }

  @start_place "__start__"
  @end_place "__end__"
  @dfs_budget 100_000

  @doc """
  Evaluates a sequence of events/activities against a set of valid paths or allowed transitions.
  """
  def evaluate(events, valid_paths, opts \\ []) do
    min_fitness = Keyword.get(opts, :min_fitness, 1.0)
    trace = extract_activity_sequence(events)
    net = build_net(valid_paths)
    result = replay(net, trace)

    success = result.fitness >= min_fitness and result.missing == 0

    violations =
      if success do
        []
      else
        reasons = []

        reasons =
          if result.fitness < min_fitness do
            [
              "Conformance fitness #{Float.round(result.fitness, 4)} is below required minimum #{min_fitness}."
              | reasons
            ]
          else
            reasons
          end

        reasons =
          if result.missing > 0 do
            [
              "Trace missed #{result.missing} mandatory transition(s) in path: #{inspect(result.best_path)}."
              | reasons
            ]
          else
            reasons
          end

        reasons =
          if result.remaining > 0 do
            [
              "Trace ended with #{result.remaining} unconsumed token(s) (premature termination or superfluous transitions)."
              | reasons
            ]
          else
            reasons
          end

        Enum.reverse(reasons)
      end

    %{
      success: success,
      fitness: result.fitness,
      violations: violations,
      diagnostics: %{
        trace: trace,
        target_path: result.best_path,
        produced: result.produced,
        consumed: result.consumed,
        missing_tokens: result.missing,
        remaining_tokens: result.remaining,
        best_path: result.best_path,
        missing_transitions: result.missing_transitions,
        remaining_tokens_map: result.remaining_tokens
      }
    }
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

  # ---------------------------------------------------------------------------
  # Petri net construction from valid paths
  # ---------------------------------------------------------------------------

  defp build_net(valid_paths) do
    transitions =
      valid_paths
      |> Enum.map(fn path -> Enum.map(path, &to_string/1) end)
      |> Enum.with_index()
      |> Enum.flat_map(fn {path, k} ->
        {branch, _} =
          path
          |> Enum.with_index()
          |> Enum.map_reduce(@start_place, fn {activity, i}, cur ->
            out_place = if i == length(path) - 1, do: @end_place, else: "p#{k}_#{i}"
            transition = %{
              name: "t_#{k}_#{i}_#{activity}",
              label: activity,
              input: cur,
              output: out_place,
              path_index: k
            }

            {transition, out_place}
          end)

        branch
      end)

    %{
      transitions: transitions,
      initial_marking: %{@start_place => 1},
      final_place: @end_place
    }
  end

  # ---------------------------------------------------------------------------
  # Token-based replay (bounded backtracking)
  # ---------------------------------------------------------------------------

  defp replay(net, trace) do
    initial_marking = net.initial_marking

    {outcome, _memo, _expansions} = dfs(0, initial_marking, [], net, trace, %{}, 0)

    steps =
      if is_nil(outcome) do
        Enum.map(trace, fn activity -> {:cannot, activity} end)
      else
        Enum.reverse(elem(outcome, 2))
      end

    recount(net, initial_marking, steps, trace)
  end

  # Recounts missing/consumed/produced/remaining from the chosen firing sequence,
  # exactly as the TS engine does after its DFS:
  #   - fired transition with an empty input place  -> manufactured token (missing + 1)
  #   - fired transition                            -> consumed + 1, produced + 1
  #   - cannot-fire step (unmapped activity)        -> missing + 1, consumed + 1 only
  #   - remaining = tokens stranded outside the final place at trace end
  defp recount(net, initial_marking, steps, trace) do
    initial_tokens = initial_marking |> Map.values() |> Enum.sum()

    {missing, consumed, produced, final_marking, fired_labels} =
      Enum.reduce(steps, {0, 0, initial_tokens, initial_marking, MapSet.new()}, fn
        {:fire, t, _activity}, {missing, consumed, produced, marking, fired} ->
          marking =
            if Map.get(marking, t.input, 0) <= 0 do
              marking
            else
              Map.update!(marking, t.input, fn n -> n - 1 end)
            end

          marking = Map.update(marking, t.output, 1, fn n -> n + 1 end)

          {missing, consumed + 1, produced + 1, marking, MapSet.put(fired, t.label)}

        {:cannot, _activity}, {missing, consumed, produced, marking, fired} ->
          {missing + 1, consumed + 1, produced, marking, fired}
      end)

    {remaining, tokens} = remaining_of(final_marking, net.final_place)

    %{
      fitness:
        0.5 * (1 - missing_ratio(missing, consumed)) + 0.5 * (1 - remaining_ratio(remaining, produced)),
      missing: missing,
      consumed: consumed,
      remaining: remaining,
      produced: produced,
      missing_transitions: diagnose_missing_mandatory(net, trace, fired_labels),
      remaining_tokens: tokens,
      best_path: diagnose_best_path(net, trace)
    }
  end

  defp missing_ratio(_missing, 0), do: 0.0
  defp missing_ratio(missing, consumed), do: missing / consumed

  defp remaining_ratio(_remaining, 0), do: 0.0
  defp remaining_ratio(remaining, produced), do: remaining / produced

  defp remaining_of(marking, final_place) do
    Enum.reduce(marking, {0, %{}}, fn
      {place, n}, {remaining, tokens} when place != final_place and n > 0 ->
        {remaining + n, Map.put(tokens, place, n)}

      _positive_or_final, acc ->
        acc
    end)
  end

  # Bounded-backtracking DFS over (trace index, marking). Returns
  # {steps_reversed | nil, memo} where nil mirrors the TS engine's null/overflow.
  defp dfs(idx, marking, steps_rev, net, trace, memo, expansions) do
    trace_len = length(trace)

    cond do
      expansions > @dfs_budget ->
        {nil, memo, expansions}

      cached_perfect?(memo, idx, marking) ->
        {nil, memo, expansions}

      idx >= trace_len ->
        {remaining, _tokens} = remaining_of(marking, net.final_place)
        {{0, remaining, steps_rev}, memo, expansions}

      true ->
        activity = Enum.at(trace, idx)

        candidates =
          Enum.filter(net.transitions, fn t ->
            t.label == activity and Map.get(marking, t.input, 0) > 0
          end)

        branches = Enum.map(candidates, &{:fire, &1}) ++ [{:cannot, activity}]

        {results, memo, expansions} =
          Enum.reduce(branches, {[], memo, expansions}, fn
            {:fire, t}, {results, memo, expansions} ->
              next_marking =
                marking
                |> Map.update!(t.input, fn n -> n - 1 end)
                |> Map.update(t.output, 1, fn n -> n + 1 end)

              {res, memo, expansions} =
                dfs(idx + 1, next_marking, [{:fire, t, activity} | steps_rev], net, trace, memo, expansions + 1)

              {[{res, t} | results], memo, expansions}

            {:cannot, activity}, {results, memo, expansions} ->
              {res, memo, expansions} =
                dfs(idx + 1, marking, [{:cannot, activity} | steps_rev], net, trace, memo, expansions + 1)

              {[{res, :cannot} | results], memo, expansions}
          end)

        # Branch order is fire-first, cannot-last; tie-break keeps the earliest
        # fire branch, mirroring the TS engine's first-wins result scan.
        best =
          results
          |> Enum.reverse()
          |> Enum.reduce(nil, fn {res, _origin}, best ->
            if better?(res, best), do: res, else: best
          end)

        memo =
          if is_nil(best) do
            memo
          else
            Map.put(memo, memo_key(idx, marking), {elem(best, 0), elem(best, 1)})
          end

        {best, memo, expansions}
    end
  end

  defp cached_perfect?(memo, idx, marking) do
    case Map.get(memo, memo_key(idx, marking)) do
      {0, 0} -> true
      _ -> false
    end
  end

  defp memo_key(idx, marking), do: "#{idx}|#{marking_key(marking)}"

  defp marking_key(marking) do
    marking
    |> Enum.filter(fn {_p, n} -> n > 0 end)
    |> Enum.sort()
    |> Enum.map_join(",", fn {p, n} -> "#{p}:#{n}" end)
  end

  defp better?(_res, nil), do: true

  defp better?(nil, _best), do: false

  defp better?({m1, r1, _}, {m2, r2, _}) do
    m1 < m2 or (m1 == m2 and r1 < r2)
  end

  # ---------------------------------------------------------------------------
  # Diagnostics
  # ---------------------------------------------------------------------------

  defp diagnose_missing_mandatory(net, trace, fired) do
    path = diagnose_best_path(net, trace)
    Enum.filter(path, fn a -> not MapSet.member?(fired, a) end)
  end

  defp diagnose_best_path(net, trace) do
    paths = distinct_paths(net)

    paths
    |> Enum.reduce({[], -1}, fn p, {best, best_len} ->
      l = lcs_length(trace, p)

      if l > best_len do
        {p, l}
      else
        {best, best_len}
      end
    end)
    |> elem(0)
  end

  defp distinct_paths(net) do
    net.transitions
    |> Enum.group_by(fn t -> t.path_index end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map(fn {_k, ts} -> Enum.map(ts, & &1.label) end)
  end

  defp lcs_length(a, b) do
    len_a = length(a)
    len_b = length(b)
    zero_row = List.duplicate(0, len_b + 1)

    dp =
      Enum.reduce(Range.new(1, len_a, 1), List.duplicate(zero_row, len_a + 1), fn i, dp ->
        prev = Enum.at(dp, i - 1)

        row =
          Enum.reduce(Range.new(1, len_b, 1), List.duplicate(0, len_b + 1), fn j, row ->
            v =
              if Enum.at(a, i - 1) == Enum.at(b, j - 1) do
                Enum.at(prev, j - 1) + 1
              else
                max(Enum.at(prev, j), Enum.at(row, j - 1))
              end

            List.replace_at(row, j, v)
          end)

        List.replace_at(dp, i, row)
      end)

    dp |> Enum.at(len_a) |> Enum.at(len_b)
  end
end

defmodule Pm4ExUnit.Assertions do
  @moduledoc """
  ExUnit assertion macros for process intelligence and conformance checking.
  """

  alias Pm4ExUnit.Conformance
  alias Pm4ExUnit.Temporal
  alias Pm4ExUnit.Session

  @doc """
  Asserts that a trace or session conforms to a set of valid paths with minimum fitness threshold.
  """
  def assert_conformance(source, valid_paths, opts \\ []) do
    events = extract_events(source)
    min_fitness = Keyword.get(opts, :min_fitness, 1.0)

    result = Conformance.evaluate(events, valid_paths, opts)

    unless result.success do
      msg =
        """
        Process Conformance Assertion Failed!
        Minimum Fitness Required: #{min_fitness}
        Observed Fitness: #{Float.round(result.fitness, 4)}
        Violations:
        #{Enum.map_join(result.violations, "\n", &("  * " <> &1))}
        Diagnostics:
          Trace: #{inspect(result.diagnostics[:trace])}
          Missing Tokens: #{result.diagnostics[:missing_tokens]}
          Remaining Tokens: #{result.diagnostics[:remaining_tokens]}
        """

      raise ExUnit.AssertionError,
        message: msg,
        expr: quote(do: assert_conformance(unquote(source), unquote(valid_paths), unquote(opts)))
    end

    result
  end

  @doc """
  Refutes conformance (asserts that a trace violates the model or fitness constraint).
  """
  def refute_conformance(source, valid_paths, opts \\ []) do
    events = extract_events(source)
    result = Conformance.evaluate(events, valid_paths, opts)

    if result.success do
      msg =
        """
        Expected process conformance to fail, but it succeeded!
        Observed Fitness: #{Float.round(result.fitness, 4)}
        Trace: #{inspect(result.diagnostics[:trace])}
        """

      raise ExUnit.AssertionError,
        message: msg,
        expr: quote(do: refute_conformance(unquote(source), unquote(valid_paths), unquote(opts)))
    end

    result
  end

  @doc """
  Asserts that the temporal duration between two activities in the trace satisfies the max latency constraint.
  """
  def assert_sla(source, from_activity, to_activity, opts \\ []) do
    events = extract_events(source)
    max_seconds = Keyword.get(opts, :max_seconds) || Keyword.fetch!(opts, :max_duration)

    result = Temporal.evaluate_sla(events, from_activity, to_activity, max_seconds)

    unless result.success do
      msg =
        """
        Temporal SLA Assertion Failed!
        #{Enum.map_join(result.violations, "\n", &("  * " <> &1))}
        """

      raise ExUnit.AssertionError,
        message: msg,
        expr:
          quote(
            do:
              assert_sla(
                unquote(source),
                unquote(from_activity),
                unquote(to_activity),
                unquote(opts)
              )
          )
    end

    result
  end

  defp extract_events(pid) when is_pid(pid) do
    Session.get_events(pid)
  end

  defp extract_events(%Pm4ExUnit.TraceCollector{events: events}) do
    events
  end

  defp extract_events(events) when is_list(events) do
    events
  end
end

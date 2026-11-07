defmodule Pm4ExUnit.Reporter do
  @moduledoc """
  Generates machine-parseable test output (TAP v13, JUnit XML, JSON) for process intelligence runs.
  Matches pm4pytest reporters.
  """

  @doc """
  Formats results as Test Anything Protocol (TAP) version 13 with YAML diagnostic blocks.
  """
  def format_tap(test_name, success, violations, diagnostics) do
    status = if success, do: "ok", else: "not ok"
    desc = "#{status} 1 - #{test_name}"

    yaml_block =
      diagnostics
      |> Enum.map(fn {k, v} -> "  #{k}: #{inspect(v)}" end)
      |> Enum.join("\n")

    violations_str =
      if Enum.empty?(violations) do
        ""
      else
        "  violations:\n" <> Enum.map_join(violations, "\n", fn v -> "    - #{v}" end) <> "\n"
      end

    """
    TAP version 13
    1..1
    #{desc}
      ---
    #{violations_str}#{yaml_block}
      ...
    """
  end

  @doc """
  Formats results as JUnit XML for direct CI/CD ingestion.
  """
  def format_junit(test_name, success, violations, _diagnostics, duration_seconds \\ 0.001) do
    failures_attr = if success, do: "0", else: "1"

    failure_node =
      if success do
        ""
      else
        message = Enum.join(violations, "; ")
        "<failure message=\"#{escape_xml(message)}\">#{escape_xml(Enum.join(violations, "\n"))}</failure>"
      end

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <testsuites time="#{duration_seconds}">
      <testsuite name="Pm4ExUnit" tests="1" failures="#{failures_attr}" errors="0" time="#{duration_seconds}">
        <testcase name="#{escape_xml(test_name)}" time="#{duration_seconds}">
          #{failure_node}
        </testcase>
      </testsuite>
    </testsuites>
    """
  end

  defp escape_xml(str) do
    str
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end

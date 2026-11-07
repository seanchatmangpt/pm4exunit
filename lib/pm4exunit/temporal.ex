defmodule Pm4ExUnit.Temporal do
  @moduledoc """
  Temporal Latency SLA Engine for ExUnit.
  Validates durations between specified process activities against strict thresholds.
  """

  @type temporal_result :: %{
          success: boolean(),
          actual_seconds: float() | nil,
          max_seconds: float(),
          violations: list(String.t()),
          diagnostics: map()
        }

  @doc """
  Evaluates temporal SLA between from_activity and to_activity.
  """
  def evaluate_sla(events, from_activity, to_activity, max_seconds) do
    from_str = to_string(from_activity)
    to_str = to_string(to_activity)

    from_ev =
      Enum.find(events, fn ev ->
        get_activity(ev) == from_str
      end)

    to_ev =
      Enum.find(events, fn ev ->
        get_activity(ev) == to_str
      end)

    cond do
      is_nil(from_ev) ->
        %{
          success: false,
          actual_seconds: nil,
          max_seconds: max_seconds,
          violations: ["SLA start activity #{inspect(from_str)} was not observed in the event stream."],
          diagnostics: %{}
        }

      is_nil(to_ev) ->
        %{
          success: false,
          actual_seconds: nil,
          max_seconds: max_seconds,
          violations: ["SLA end activity #{inspect(to_str)} was not observed in the event stream."],
          diagnostics: %{}
        }

      true ->
        t_start = get_timestamp(from_ev)
        t_end = get_timestamp(to_ev)

        diff_seconds = DateTime.diff(t_end, t_start, :millisecond) / 1000.0

        if diff_seconds <= max_seconds do
          %{
            success: true,
            actual_seconds: diff_seconds,
            max_seconds: max_seconds,
            violations: [],
            diagnostics: %{
              from: from_str,
              to: to_str,
              duration_ms: round(diff_seconds * 1000),
              start_time: t_start,
              end_time: t_end
            }
          }
        else
          %{
            success: false,
            actual_seconds: diff_seconds,
            max_seconds: max_seconds,
            violations: [
              "SLA violated: transition from #{inspect(from_str)} to #{inspect(to_str)} took #{Float.round(diff_seconds, 3)}s (exceeding maximum of #{max_seconds}s)."
            ],
            diagnostics: %{
              from: from_str,
              to: to_str,
              duration_ms: round(diff_seconds * 1000),
              start_time: t_start,
              end_time: t_end
            }
          }
        end
    end
  end

  defp get_activity(%{activity: a}), do: to_string(a)
  defp get_activity(%{"concept:name" => a}), do: to_string(a)
  defp get_activity(%{name: a}), do: to_string(a)
  defp get_activity(a) when is_binary(a) or is_atom(a), do: to_string(a)
  defp get_activity(_), do: ""

  defp get_timestamp(%{timestamp: %DateTime{} = dt}), do: dt
  defp get_timestamp(%{"time:timestamp" => dt_str}) when is_binary(dt_str) do
    case DateTime.from_iso8601(dt_str) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end
  defp get_timestamp(_), do: DateTime.utc_now()
end

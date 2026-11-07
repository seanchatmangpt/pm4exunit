defmodule Pm4ExUnit do
  @moduledoc """
  Process Mining, Conformance Checking, and Temporal SLA Verification for ExUnit.
  The Elixir native counterpart to `pm4pytest`.

  ## Usage in ExUnit Tests:

  ```elixir
  defmodule MyProcessTest do
    use ExUnit.Case
    use Pm4ExUnit

    test "order saga satisfies FSM conformance", %{pm4_session: session} do
      session |> emit_event("e1", :order_created)
      session |> emit_event("e2", :payment_processed)
      session |> emit_event("e3", :order_fulfilled)

      assert_conformance(session, [
        [:order_created, :payment_processed, :order_fulfilled]
      ], min_fitness: 1.0)
    end

    test "sla latency gate", %{pm4_session: session} do
      t0 = DateTime.utc_now()
      t1 = DateTime.add(t0, 2, :second)

      session |> emit_event("e1", :start_scan, timestamp: t0)
      session |> emit_event("e2", :finish_scan, timestamp: t1)

      assert_sla(session, :start_scan, :finish_scan, max_seconds: 5.0)
    end
  end
  ```
  """

  defmacro __using__(_opts \\ []) do
    quote do
      import Pm4ExUnit.Assertions
      alias Pm4ExUnit.Session

      setup context do
        {:ok, session} = Session.start_link(test_name: to_string(context.test))
        {:ok, pm4_session: session}
      end

      def emit_event(session, event_id, activity, opts \\ []) do
        Session.emit_event(session, event_id, activity, opts)
      end

      def register_object(session, obj_id, obj_type, attrs \\ %{}) do
        Session.register_object(session, obj_id, obj_type, attrs)
      end
    end
  end
end

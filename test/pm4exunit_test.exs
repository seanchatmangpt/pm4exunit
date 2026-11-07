defmodule Pm4ExUnit.MixProjectTest do
  use ExUnit.Case
  use Pm4ExUnit

  describe "Pm4ExUnit conformance assertions" do
    test "passes when trace perfectly matches declared FSM path", %{pm4_session: session} do
      emit_event(session, "e1", :order_created)
      emit_event(session, "e2", :payment_processed)
      emit_event(session, "e3", :order_fulfilled)

      assert_conformance(
        session,
        [
          [:order_created, :payment_processed, :order_fulfilled]
        ],
        min_fitness: 1.0
      )
    end

    test "fails when mandatory transitions are skipped (missing tokens)", %{pm4_session: session} do
      emit_event(session, "e1", :order_created)
      # skipped :payment_processed
      emit_event(session, "e3", :order_fulfilled)

      refute_conformance(
        session,
        [
          [:order_created, :payment_processed, :order_fulfilled]
        ],
        min_fitness: 1.0
      )
    end

    test "evaluates multi-path branching FSM", %{pm4_session: session} do
      valid_paths = [
        [:draft, :submitted, :approved, :dispatched],
        [:draft, :submitted, :rejected, :closed]
      ]

      emit_event(session, "e1", :draft)
      emit_event(session, "e2", :submitted)
      emit_event(session, "e3", :rejected)
      emit_event(session, "e4", :closed)

      assert_conformance(session, valid_paths, min_fitness: 1.0)
    end
  end

  describe "Pm4ExUnit temporal SLA assertions" do
    test "passes when latency is strictly within threshold", %{pm4_session: session} do
      t0 = ~U[2026-11-06 20:00:00Z]
      t1 = ~U[2026-11-06 20:00:02Z]

      emit_event(session, "e1", :request_received, timestamp: t0)
      emit_event(session, "e2", :response_dispatched, timestamp: t1)

      assert_sla(session, :request_received, :response_dispatched, max_seconds: 5.0)
    end

    test "fails when latency breaches SLA threshold", %{pm4_session: session} do
      t0 = ~U[2026-11-06 20:00:00Z]
      t1 = ~U[2026-11-06 20:00:10Z]

      emit_event(session, "e1", :request_received, timestamp: t0)
      emit_event(session, "e2", :response_dispatched, timestamp: t1)

      assert_raise ExUnit.AssertionError, fn ->
        assert_sla(session, :request_received, :response_dispatched, max_seconds: 5.0)
      end
    end
  end

  describe "Pm4ExUnit reporters" do
    test "generates valid TAP v13 output", %{pm4_session: session} do
      emit_event(session, "e1", :step_a)
      events = Pm4ExUnit.Session.get_events(session)
      result = Pm4ExUnit.Conformance.evaluate(events, [[:step_a]])

      tap = Pm4ExUnit.Reporter.format_tap("test_tap", result.success, result.violations, result.diagnostics)
      assert tap =~ "TAP version 13"
      assert tap =~ "ok 1 - test_tap"
    end
  end
end

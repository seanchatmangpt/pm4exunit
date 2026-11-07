defmodule Pm4ExUnit.CompatVerificationTest do
  @moduledoc """
  Verifies that Pm4ExUnit conforms to the typed structural invariants and
  named refusal semantics established by wasm4pm-compat and the wasm4pm execution engine.
  """
  use ExUnit.Case
  use Pm4ExUnit

  describe "wasm4pm-compat structural refusal & conformance alignment" do
    test "evaluates multi-object OCEL trace achieving 1.0 TBR fitness", %{pm4_session: session} do
      # Ingest multi-object event sequence matching wasm4pm-compat OcelLog schema
      register_object(session, "order_1001", "order", %{"total_amount" => 450.00})
      register_object(session, "item_a", "item", %{"sku" => "SKU-99", "qty" => 2})

      emit_event(session, "evt_create", :order_created, %{
        objects: ["order_1001", "item_a"],
        attributes: %{"channel" => "web"}
      })

      emit_event(session, "evt_pay", :payment_captured, %{
        objects: ["order_1001"],
        attributes: %{"gateway" => "stripe"}
      })

      emit_event(session, "evt_pack", :items_packed, %{
        objects: ["order_1001", "item_a"],
        attributes: %{"station" => "W-04"}
      })

      emit_event(session, "evt_ship", :order_shipped, %{
        objects: ["order_1001"],
        attributes: %{"carrier" => "fedex"}
      })

      valid_fsm = [
        [:order_created, :payment_captured, :items_packed, :order_shipped]
      ]

      result = assert_conformance(session, valid_fsm, min_fitness: 1.0)
      assert result.fitness == 1.0
      assert Enum.empty?(result.violations)
    end

    test "refutes trace violating execution sequence and catches missing transition", %{pm4_session: session} do
      register_object(session, "order_1002", "order", %{"total_amount" => 120.00})

      # Skipping :payment_captured and :items_packed directly to :order_shipped
      emit_event(session, "evt_create", :order_created, %{objects: ["order_1002"]})
      emit_event(session, "evt_ship", :order_shipped, %{objects: ["order_1002"]})

      valid_fsm = [
        [:order_created, :payment_captured, :items_packed, :order_shipped]
      ]

      refute_conformance(session, valid_fsm, min_fitness: 1.0)
    end

    test "enforces temporal SLA threshold across multi-object checkpoints", %{pm4_session: session} do
      t0 = ~U[2026-11-06 20:00:00Z]
      t1 = ~U[2026-11-06 20:00:30Z]

      emit_event(session, "evt_1", :intake_verified, timestamp: t0)
      emit_event(session, "evt_2", :clearance_granted, timestamp: t1)

      assert_sla(session, :intake_verified, :clearance_granted, max_seconds: 60.0)
    end
  end
end

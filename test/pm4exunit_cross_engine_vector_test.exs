defmodule Pm4ExUnit.CrossEngineVectorTest do
  @moduledoc """
  Cross-engine TBR parity fixtures shared with pm4vitest's standard TBR engine
  (servengine-frontend/packages/pm4vitest/src/conformance.ts).

  Each vector's expected values were produced by executing the TS engine
  (`replay(buildNet(paths), trace)`) and pinning its counters exactly. These
  tests assert the Elixir port agrees with the TS engine counter-for-counter.
  """

  use ExUnit.Case, async: true

  alias Pm4ExUnit.Conformance

  describe "shared cross-engine vectors (TS ground truth)" do
    test "vector 1: perfect trace on single path -> fitness 1.0" do
      result = Conformance.evaluate(["a", "b", "c"], [["a", "b", "c"]])

      assert result.fitness == 1.0
      assert result.success
      assert result.violations == []

      d = result.diagnostics
      assert d.missing_tokens == 0
      assert d.consumed == 3
      assert d.remaining_tokens == 0
      assert d.produced == 4
    end

    test "vector 2: perfect trace on alternate path of multi-path net -> fitness 1.0" do
      result = Conformance.evaluate(["x", "y"], [["a", "b", "c"], ["x", "y"]])

      assert result.fitness == 1.0
      assert result.success

      d = result.diagnostics
      assert d.missing_tokens == 0
      assert d.consumed == 2
      assert d.remaining_tokens == 0
      assert d.produced == 3
    end

    test "vector 3: trace with unmapped activity stranded before final place -> fitness 0.666667" do
      result = Conformance.evaluate(["a", "b", "x"], [["a", "b", "c"]])

      assert_in_delta result.fitness, 0.666667, 1.0e-6
      refute result.success

      d = result.diagnostics
      assert d.missing_tokens == 1
      assert d.consumed == 3
      assert d.remaining_tokens == 1
      assert d.produced == 3
    end

    test "vector 4: extra activity after complete trace -> fitness 0.900000" do
      result = Conformance.evaluate(["a", "b", "c", "d", "x"], [["a", "b", "c", "d"]])

      assert_in_delta result.fitness, 0.900000, 1.0e-6
      refute result.success

      d = result.diagnostics
      assert d.missing_tokens == 1
      assert d.consumed == 5
      assert d.remaining_tokens == 0
      assert d.produced == 5
    end
  end

  describe "TS-parity edge semantics" do
    test "skipped middle activity -> fitness 0.5 (cannot-fire, token stranded)" do
      result = Conformance.evaluate(["a", "c"], [["a", "b", "c"]])

      assert_in_delta result.fitness, 0.5, 1.0e-6
      d = result.diagnostics
      assert d.missing_tokens == 1
      assert d.consumed == 2
      assert d.remaining_tokens == 1
      assert d.produced == 2
    end

    test "empty trace -> fitness 0.5 (initial token stranded in source place)" do
      result = Conformance.evaluate([], [["a", "b", "c"]])

      assert_in_delta result.fitness, 0.5, 1.0e-6
      d = result.diagnostics
      assert d.missing_tokens == 0
      assert d.consumed == 0
      assert d.remaining_tokens == 1
      assert d.produced == 1
    end
  end
end

defmodule Pm4ExUnit.Session do
  @moduledoc """
  Session process and state manager for test instrumentation.
  Maintains events, objects, and specs for the currently running ExUnit test.
  """

  use GenServer
  alias Pm4ExUnit.TraceCollector

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    test_name = Keyword.get(opts, :test_name, "test_session")
    {:ok, %{test_name: test_name, collector: TraceCollector.new()}}
  end

  def register_object(pid, obj_id, obj_type, attributes \\ %{}) do
    GenServer.call(pid, {:register_object, obj_id, obj_type, attributes})
  end

  def emit_event(pid, event_id, activity, opts \\ []) do
    GenServer.call(pid, {:emit_event, event_id, activity, opts})
  end

  def get_events(pid) do
    GenServer.call(pid, :get_events)
  end

  def get_collector(pid) do
    GenServer.call(pid, :get_collector)
  end

  # Callbacks

  def handle_call({:register_object, id, type, attrs}, _from, state) do
    new_collector = TraceCollector.register_object(state.collector, id, type, attrs)
    {:reply, :ok, %{state | collector: new_collector}}
  end

  def handle_call({:emit_event, id, act, opts}, _from, state) do
    new_collector = TraceCollector.emit_event(state.collector, id, act, opts)
    {:reply, :ok, %{state | collector: new_collector}}
  end

  def handle_call(:get_events, _from, state) do
    {:reply, state.collector.events, state}
  end

  def handle_call(:get_collector, _from, state) do
    {:reply, state.collector, state}
  end
end

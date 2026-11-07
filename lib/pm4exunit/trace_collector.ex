defmodule Pm4ExUnit.TraceCollector do
  @moduledoc """
  Collects process execution traces and events in-memory during an ExUnit test case.
  Provides structured OCEL 2.0 object and event recording.
  """

  defstruct objects: %{}, events: []

  @type t :: %__MODULE__{
          objects: %{String.t() => %{id: String.t(), type: String.t(), attributes: map()}},
          events: list(map())
        }

  @doc """
  Initializes an empty trace collector.
  """
  def new do
    %__MODULE__{objects: %{}, events: []}
  end

  @doc """
  Registers an object in the trace collector.
  """
  def register_object(%__MODULE__{} = collector, obj_id, obj_type, attributes \\ %{}) do
    id_str = to_string(obj_id)
    type_str = to_string(obj_type)

    obj = %{
      id: id_str,
      type: type_str,
      attributes: attributes
    }

    %{collector | objects: Map.put(collector.objects, id_str, obj)}
  end

  @doc """
  Emits an event into the trace collector.
  """
  def emit_event(%__MODULE__{} = collector, event_id, activity, opts \\ []) do
    id_str = to_string(event_id)
    act_str = to_string(activity)
    timestamp = Keyword.get(opts, :timestamp) || DateTime.utc_now()
    attributes = Keyword.get(opts, :attributes, %{})
    relationships = Keyword.get(opts, :relationships, [])

    event = %{
      id: id_str,
      activity: act_str,
      timestamp: timestamp,
      attributes: attributes,
      relationships: relationships
    }

    %{collector | events: collector.events ++ [event]}
  end
end

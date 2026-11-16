defmodule Pm4ExUnit.MixProject do
  use Mix.Project

  @version "26.11.12"

  def project do
    [
      app: :pm4exunit,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Process Intelligence and Conformance Checking for ExUnit (pm4pytest for Elixir)",
      package: package(),
      docs: [main: "readme", extras: ["README.md", "docs/README.md", "docs/tutorials/first-conformance-test.md", "docs/how-to/model-multiple-paths.md", "docs/how-to/enforce-a-latency-sla.md", "docs/how-to/refute-a-trace.md", "docs/how-to/emit-tap-and-junit.md", "docs/how-to/assert-on-plain-lists.md", "docs/reference/api.md", "docs/explanation/token-based-replay.md", "docs/explanation/session-per-test.md"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:ex_doc, "~> 0.34", only: :dev, runtime: false}]
  end

  defp package do
    [
      licenses: ["MIT"],
      files: ~w(lib docs mix.exs README.md CHANGELOG.md LICENSE),
      links: %{"GitHub" => "https://github.com/seanchatmangpt/pm4exunit"}
    ]
  end
end

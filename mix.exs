defmodule Pm4ExUnit.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :pm4exunit,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Process Intelligence, Conformance Checking, and OCPQ for ExUnit (pm4pytest for Elixir)",
      package: package()
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
      files: ~w(lib mix.exs README.md LICENSE),
      links: %{"GitHub" => "https://github.com/seanchatmangpt/pm4exunit"}
    ]
  end
end

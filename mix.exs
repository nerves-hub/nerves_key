defmodule Atecc508a.MixProject do
  use Mix.Project

  def project do
    [
      app: :atecc508a,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:x509, "~> 0.3"},
      {:elixir_circuits_i2c, github: "elixir-circuits/i2c"}
      #{:elixir_circuits_i2c, path: "../elixir-circuits/i2c"}
    ]
  end
end

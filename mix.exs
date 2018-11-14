defmodule Atecc508a.MixProject do
  use Mix.Project

  def project do
    [
      app: :atecc508a,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # {:x509, "~> 0.5"},
      {:x509, github: "mobileoverlord/x509", branch: "template-update"},
      {:circuits_i2c, "~> 0.1"}
    ]
  end
end

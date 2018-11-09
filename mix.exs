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
      # {:x509, "~> 0.5"},
      {:x509, github: "mobileoverlord/x509", branch: "template-update"},
      {:circuits_i2c, "~> 0.1"}
    ]
  end
end

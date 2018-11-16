defmodule Atecc508a.MixProject do
  use Mix.Project

  def project do
    [
      app: :atecc508a,
      version: "0.1.0",
      description: description(),
      package: package(),
      source_url: "https://github.com/fhunleth/atecc508a",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      docs: [extras: ["README.md"], main: "readme"],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:public_key, :asn1, :crypto],
        ignore_warnings: "dialyzer.ignore-warnings"
      ]
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

  defp description do
    "Elixir support for the ATECC508A/608A Cryptoauthentication chips"
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/fhunleth/atecc508a"}
    }
  end

  defp deps do
    [
      # {:x509, "~> 0.5"},
      {:x509, github: "voltone/x509", branch: "master"},
      {:circuits_i2c, github: "elixir-circuits/circuits_i2c"},
      {:ex_doc, "~> 0.11", only: :dev, runtime: false},
      {:dialyxir, "1.0.0-rc.4", only: :dev, runtime: false}
    ]
  end
end

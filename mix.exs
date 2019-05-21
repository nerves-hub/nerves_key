defmodule NervesKey.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_key,
      version: "0.5.0",
      description: description(),
      package: package(),
      source_url: "https://github.com/nerves-hub/nerves_key",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      docs: [extras: ["README.md", "hw/hw.md"], main: "readme"],
      aliases: [docs: ["docs", &copy_images/1]],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:public_key, :asn1, :crypto, :mix],
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
    "Elixir support for the NervesKey"
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/nerves-hub/nerves_key"}
    }
  end

  defp deps do
    [
      {:atecc508a, "~> 0.2"},
      {:nerves_key_pkcs11, "~> 0.1"},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false}
    ]
  end

  # Copy the images referenced by docs, since ex_doc doesn't do this.
  defp copy_images(_) do
    File.cp_r("hw/assets", "doc/assets")
  end
end

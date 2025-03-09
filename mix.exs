defmodule NervesKey.MixProject do
  use Mix.Project

  @version "1.2.0"
  @source_url "https://github.com/nerves-hub/nerves_key"

  def project do
    [
      app: :nerves_key,
      version: @version,
      description: description(),
      package: package(),
      source_url: @source_url,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      aliases: [docs: ["docs", &copy_images/1]],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:public_key, :asn1, :mix],
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:crypto]
    ]
  end

  defp description do
    "Elixir support for the NervesKey"
  end

  defp package do
    [
      files: [
        "CHANGELOG.md",
        "lib",
        "LICENSES/*",
        "mix.exs",
        "NOTICE",
        "README.md",
        "REUSE.toml"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "REUSE Compliance" => "https://api.reuse.software/info/github.com/nerves-hub/nerves_key"
      }
    ]
  end

  defp deps do
    [
      {:atecc508a, "~> 1.1 or ~> 0.3.0"},
      {:nerves_key_pkcs11, "~> 1.0 or ~> 0.2"},
      {:ex_doc, "~> 0.20", only: :docs, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "hw/hw.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  # Copy the images referenced by docs, since ex_doc doesn't do this.
  defp copy_images(_) do
    File.cp_r("hw/assets", "doc/assets")
  end
end

defmodule Utftrap.MixProject do
  use Mix.Project

  @version "0.0.1"
  @source_url "https://github.com/lmartinsantos/utftrap"

  def project do
    [
      app: :utftrap,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "A library for creating spy traps based on UTF-8 invisible characters",
      package: package(),

      # Docs
      name: "Utftrap",
      docs: docs(),

      # Source
      source_url: @source_url,
      homepage_url: @source_url,

      # Escript
      escript: escript()
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
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Luis Martin-Santos <lmartinsantos@webalianza.com>"],
      licenses: ["mit"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/utftrap"
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp escript do
    [
      main_module: UTFtrap.CLI,
      name: "utftrap"
    ]
  end
end

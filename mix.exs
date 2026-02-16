defmodule Plurality.MixProject do
  use Mix.Project

  @version "0.2.3"
  @source_url "https://github.com/jeffhuen/plurality"

  def project do
    [
      app: :plurality,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "Plurality",
      description:
        "Ultra fast English pluralize and singularize noun inflection for Elixir. Convert plural to singular, singular to plural, and detect noun forms. Zero-regex, compile-time data, O(1) dispatch. Classical English mode available.",
      authors: ["Jeff Huen"],
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ash, "~> 3.0", only: [:dev, :test], optional: true},
      {:benchee, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      files: ~w[
        lib
        priv/data
        guides
        mix.exs
        README.md
        LICENSE
        CHANGELOG.md
      ]
    ]
  end

  defp docs do
    [
      main: "Plurality",
      extras: [
        "README.md",
        "guides/classical-mode.md",
        "guides/customization.md",
        "guides/ash-integration.md",
        "guides/performance.md",
        "guides/methodology.md",
        "guides/ambiguous-words.md",
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Guides: ~r/guides\/.*/,
        Changelog: ~r/CHANGELOG.md/
      ],
      groups_for_modules: [
        Core: [Plurality, Plurality.Custom],
        Engine: [Plurality.Engine, Plurality.Rules, Plurality.Style],
        "Ash Integration": ~r/Plurality\.Ash\..*/
      ]
    ]
  end
end

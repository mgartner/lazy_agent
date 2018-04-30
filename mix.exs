defmodule LazyAgent.MixProject do
  use Mix.Project

  @github_url "https://github.com/mgartner/lazy_agent"

  def project do
    [
      app: :lazy_agent,
      version: "0.2.0",
      elixir: "~> 1.6",
      name: "LazyAgent",
      description: "Start agents lazily.",
      source_url: @github_url,
      homepage_url: @github_url,
      files: ~w(mix.exs lib LICENSE.md README.md CHANGELOG.md),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "LazyAgent",
        extras: ["README.md"]
      ],
      package: [
        maintainers: ["Marcus Gartner"],
        licenses: ["MIT"],
        links: %{
          "GitHub" => @github_url,
        }
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false}
    ]
  end
end

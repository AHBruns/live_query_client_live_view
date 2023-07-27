defmodule LiveQueryClientLiveView.MixProject do
  use Mix.Project

  def project do
    [
      name: "LiveQueryClientLiveView",
      description: "Consume LiveQuery queries from Phoenix live views.",
      app: :live_query_client_live_view,
      package: [
        licenses: ["MIT"],
        links: %{
          "Source Code" => "https://github.com/AHBruns/live_query_client_live_view",
          "GitHub" => "https://github.com/AHBruns/live_query_client_live_view"
        },
        files: ~w(lib .formatter.exs mix.exs)
      ],
      docs: [
        main: "LiveQuery.Clients.LiveView"
      ],
      version: "0.1.1",
      source_url: "https://github.com/AHBruns/live_query_client_live_view",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:phx_test_app, path: "./priv/phx_test_app", only: [:test, :dev]},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:phx_test, "~> 0.1.0", only: [:dev, :test]},
      {:live_query, "~> 0.3"},
      {:phoenix_live_view, "~> 0.19"}
    ]
  end
end

defmodule PhxTestAppWeb.UsingAStaticQueryLive do
  use PhxTestAppWeb, :live_view

  on_mount({LiveQuery.Clients.LiveView, name: PhxTestApp.LiveQuery, assign: :lq_ref})

  defmodule Query do
    use LiveQuery.Query.Def

    @impl true
    def init(_ctx) do
      __MODULE__
    end
  end

  defmodule Comp do
    use PhxTestAppWeb, :live_component

    @impl true
    def render(assigns) do
      ~H"""
      <span><%= @value %></span>
      """
    end

    @impl true
    def update(assigns, socket) do
      {:ok,
       socket
       |> assign(:lq_ref, assigns.lq_ref)
       |> assign(:value, LiveQuery.Clients.LiveView.use_query(assigns.lq_ref, Query))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component module={Comp} id={Comp} lq_ref={@lq_ref} />
    </div>
    """
  end
end

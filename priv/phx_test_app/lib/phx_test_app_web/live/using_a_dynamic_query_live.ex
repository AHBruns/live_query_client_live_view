defmodule PhxTestAppWeb.UsingADynamicQueryLive do
  use PhxTestAppWeb, :live_view

  on_mount({LiveQuery.Clients.LiveView, name: PhxTestApp.LiveQuery, assign: :lq_ref})

  defmodule Query do
    use LiveQuery.Query.Def

    @impl true
    def init(_ctx) do
      :ok = Phoenix.PubSub.subscribe(PhxTestApp.PubSub, "dynamic_query:commands")
      1
    end

    @impl true
    def handle_info({"dynamic_query:commands", :change}, state) do
      Phoenix.PubSub.broadcast(
        PhxTestApp.PubSub,
        "dynamic_query:events",
        {"dynamic_query:events", :changed}
      )

      2
    end
  end

  defmodule Comp do
    use PhxTestAppWeb, :live_component

    @impl true
    def render(assigns) do
      ~H"""
      <div>
        <span id="value"><%= @value %></span>
      </div>
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

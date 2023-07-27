defmodule LiveQuery.Clients.LiveView do
  @moduledoc """
  Consume your LiveQuery queries from your Phoenix.LiveViews!
  """

  import Phoenix.Component
  import Phoenix.LiveView

  @doc """
  This is the hook which sets up and manages the all your LiveView's LiveQuery interactions.
  You should consider this a black box.
  It takes 2 things, `:name` and `:assign`.
  `:name` is the name of your LiveQuery system.
  `:assign` is the name of the assign at which you'd like your client ref to be stored. This library will place it there for you.
  Your client ref must be passed to every callsite of `use_query/2`.
  This ref will change every time a query that you're using changes.
  Other than that, it should be considered an opaque data structure.

  ```elixir
  def YourAppWeb.YourLiveView do
    use YourAppWeb, :live_view

    on_mount {LiveQuery.Clients.LiveView, name: YourApp.LiveQuery, assign: :lq_ref}

    ...
  end
  ```
  """
  def on_mount(opts, _params, _session, socket) do
    opts = Map.new(opts)

    process_dict_key = System.unique_integer()

    Process.put(process_dict_key, %{
      opts: opts,
      used_queries: %{},
      read_queries: %{}
    })

    {:cont,
     socket
     |> assign(opts.assign, {process_dict_key, System.unique_integer()})
     |> attach_hook(__MODULE__, :handle_info, fn
       {__MODULE__, :invalidate, _query_key}, socket ->
         {:halt, assign(socket, opts.assign, {process_dict_key, System.unique_integer()})}

       _msg, socket ->
         {:cont, socket}
     end)
     |> attach_hook(__MODULE__, :after_render, fn
       socket ->
         state = Process.get(process_dict_key)

         newly_used_query_keys =
           state.read_queries
           |> Map.keys()
           |> Enum.reject(fn query_key ->
             Map.has_key?(state.used_queries, query_key)
           end)

         newly_unused_query_keys =
           state.used_queries
           |> Map.keys()
           |> Enum.reject(fn query_key ->
             Map.has_key?(state.read_queries, query_key)
           end)

         state =
           Enum.reduce(newly_used_query_keys, state, fn query_key, state ->
             Map.update!(state, :used_queries, fn used_queries ->
               Map.put(used_queries, query_key, %{
                 query_def: state.read_queries[query_key].query_def,
                 query_config: state.read_queries[query_key].query_config
               })
             end)
           end)

         state =
           Enum.reduce(newly_unused_query_keys, state, fn query_key, state ->
             Map.update!(state, :used_queries, fn used_queries ->
               LiveQuery.unlink(state.opts.name,
                 query_key: query_key,
                 client_pid: self()
               )

               Map.delete(used_queries, query_key)
             end)
           end)

         state = Map.put(state, :read_queries, %{})

         Process.put(process_dict_key, state)

         socket
     end)}
  end

  @doc """
  Use a query in from a LiveView live component.
  The first argument is your client ref, which you'll get from the `on_mount` hook.
  If no query_key is provided, the query_def is used as the query_key (useful for singleton queries).
  This will return link the live_view to the query for as long as at least 1 live_component in the live_view is using the query.
  This will return the value of the query, and will automatically rerender the live_view when the query changes.

  ```elixir
  defmodule YourAppWeb.YourLiveComponent do
    use PhxTestAppWeb, :live_component

    @impl true
    def render(assigns) do
      ~H\"\"\"
      <span><%= @value %></span>
      \"\"\"
    end

    @impl true
    def update(assigns, socket) do
      {:ok,
       socket
       |> assign(:lq_ref, assigns.lq_ref)
       |> assign(:value, LiveQuery.Clients.LiveView.use_query(assigns.lq_ref, :your_query_key, YourApp.YourQueryDef))}
    end
  end
  ```
  """
  def use_query(
        {process_dict_key, _nonce},
        query_key \\ nil,
        query_def,
        query_config \\ %{}
      ) do
    query_key =
      if is_nil(query_key) do
        query_def
      else
        query_key
      end

    state = Process.get(process_dict_key)

    unless Map.has_key?(state.used_queries, query_key) or
             Map.has_key?(state.read_queries, query_key) do
      LiveQuery.link(state.opts.name,
        query_key: query_key,
        query_def: query_def,
        query_config: query_config,
        client_pid: self()
      )

      self_pid = self()

      LiveQuery.register_callback(state.opts.name,
        query_key: query_key,
        client_pid: self(),
        cb_key: {__MODULE__, :invalidate},
        cb: fn %LiveQuery.Protocol.DataChanged{query_key: query_key} ->
          send(self_pid, {__MODULE__, :invalidate, query_key})
        end
      )
    end

    unless Map.has_key?(state.read_queries, query_key) do
      %LiveQuery.Protocol.Data{value: value} =
        LiveQuery.read(state.opts.name,
          query_key: query_key,
          selector: &Function.identity/1
        )

      state =
        Map.update!(state, :read_queries, fn read_queries ->
          Map.put(read_queries, query_key, %{
            query_def: query_def,
            query_config: query_config,
            value: value
          })
        end)

      Process.put(process_dict_key, state)

      value
    else
      state.read_queries[query_key].value
    end
  end
end

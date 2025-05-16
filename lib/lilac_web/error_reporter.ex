defmodule LilacWeb.ErrorReporter do
  alias Lilac.Supernova.Types.Payload

  @spec get_stack() :: Exception.stacktrace()
  def get_stack() do
    Process.info(self(), :current_stacktrace) |> elem(1)
  end

  @spec handle_error(%{
          kind: String.t(),
          reason: Exception.t() | term(),
          stack: Exception.stacktrace(),
          user: Lilac.User.t() | nil
        }) ::
          %{error: String.t()} | %{error: String.t(), supernova_id: String.t()}
  def handle_error(%{kind: kind, reason: error, stack: stack, user: user}) do
    response =
      Lilac.Supernova.report(%Payload{
        application: "Lilac",
        kind: error.__struct__,
        severity: kind,
        userID: Map.get(user, :discord_id, "anonymous"),
        message: error.message,
        stack: pretty_print_stack(stack),
        tags: []
      })

    case response do
      {:ok, %{body: %{"error" => supernova_error}}} ->
        %{error: error.message, supernova_id: supernova_error["id"]}

      _ ->
        IO.inspect(response)
        %{error: "An unknown error occurred"}
    end
  end

  @spec handle_error(%{
          kind: String.t(),
          error_struct: struct(),
          user: Lilac.User.t() | nil
        }) ::
          %{error: String.t()} | %{error: String.t(), supernova_id: String.t()}
  def handle_error(%{kind: kind, error_struct: error, user: user}) do
    response =
      Lilac.Supernova.report(%Payload{
        application: "Lilac",
        kind: error.__struct__,
        severity: kind,
        userID: Map.get(user, :discord_id, "anonymous"),
        message: Map.get(error, :message, "An unknown error occurred"),
        stack: get_stack() |> pretty_print_stack(),
        tags: []
      })

    case response do
      {:ok, %{body: %{"error" => supernova_error}}} ->
        %{
          error: Map.get(error, :message, "An unknown error occurred"),
          supernova_id: supernova_error["id"]
        }

      _ ->
        IO.inspect(response)
        %{error: "An unknown error occurred"}
    end
  end

  defp pretty_print_stack(stacktrace) when is_list(stacktrace) do
    stacktrace
    |> Enum.map(&format_entry/1)
    |> Enum.join(",\n")
  end

  defp format_entry({module, function, arity, info}) do
    file = Keyword.get(info, :file, "unknown")
    line = Keyword.get(info, :line, 0)

    """
    {#{inspect(module)}, :#{function}, #{arity},
     [file: ~c"#{file}", line: #{line}]}
    """
  end
end

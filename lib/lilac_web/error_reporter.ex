defmodule LilacWeb.ErrorReporter do
  alias Lilac.Supernova.Types.Payload

  def handle_error(%{kind: kind, reason: error, stack: stack}) do
    response =
      Lilac.Supernova.report(%Payload{
        application: "Lilac",
        kind: error.__struct__,
        severity: kind,
        userID: "anonymous",
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

  defp pretty_print_stack(stacktrace) when is_list(stacktrace) do
    stacktrace
    |> Enum.map(&format_entry/1)
    |> Enum.join(",\n")
  end

  defp format_entry({module, function, arity, [file: file, line: line]}) do
    """
    {#{inspect(module)}, :#{function}, #{arity},
     [file: ~c"#{file}", line: #{line}]}
    """
  end
end

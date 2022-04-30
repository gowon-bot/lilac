defmodule Lilac.LastFM.Response do
  defmacro __using__(_opts) do
    quote do
      @spec convert_number(binary | integer) :: integer
      def convert_number(input) do
        if is_binary(input), do: String.to_integer(input), else: input
      end

      @spec convert_list(binary | Enum.t()) :: Enum.t()
      def convert_list(input) do
        if is_binary(input), do: [], else: input
      end

      @spec convert_boolean(binary | boolean) :: boolean
      def convert_boolean(input) do
        case input do
          x when is_boolean(x) -> x
          "1" -> true
          "true" -> true
          _ -> false
        end
      end
    end
  end
end

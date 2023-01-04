defmodule Lilac.Pagination do
  defstruct [:current_page, :total_pages, :total_items, :per_page]

  @type t() :: %__MODULE__{
          current_page: integer,
          total_pages: integer,
          total_items: integer,
          per_page: integer
        }

  @spec generate(integer, Lilac.Pagination.Input.t() | nil) ::
          Lilac.Pagination.t()
  def generate(count, maybe_page_input) do
    current_page = Map.get(maybe_page_input || %{}, :page, 1)
    per_page = Map.get(maybe_page_input || %{}, :per_page, count)

    %Lilac.Pagination{
      current_page: current_page,
      total_pages: if(per_page > 0, do: ceil(1.0 * count / per_page), else: 1),
      total_items: count,
      per_page: per_page
    }
  end
end

defmodule Lilac.Errors.Indexing do
  def user_already_indexing do
    {:error, "User is already being indexed or updated!"}
  end
end

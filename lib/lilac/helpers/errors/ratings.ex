defmodule Lilac.Errors.Ratings do
  def user_already_importing do
    {:error, "User is already importing ratings!"}
  end
end

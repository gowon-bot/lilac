defmodule Lilac.Helpers.Errors do
  def doughnut_id_doesnt_match do
    {:error, "You do not have permission to execute this operation for that user"}
  end
end

defmodule Lilac.Errors.Meta do
  def doughnut_id_doesnt_match do
    {:error, "You do not have permission to execute this operation for that user"}
  end

  def unknown_database_error do
    {:error, "An unknown Lilac error ocurred"}
  end
end

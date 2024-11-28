defmodule Lilac.Errors.Ratings do
  def user_already_importing do
    {:error, "User is already importing ratings!"}
  end

  def csv_not_in_correct_format do
    {:error, "File is not in correct format! Please upload a valid RateYourMusic .csv file."}
  end
end

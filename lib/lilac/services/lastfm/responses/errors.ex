defmodule Lilac.LastFM.Errors do
  defmodule ConnectionError do
    @type t :: %__MODULE__{status_code: integer | nil, reason: binary | nil}
    defstruct [:status_code, :reason]
  end

  defmodule LastFMError do
    @type t :: %__MODULE__{error_code: integer, message: binary}
    defstruct [:error_code, :message]
  end

  @spec parse_error(map) :: struct
  def parse_error(error) do
    %__MODULE__.LastFMError{error_code: error["error"], message: error["message"]}
  end
end

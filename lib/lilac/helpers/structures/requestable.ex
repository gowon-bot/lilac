defmodule Lilac.Requestable do
  defstruct [:username, :session]

  @typedoc """
  the ambiguous type represents either a requestable or a string (username)
  """
  @type ambiguous :: %Lilac.Requestable{} | String.t()

  @spec from_user(%Lilac.User{}) :: %Lilac.Requestable{}
  def from_user(user) do
    if user.last_fm_session != nil do
      %Lilac.Requestable{
        username: user.username,
        session: user.last_fm_session
      }
    else
      %Lilac.Requestable{username: user.username}
    end
  end

  @spec from_ambiguous(Lilac.Requestable.ambiguous()) :: Lilac.Requestable
  def from_ambiguous(string_or_requestable) do
    if is_bitstring(string_or_requestable) do
      %Lilac.Requestable{username: string_or_requestable}
    else
      string_or_requestable
    end
  end

  @spec is_authed?(Lilac.Requestable.ambiguous()) :: boolean
  def is_authed?(string_or_requestable) do
    not is_binary(string_or_requestable) and string_or_requestable.session != nil
  end
end

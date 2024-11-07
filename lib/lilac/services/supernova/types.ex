defmodule Lilac.Supernova.Types do
  defmodule SupernovaError do
    @enforce_keys [:code, :reason]
    defstruct [:code, :reason]

    @type t :: %__MODULE__{
            code: integer(),
            reason: String.t()
          }
  end

  defmodule Payload.Tag do
    @enforce_keys [:key, :value]
    defstruct [:key, :value]

    @type t :: %__MODULE__{
            key: String.t(),
            value: String.t()
          }
  end

  defmodule Payload do
    @enforce_keys [:application, :kind, :severity, :userID, :message, :stack, :tags]
    defstruct [:application, :kind, :severity, :userID, :message, :stack, :tags]

    @type t :: %__MODULE__{
            application: String.t(),
            kind: String.t(),
            severity: String.t(),
            userID: String.t(),
            message: String.t(),
            stack: String.t(),
            tags: [Payload.Tag.t()]
          }
  end

  defmodule Tag do
    @enforce_keys [:id, :key, :value, :error_id]
    defstruct [:id, :key, :value, :error_id]

    @type t :: %__MODULE__{
            id: integer(),
            key: String.t(),
            value: String.t(),
            error_id: String.t()
          }
  end

  defmodule ErrorResponse do
    @enforce_keys [:error]
    defstruct [:error]

    @type t :: %__MODULE__{
            error: Error.t()
          }
  end

  defmodule Error do
    @enforce_keys [
      :id,
      :created_at,
      :application,
      :kind,
      :severity,
      :user_id,
      :message,
      :stack,
      :tags
    ]
    defstruct [
      :id,
      :created_at,
      :application,
      :kind,
      :severity,
      :user_id,
      :message,
      :stack,
      :tags
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            created_at: String.t(),
            application: String.t(),
            kind: String.t(),
            severity: String.t(),
            user_id: String.t(),
            message: String.t(),
            stack: String.t(),
            tags: [Tag.t()]
          }
  end
end

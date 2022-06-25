FROM elixir:latest

WORKDIR /app

ENV MIX_ENV="prod"

COPY mix.exs ./
COPY mix.lock ./

# Install dependencies
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get

# Copy source
COPY . .

# Compile
RUN mix compile

RUN MIX_ENV="prod"; export SECRET_KEY_BASE=$(mix phx.gen.secret)

EXPOSE 4000
CMD ["mix", "phx.server"]

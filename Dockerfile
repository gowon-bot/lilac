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

# After 5 years you still cannot set an env variable to the output of a command,
# so I have to store it in bashrc...
RUN /bin/bash -l -c 'echo export  > /etc/profile.d/docker_init.sh'

EXPOSE 4000
CMD SECRET_KEY_BASE="$(mix phx.gen.secret)" mix phx.server

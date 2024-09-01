# Lilac

_너도 언젠가 날 잊게 될까?_

This project is part of Gowon bot ([main repo](https://github.com/gowon-bot/gowon))

## Setup

To setup, fill out `config/[env].exs`. Use `prod.exs` for production, and `dev.exs` for development.

To set up the database, make sure the config is filled out:

- Run `mix ecto.create`
- Run `mix ecto.migrate`

Download and build the mirrorball image from [gowon-bot/mirrorball](https://github.com/gowon-bot/mirrorball)

Then Lilac and Mirrorball can be brought up with Docker Compose

## Structure

### Syncing

Lilac syncing leverages Elixir's OTP integration to dynamically spin up new indexing instances. [`Syncer`](lib/lilac/servers/sync/syncer.ex) supervises [`Sync.Supervisor`](lib/lilac/servers/sync/supervisor.ex) instances, which also have children to handle scrobble fetching, converting, inserting, and progress updating.

## Any questions?

Somethings broken? Just curious how something works?

Feel free to shoot me a Discord dm at @mahjogn or join the support server! https://discord.gg/9Vr7Df7TZf

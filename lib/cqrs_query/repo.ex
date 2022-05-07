defmodule CqrsQuery.Repo do
  use Ecto.Repo,
    otp_app: :cqrs_query,
    adapter: Ecto.Adapters.Postgres
end

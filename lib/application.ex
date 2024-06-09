defmodule Venomous.Application do
  @moduledoc """
  This module initializes the application supervision tree.
  It starts the supervisor for managing SnakeManager process with the given Application config.
  """
  use Application
  @default_ttl_minutes 15
  @default_cleaner_interval 60_000
  @default_perpetual_workers 10

  def start(_type, _args) do
    children =
      [
        Supervisor.child_spec(
          {Venomous.SnakeManager, snake_manager_specs()},
          id: Venomous.SnakeManager,
          restart: :permanent
        )
      ] ++ snake_supervisor_spec()

    opts = [strategy: :one_for_one, name: Venomous.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp snake_manager_specs() do
    table = :ets.new(:snake_terrarium, [:set, :public])

    encoder_decoder = Application.get_env(:venomous, :erlport_encoder, %{})
    snake_ttl = Application.get_env(:venomous, :snake_ttl_minutes, @default_ttl_minutes)

    perpetual_workers =
      Application.get_env(:venomous, :perpetual_workers, @default_perpetual_workers)

    cleaner_interval_ms =
      Application.get_env(:venomous, :cleaner_interval, @default_cleaner_interval)

    %{
      table: table,
      snake_ttl_minutes: snake_ttl,
      perpetual_workers: perpetual_workers,
      cleaner_interval_ms: cleaner_interval_ms,
      erlport_encoder: encoder_decoder
    }
  end

  defp snake_supervisor_spec() do
    if Application.get_env(:venomous, :snake_supervisor_enabled, false) do
      [{Venomous.SnakeSupervisor, [strategy: :one_for_one, max_restarts: 0, max_children: 50]}]
    else
      []
    end
  end
end

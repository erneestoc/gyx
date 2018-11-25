defmodule Trainer.Single do
  use GenServer

  defstruct environment: nil, agent: nil, rewards: [], current_state: nil, experience: nil

  @env_module Env.Blackjack
  @agent Agents.BlackjackAgent

  def init(%{env: env, agent: agent}) do
    env.start_link()
    agent.start_link()

    {:ok,
     %Trainer.Single{
       environment: env,
       agent: agent,
       experience: %Experience.Exp{}
     }}
  end

  def start_link do
    GenServer.start_link(__MODULE__, %{env: @env_module, agent: @agent}, name: __MODULE__)
  end

  def train() do
    GenServer.call(__MODULE__, :train)
  end

  def handle_call(:train, _from, t = %Trainer.Single{}) do
    t.environment.reset()
    {:reply, trainer(t, 13), t}
  end

  defp trainer(t = %Trainer.Single{}, 0), do: t

  defp trainer(t = %Trainer.Single{}, num_episodes) do
    IO.puts("\n*** Episodes remaining: " <> inspect(num_episodes))
    t.environment.reset()
    t
    |> observe()
    |> run_episode(false)
    |> trainer(num_episodes - 1)
  end

  defp run_episode(t = %Trainer.Single{}, true), do: t

  defp run_episode(t = %Trainer.Single{}, false) do
    exp = %Experience.Exp{done: done} = t.environment.step(Enum.random([0, 1]))
    t = %{t | experience: exp}
    IO.inspect(exp)
    run_episode(t, done)
  end

  defp observe(t = %Trainer.Single{environment: env}) do
    %{t | current_state: env.get_state()}
  end
end

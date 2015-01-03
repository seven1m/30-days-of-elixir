defmodule Table do
  @moduledoc """
  h2. Problem

  http://rosettacode.org/wiki/Dining_philosophers

  Five philosophers, Aristotle, Kant, Spinoza, Marx, and Russell (the tasks) spend their time
  thinking and eating spaghetti. They eat at a round table with five individual seats.
  For eating each philosopher needs two forks (the resources). There are five forks on the table,
  one left and one right of each seat. When a philosopher cannot grab both forks it sits and waits.
  Eating takes random time, then the philosopher puts the forks down and leaves the dining room.
  After spending some random time thinking about the nature of the universe, he again becomes
  hungry, and the circle repeats itself.

  h2. My Solution

  So, I cheated a little. I skipped modeling of the seats and fork placement, and instead modeled
  forks as 5 discreet resources to be managed by the "Table". I figured philosophers can just
  reach over and grab a fork, yeah? :-)

  It turns out that message passing between processes made this very simple. Even adding "seats"
  as resources to be managed wouldn't make this much more difficult.

  h2. Sample Run

    $ elixir 17-dining-philosophers.exs

    1 philosopher waiting: Aristotle
    1 philosopher waiting: Kant
    Aristotle is eating (count: 1)
    1 philosopher waiting: Spinoza
    Kant is eating (count: 1)
    2 philosophers waiting: Marx, Spinoza
    3 philosophers waiting: Russell, Marx, Spinoza
    Kant is done eating
    Aristotle is done eating
    ...
  """

  defmodule Philosopher do
    defstruct name: nil, ate: 0, thunk: 0
  end

  def simulate do
    forks = [:fork1, :fork2, :fork3, :fork4, :fork5]

    table = spawn_link(Table, :manage_resources, [forks])

    spawn(Dine, :dine, [%Philosopher{name: "Aristotle"}, table])
    spawn(Dine, :dine, [%Philosopher{name: "Kant"     }, table])
    spawn(Dine, :dine, [%Philosopher{name: "Spinoza"  }, table])
    spawn(Dine, :dine, [%Philosopher{name: "Marx"     }, table])
    spawn(Dine, :dine, [%Philosopher{name: "Russell"  }, table])

    receive do: (_ -> :ok)
  end

  def manage_resources(forks, waiting \\ []) do
    # distribute forks to waiting philosophers
    if length(waiting) > 0 do
      names = for {_, phil} <- waiting, do: phil.name
      IO.puts "#{length waiting} philosopher#{if length(waiting) == 1, do: '', else: 's'} waiting: #{Enum.join names, ", "}"
      if length(forks) >= 2 do
        [{pid, _} | waiting] = waiting
        [fork1, fork2 | forks] = forks
        send pid, {:eat, [fork1, fork2]}
      end
    end
    receive do
      {:sit_down, pid, phil} ->
        manage_resources(forks, [{pid, phil} | waiting])
      {:give_up_seat, free_forks, _} ->
        forks = free_forks ++ forks
        IO.puts "#{length forks} fork#{if length(forks) == 1, do: '', else: 's'} available"
        manage_resources(forks, waiting)
    end
  end

end

defmodule Dine do

  def dine(phil, table) do
    send table, {:sit_down, self, phil}
    receive do
      {:eat, forks} ->
        phil = eat(phil, forks, table)
        phil = think(phil, table)
    end
    dine(phil, table)
  end

  def eat(phil, forks, table) do
    phil = %{phil | ate: phil.ate + 1}
    IO.puts "#{phil.name} is eating (count: #{phil.ate})"
    :timer.sleep(:random.uniform(1000))
    IO.puts "#{phil.name} is done eating"
    send table, {:give_up_seat, forks, phil}
    phil
  end

  def think(phil, _) do
    IO.puts "#{phil.name} is thinking (count: #{phil.thunk})"
    :timer.sleep(:random.uniform(1000))
    %{phil | thunk: phil.thunk + 1}
  end

end

:random.seed(:erlang.now)
Table.simulate

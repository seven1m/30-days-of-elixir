defmodule Table do
  defrecord Philosopher, name: nil, ate: 0, thunk: 0

  def simulate do
    forks = [:fork1, :fork2, :fork3, :fork4, :fork5]

    table = spawn_link(Table, :manage_resources, [forks])

    spawn(Dine, :dine, [Philosopher[name: "Aristotle"], table])
    spawn(Dine, :dine, [Philosopher[name: "Kant"     ], table])
    spawn(Dine, :dine, [Philosopher[name: "Spinoza"  ], table])
    spawn(Dine, :dine, [Philosopher[name: "Marx"     ], table])
    spawn(Dine, :dine, [Philosopher[name: "Russell"  ], table])

    wait # TODO why is this necessary? (I thought spawn_link would hold open the parent process.)
  end

  def wait do
    receive do
      {:DOWN, _, _, pid, _} ->
        :quit
      msg ->
        IO.puts inspect msg
        wait
    end
  end

  def manage_resources(forks) do
    #IO.puts "forks available: #{inspect forks}"
    receive do
      {:sit_down, phil} ->
        if length(forks) >= 2 do
          [fork1, fork2 | forks] = forks
          phil <- {:sit_down_and_eat, [fork1, fork2]}
        else
          phil <- :sit_down_and_wait
        end
        manage_resources(forks)
      {:give_up_seat, free_forks} ->
        manage_resources(free_forks ++ forks)
      other ->
        IO.puts inspect other
    end
  end

end

defmodule Dine do

  def dine(phil, table) do
    table <- {:sit_down, self}
    receive do
      {:sit_down_and_eat, forks} ->
        phil = eat(phil, forks, table)
        phil = think(phil, table)
      :sit_down_and_wait ->
        IO.puts "#{phil.name} is waiting for forks"
        :timer.sleep(:random.uniform(1000))
    end
    dine(phil, table)
  end

  def eat(phil, forks, table) do
    IO.puts "#{phil.name} is eating (count: #{phil.ate})"
    :timer.sleep(:random.uniform(1000))
    IO.puts "#{phil.name} is done eating"
    table <- {:give_up_seat, forks}
    phil.ate(phil.ate + 1)
  end

  def think(phil, table) do
    IO.puts "#{phil.name} is thinking (count: #{phil.thunk})"
    :timer.sleep(:random.uniform(1000))
    phil.thunk(phil.thunk + 1)
  end

end

:random.seed(:erlang.now)
Table.simulate

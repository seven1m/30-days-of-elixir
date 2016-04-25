# Play Spades with four players using iex!
#
# To play:
#
# 1. In one terminal, start iex as the dealer:
#
#   iex --name dealer@localhost 14-spades.exs
#   iex> Player.start_game
#
# 2. In three more terminals, start iex as players:
#
#   iex --sname two 14-spades.exs
#   iex> Node.connect(:dealer@localhost)
#   iex> Player.join
#
#   iex --sname three 14-spades.exs
#   iex> Node.connect(:dealer@localhost)
#   iex> Player.join
#
#   iex --sname four 14-spades.exs
#   iex> Node.connect(:dealer@localhost)
#   iex> Player.join
#
# 3. Enjoy!


defmodule Dealer do
  @moduledoc """
  A separate process that brokers messages and determines winners.
  """

  @card_vals Enum.into([
    {"J", 11},
    {"Q", 12},
    {"K", 13},
    {"A", 14}
  ], HashDict.new)

  def start_game do
    :global.register_name(:dealer, self)
    IO.puts "waiting for players"
    players = wait_for_players
    IO.puts "dealing cards"
    deal(players, shuffle)
    IO.puts "starting game"
    signal_start(players)
    IO.puts "waiting for plays"
    wait_for_plays(players)
  end

  defp wait_for_players(players \\ []) do
    receive do
      {:join, pid} ->
        IO.puts "#{inspect pid} joined"
        players = [pid | players]
        if length(players) < 4 do
          wait_for_players(players)
        else
          IO.puts "everyone joined!"
          players
        end
    end
  end

  defp shuffle do
    :random.seed(:erlang.now)
    deck = for suit <- ~w(Hearts Diamonds Clubs Spades),
              face <- [2, 3, 4, 5, 6, 7, 8, 9, 10, "J", "Q", "K", "A"],
              do: {suit, face}
    Enum.shuffle(deck)
  end

  defp deal([player | rest_players], [card | rest_cards]) do
    send player, {:deal, card}
    deal(rest_players ++ [player], rest_cards)
  end
  defp deal(_, []), do: :ok

  defp signal_start(players) do
    Enum.each players, fn p -> send(p, :start) end
  end

  defp wait_for_plays(players) do
    wait_for_plays(players, [], 0)
  end

  defp wait_for_plays(players, cards_played, tricks_played) when tricks_played < 13 do
    if length(cards_played) == 0, do: IO.puts "#{tricks_played} tricks played"
    receive do
      action = {:play, card, player} ->
        broadcast(players, action)
        cards_played = cards_played ++ [{player, card}]
        if length(cards_played) == 4 do
          {winner, _} = trick_winner(cards_played)
          broadcast(players, {:trick, winner})
          if tricks_played < 12, do: send winner, :your_turn
          wait_for_plays(players, [], tricks_played + 1)
        else
          players = reorder_players(players, player)
          send List.first(players), :your_turn
          wait_for_plays(players, cards_played, tricks_played)
        end
    end
  end

  defp wait_for_plays(players, [], 13) do
    broadcast(players, :end)
  end

  def trick_winner(cards_played = [first_card | _rest]) do
    {_, {suit, _}} = first_card
    if Enum.any?(cards_played, fn {_, {s, _}} -> s == "Spades" end) do
      sort_cards(cards_played)
        |> Enum.filter(fn {_, {s, _}} -> s == "Spades" end)
        |> List.first
    else
      sort_cards(cards_played)
        |> Enum.filter(fn {_, {s, _}} -> s == suit end)
        |> List.first
    end
  end

  defp sort_cards(cards) do
    Enum.sort cards, fn {_, {_, v1}}, {_, {_, v2}} ->
      Dict.get(@card_vals, v1, v1) > Dict.get(@card_vals, v2, v2)
    end
  end

  defp broadcast(players, action) do
    Enum.each players, fn p -> send(p, action) end
  end

  defp reorder_players(players = [first | rest], player) do
    if Enum.at(players, 3) == player do
      players
    else
      reorder_players(rest ++ [first], player)
    end
  end

end


defmodule Player do
  @moduledoc """
  Handle player state and card selection for plays.
  """

  @doc """
  Call this as the dealer to set up the game.
  """
  def start_game do
    dealer = spawn_link(Dealer, :start_game, [])
    send dealer, {:join, self}
    IO.puts "I am #{inspect self}"
    wait_to_start(dealer)
  end

  @doc """
  Call this as a player to join an existing game.
  """
  def join do
    dealer = :global.whereis_name(:dealer)
    send dealer, {:join, self}
    IO.puts "I am #{inspect self}"
    wait_to_start(dealer)
  end

  defp wait_to_start(dealer, hand \\ []) do
    receive do
      {:deal, card} ->
        hand = [card | hand]
        wait_to_start(dealer, hand)
      :start ->
        play_2_of_clubs(dealer, hand)
    end
  end

  defp play(dealer, hand, card) do
    send dealer, {:play, card, self}
    List.delete hand, card
  end

  defp play_2_of_clubs(dealer, hand) do
    if card = Enum.find hand, fn card -> card == {"Clubs", 2} end do
      hand = play(dealer, hand, card)
    end
    wait_to_play(dealer, hand)
  end

  defp wait_to_play(dealer, hand) do
    receive do
      {:play, card, player} ->
        IO.puts "#{inspect player} played #{inspect card}"
        wait_to_play(dealer, hand)
      {:trick, player} ->
        IO.puts "#{inspect player} won trick"
        wait_to_play(dealer, hand)
      :your_turn ->
        hand = select_and_play_card(dealer, hand)
        wait_to_play(dealer, hand)
      :end ->
        IO.puts "game over!"
    end
  end

  defp select_and_play_card(dealer, hand) do
    show_hand(hand)
    if List.first(System.argv) == "--test" do # TODO how to set debug mode based on args?
      card = Enum.shuffle(hand) |> List.first
    else
      card = select_card(hand)
    end
    play(dealer, hand, card)
  end

  defp select_card(hand) do
    try do
      number = IO.gets("Enter a card number to play: ")
        |> String.strip
        |> String.to_integer
      card = Enum.at(hand, number-1)
      unless card, do: raise ArgumentError
      card
    rescue
      ArgumentError ->
        IO.puts "Invalid entry; try again."
        select_card(hand)
    end
  end

  defp show_hand(hand) do
    Enum.with_index(hand) |> Enum.each fn {{suit, face}, index} ->
      IO.puts "#{index+1}. #{face} of #{suit}"
    end
  end
end

if List.first(System.argv) == "--test" do
  ExUnit.start

  defmodule SpadesTest do
    use ExUnit.Case

    test "trick winner in a single suit" do
      hand = [{nil, {"Clubs", 2}}, {nil, {"Clubs", 3}}, {nil, {"Clubs", 4}}, {nil, {"Clubs", 5}}]
      {_, card} = Dealer.trick_winner(hand)
      assert card == {"Clubs", 5}
    end

    test "trick winner in a single suit with face cards" do
      hand = [{nil, {"Clubs", 2}}, {nil, {"Clubs", 3}}, {nil, {"Clubs", "J"}}, {nil, {"Clubs", "A"}}]
      {_, card} = Dealer.trick_winner(hand)
      assert card == {"Clubs", "A"}
    end

    test "trick winner with irrelevant suit" do
      hand = [{nil, {"Clubs", 2}}, {nil, {"Clubs", 3}}, {nil, {"Clubs", 4}}, {nil, {"Hearts", 5}}]
      {_, card} = Dealer.trick_winner(hand)
      assert card == {"Clubs", 4}
    end

    test "trick winner with one spade" do
      hand = [{nil, {"Clubs", 2}}, {nil, {"Clubs", 3}}, {nil, {"Clubs", 4}}, {nil, {"Spades", 2}}]
      {_, card} = Dealer.trick_winner(hand)
      assert card == {"Spades", 2}
    end

    test "trick winner with all spades" do
      hand = [{nil, {"Spades", 2}}, {nil, {"Spades", 3}}, {nil, {"Spades", 4}}, {nil, {"Spades", 5}}]
      {_, card} = Dealer.trick_winner(hand)
      assert card == {"Spades", 5}
    end

    test "setup" do
      dealer = spawn_monitor Player, :start_game, []
      :timer.sleep(100) # TODO why is this necessary?
      two    = spawn Player, :join, []
      three  = spawn Player, :join, []
      four   = spawn Player, :join, []
      wait
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
  end

end

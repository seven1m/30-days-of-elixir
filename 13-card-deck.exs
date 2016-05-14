defmodule Deck do
  @moduledoc """
    Create, shuffle, deal a set of 52 cards.
  """

  @doc """
    Returns a list of tuples, in sorted order.
  """
  def new do
    for suit <- ~w(Hearts Clubs Diamonds Spades),
       face <- [2, 3, 4, 5, 6, 7, 8, 9, 10, "J", "Q", "K", "A"],
       do: {suit, face}
  end

  @doc """
    Given a list of cards (a deck), reorder cards randomly.

    If no deck is given, then create a new one and shuffle that.
  """
  def shuffle(deck \\ new) do
    Enum.shuffle(deck)
  end

  @doc """
    Given a deck of cards, a list of players, and a deal function,
    call the deal function for each card for each player. The function
    should return the updated player.

    Returns the list of players.
  """

  def deal(cards, players, deal_fn, cards_per_player \\ 52) do
    cards_left = cards_per_player * Enum.count(players)
    _deal(cards, players, deal_fn, cards_left)
  end

  def _deal(cards, players, _, 0), do: {players, cards}

  def _deal([card | rest_cards], [player | rest_players], deal_fn, cards_left) do
    player = deal_fn.(card, player)
    _deal(rest_cards, rest_players ++ [player], deal_fn, cards_left - 1)
  end

  def _deal([], players, _, _), do: { players, [] }


end

ExUnit.start

defmodule DeckTest do
  use ExUnit.Case

  test "new" do
    deck = Deck.new
    assert Enum.at(deck, 0)  == {"Hearts", 2}
    assert Enum.at(deck, 51) == {"Spades", "A"}
  end

  test "shuffle" do
    :random.seed(:erlang.now)
    deck = Deck.shuffle
    assert Deck.shuffle != deck
    assert length(Deck.shuffle) == 52
  end

  test "deal" do
    players = [{"tim", []}, {"jen", []}, {"mac", []}, {"kai", []}]
    deck = Deck.new
    {players, deck} = Deck.deal(deck, players, fn (card, {name, cards}) -> {name, cards ++ [card]} end)
    assert Enum.at(players, 0) == {"tim", [{"Hearts", 2}, {"Hearts", 6}, {"Hearts",  10}, {"Hearts", "A"}, {"Clubs", 5}, {"Clubs",   9}, {"Clubs",  "K"}, {"Diamonds", 4}, {"Diamonds",   8}, {"Diamonds", "Q"}, {"Spades", 3}, {"Spades",  7}, {"Spades", "J"}]}
    assert Enum.at(players, 1) == {"jen", [{"Hearts", 3}, {"Hearts", 7}, {"Hearts", "J"}, {"Clubs",    2}, {"Clubs", 6}, {"Clubs",  10}, {"Clubs",  "A"}, {"Diamonds", 5}, {"Diamonds",   9}, {"Diamonds", "K"}, {"Spades", 4}, {"Spades",  8}, {"Spades", "Q"}]}
    assert Enum.at(players, 2) == {"mac", [{"Hearts", 4}, {"Hearts", 8}, {"Hearts", "Q"}, {"Clubs",    3}, {"Clubs", 7}, {"Clubs", "J"}, {"Diamonds", 2}, {"Diamonds", 6}, {"Diamonds",  10}, {"Diamonds", "A"}, {"Spades", 5}, {"Spades",  9}, {"Spades", "K"}]}
    assert Enum.at(players, 3) == {"kai", [{"Hearts", 5}, {"Hearts", 9}, {"Hearts", "K"}, {"Clubs",    4}, {"Clubs", 8}, {"Clubs", "Q"}, {"Diamonds", 3}, {"Diamonds", 7}, {"Diamonds", "J"}, {"Spades",     2}, {"Spades", 6}, {"Spades", 10}, {"Spades", "A"}]}
    assert deck == []
  end

  test "deal 5 cards per player" do
    players = [{"tim", []}, {"jen", []}, {"mac", []}, {"kai", []}]
    deck = Deck.new
    {players, deck} = Deck.deal(deck, players, fn (card, {name, cards}) -> {name, cards ++ [card]} end, 5)
    assert Enum.at(players, 0) == {"tim", [{"Hearts", 2}, {"Hearts", 6}, {"Hearts",  10}, {"Hearts", "A"}, {"Clubs", 5}]}
    assert Enum.at(players, 1) == {"jen", [{"Hearts", 3}, {"Hearts", 7}, {"Hearts", "J"}, {"Clubs",    2}, {"Clubs", 6}]}
    assert Enum.at(players, 2) == {"mac", [{"Hearts", 4}, {"Hearts", 8}, {"Hearts", "Q"}, {"Clubs",    3}, {"Clubs", 7}]}
    assert Enum.at(players, 3) == {"kai", [{"Hearts", 5}, {"Hearts", 9}, {"Hearts", "K"}, {"Clubs",    4}, {"Clubs", 8}]}
    [next | rest_of_deck] = deck
    assert next == {"Clubs", 9}
  end
end

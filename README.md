# 30 Days of Elixir

A walk through the [Elixir](http://elixir-lang.org/) language, one exercise per day for 30 days.

**Update:** updated to work with Elixir 1.0.2 as of Jan 2015. Special thanks to [parroty](https://github.com/parroty) for help in updating for 1.0 compatibility.

### You have to start somewhere.

**01-hello-world.exs** - We start at the very beginning: our first message to the world!

**02-unit-testing.exs** - We'll need unit testing for the rest of the excercises, so let's do this! The built-in unit testing library ExUnit is capable and easy-to-use.

**03-function-capturing.exs - Quick introduction to function capturing and how to handle different arguments for the same function in module

**03-input-output.exs** - Here we learn that file input and user input are easy. José has even done us a solid and duplicated some familiar Path and File methods from Ruby.

**04-list.exs** - What's a functional language without a List? Here we learn some simple list manipulation, and for awhile we can pretend lists are like our familiar Ruby arrays. :-)

**05-dict.exs** - Dict and Keyword structures are a bit of a departure from the Hash in Ruby world. Sure, it's an associative array, but wrapping our minds around Keyword vs HashDict vs ListDict can be confusing. Luckily, it seems we can simplify by defaulting to [HashDict.new](http://elixir-lang.org/docs/stable/elixir/HashDict.html#new/0) and using the [Dict methods](http://elixir-lang.org/docs/stable/elixir/Dict.html) for manipulation.

**06-record.exs** - Where are our beloved objects? In functional programming, data is just data, and Elixir gives you the Record structure to organize it a bit. Records are a little like Struct from other imperative languages, except of course they are immutable!

**07-fibonacci.exs** - You learn recursion by using recursion! We learn about multiple methods of the same name, pattern matching, and guard clauses, cool! Finally we do it all over again, backwards! (Hey, why not?)

### Learning is a Process.

**08-process-ring.exs** - Sometimes a contrived example is the best way to focus on the technology. For now, let's just send messages around in a ring and see how this Process thing works.

**09-ping.exs** - Now let's build something useful! Wow, it's easy to launch as many processes as you have increments of work. When the work is finished, send a message back to the parent and he'll assemble the results. Cool!

### So, do you Sudoku?

**10-sudoku-board.exs** - No objects? Pshaaw! Who needs 'em - let's use simple lists to represent our Sudoku board. Easy!

**11-sudoku-solver.exs** - Epic fail. Our code is pretty, but the algorithm is naive and too slow to use on a full-size board.

**12-sudoku-solver-norvig.exs** - Time to bring out the big guns! Here we port Peter Norvig's Holy Grail of a Solver over to Elixir. We learn how to change imperative operations on mutable state to functional ones on immutable data. This solver is freakin' fast!

### Spades, cuz they look like little shovels!

**13-card-deck.exs** - Let's see how we might represent a deck of cards. Easy, a list of tuples! We'll also build a higher-order function to deal out the cards to players.

**14-spades.exs** - They're aliiiiive! Processes connect to one another and send messages, across terminal windows, machines, even teh intarwebs! Let's put this to good use and build a multi-player game of Spades. Ace of Spades FTW!

### Tease your brain, but don't be a bully.

**15-quine.exs** - A quine is a program that prints its own source code. Let's build the smallest one we can using Elixir... sigils help a lot!

**16-euler-tree.exs** - Project Euler problem 67 is a fun puzzle; let's solve it with a functional language! We'll make extensive use of list comprehensions in this one.

**17-dining-philosophers.exs** - Pass the fork! The actor model makes certain problems a lot easier to reason about, and feeding some philosophers is one of them.

### OTP, hey you know me!

**18-gen_server.exs** - Here we move up a level and build a Prime Factors server using OTP GenServer behaviour.

**19-supervisor.exs** - This one is simple: when our Prime Factors server craps out, restart it. Easy!

### Let's build a web...

**20-inets.exs** - Erlang's built-in inets library is nothing to be amazed by, but it gets the job done. We'll simply announce ourselves to the world again, this time via HTTP.

**21-wiki.exs** - Now let's build something useful, combining our knowledge of inets and some simple File IO to build a wiki web server.

**22-socket-server.exs** - "I don't always build web apps, but when I do, I use low-level sockets and parse the HTTP headers myself," said no one, ever. Turns out [gen_tcp](http://erlang.org/doc/man/gen_tcp.html) is pretty easy to use if you want to handle socket communication.

### What's this doing here?

**23-digest.exs** - Erlang/OTP has so many things to offer, yet simple hexdigest using sha1 isn't one of 'em. At least we get to learn one way to import external Erlang code and run it in Elixir, so not all is lost.

**24-stream.exs** - Let's build a better Fibonacci method using lazy streams. You can tell our understanding of the language has improved, as the amount of code to implement this is 1/10th of the size of our first foray into Fibonacci!

**25-set.exs** - We'll learn about the built-in [HashSet](http://elixir-lang.org/docs/stable/elixir/HashSet.html) library, just for fun.

### The Rat Pack didn't have Macros.

**26-frank.exs** - Here we'll make a brief incursion into the land of macros. In this excercise, we'll build a web DSL with custom syntax. This first try we'll just use a macro to write a method. `quote`/`unquote` confounds a bit.

**27-frank-2.exs** - This version of Frank is only a little better, but lets our path matches contain any character and utilizes pattern matching to grab the right handler method. But here we're still struggling with `quote`/`unquote` et al. What does it all mean?

**28-frank-3.exs** - Macros are starting to make a little more sense now. The final version of Frank can handle patterns in the URL, e.g. `/foo/:id` and our macro code got simpler!

### You'll never learn if you don't Trie.

**29-vector.exs** - For our last couple of exercises, let's do something completly different! Elixir has a list data structure, but no [Vector](http://clojure.org/data_structures#Data Structures-Vectors (IPersistentVector)), so let's create one... our first attempt has us learning about Hash Array Mapped Trie (HAMT), and as it turns out, using this structure for a vector wasn't the best idea.

**30-vector.exs** - Take 2... Thanks to Jean Niklas L'orange's [excellent articles about Clojure's Vectors](http://hypirion.com/musings/understanding-persistent-vector-pt-1), we learn how to build a Bit Partitioned Vector Trie. And now, we have a Vector with constant-time access. Cool stuff!


## Copyright & License

Copyright (c) 2014, [Tim Morgan](http://timmorgan.org)

Licensed under MIT, see LICENSE file.

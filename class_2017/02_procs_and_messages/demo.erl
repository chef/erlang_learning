
-module(demo).
-compile(export_all).


% You can compile and load this demo module in the REPL as follows:
%     c(demo).
% Youcan then run the functions by calling into this module:
%     demo:simple_spawn().

simple_spawn() ->
  Fun = fun() -> something_happened end,
  spawn(Fun).


% in REPL: spawn a fun as a process

% This example demonstrates a process that will
% wait for any message before terminating.
receiver() ->
  % This will block until we receive something that matches -
  % in this case, any message at all:
  receive Anything ->
           io:fwrite("I got your message and am hanging up.~n"),
           io:fwrite("You said: ~p~n", [Anything])
  end.


% You can send anything - even functions.
send_a_function() ->
  SimpleFun = fun() ->
                  io:fwrite("    -> Function running from PID ~p~n", [self()])
              end,
  Receiver = spawn(fun receive_a_function/0),
  io:fwrite("~nSending the fun from PID ~p to PID ~p~n~n", [self(), Receiver]),
  Receiver ! SimpleFun,
  ok.

% And when you receive them, you can run them:
receive_a_function() ->
  receive SomeUnknownFunction ->
     SomeUnknownFunction()
  end.

% This example shows how a process will only receive the messages
% that match the patterns it is asking for and leaves the others behind.
selective_receive() ->
  receive quit ->
      io:fwrite("Goodbye.")
  end,
  {message_queue_len, Length} = process_info(self(), message_queue_len),
  io:fwrite("~p: I'm leaving now - with ~p messages left unprocessed~n",
            [self(), Length]).

% This builds on the previous example, but uses a tail recursion call
% to continue listening for more messages until it's told to quit.
selective_receive_forever() ->
  receive
    quit ->
      io:fwrite("~p: You said, quit - so goodbye.~n", [self()]);
    _Other ->
      io:fwrite("~p: I got something else. I'll wait for more.~n.", [self()]),
      selective_receive_forever()
  end.

% It's like selective_receive_forever, but it's not forever.
% If no matching message is received in the timeout
% provided, the timeout clause is triggered.
receive_with_timeout() ->
  receive
    quit ->
      io:fwrite("~p: Goodbye~n", [self()]);
    {something, anything} ->
      % An example of a pattern we won't send in this example.
      receive_with_timeout()
  after 5000 ->
      io:fwrite("~p: I am still here. Waiting. Just making sure you know~n.", [self()]),
      % We could just as easily keep waiting for more messages
      receive_with_timeout()
  end.

replying() ->
  receive
    {Pid, quit} ->
      % Reply then exit.
      Pid ! goodbye;
    {Pid, Value} ->
      Pid ! {echo, Value},
      replying();
    _ ->
      io:fwrite("Error: I don't have a PID to talk to!~n"),
      replying()
  end.

% Let's combine the examples above, and add some persistent state:
continuing_to_listen_with_state(State) ->
  receive
    {add, Item} ->
      % Erlang doesn't let us change the value of State, so
      % we'll update it by binding the new state to a new variable:

      NewState = [State | [Item]], % Append the new item to the end of the list

      % Now when we re-enter this function, we'll pass in our modified state:
      continuing_to_listen_with_state(NewState);
    {Pid, count} ->
      Pid ! {items_stored, length(State)},
      continuing_to_listen_with_state(State)
  end.


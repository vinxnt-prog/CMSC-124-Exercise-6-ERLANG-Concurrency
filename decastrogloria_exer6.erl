-module(decastrogloria_exer6).
-compile(export_all).
-compile(nowarn_export_all).

% host the chat
init_chat() ->
    % get user name and trim newline character
    Name = string:trim(io:get_line("Enter Your Name: ")),
    ShellPid = self(), % to get the main terminal's pid

    ReceiverPid = spawn(decastrogloria_exer6, chat, [ShellPid]), % pass shell pid to receiver
    register(chat, ReceiverPid), % start the receiver

    ServerPid = spawn(decastrogloria_exer6, server, [[]]),
    register(chat_server, ServerPid), % start the server

    chat_server ! {join, ReceiverPid}, % host (this) joins the server

    % spawn the input loop in the background
    SenderPid = spawn(decastrogloria_exer6, send_messages, [Name, ReceiverPid, node(), ShellPid]),
    wait_for_end(SenderPid). % main terminal will wait until chat ends ('bye' is sent)

    % send_messages(Name, ReceiverPid, node()). % para sa input to (another function)

% guest of the chat
init_chat2(FrodoNode) ->
    Name = string:trim(io:get_line("Enter Your Name: ")),
    ShellPid = self(), % get the pid of this terminal

    % start the receiver
    ReceiverPid = spawn(decastrogloria_exer6, chat, [ShellPid]),
    register(chat, ReceiverPid),

    % guest joins the server
    {chat_server, FrodoNode} ! {join, ReceiverPid},

    % spawn input loop
    SenderPid = spawn(decastrogloria_exer6, send_messages, [Name, ReceiverPid, FrodoNode, ShellPid]),
    wait_for_end(SenderPid). % this terminal will also wiat (like main terminal) until chat ends

    % send_messages(Name, ReceiverPid, FrodoNode). % para sa input to (another function)


% continuously read terminal input 
% send messages to chat server
% keep looping
% terminate on "bye"
send_messages(Name, ReceiverPid, FrodoNode, ShellPid) ->
    Message = get_input(Name),
    if 
        Message == "bye" -> % if user wants to exit/end the convo 'bye'
            {chat_server, FrodoNode} ! {chat_msg, Name, Message, ReceiverPid}, % send to server to print the message to all connected terminals
            {chat_server, FrodoNode} ! {bye, Name, ReceiverPid}, % tells server to remove this receiverpid from the list of clients (terminals)
            io:format("You disconnected.~n"),
            ShellPid ! chat_ended; % tell the terminal that convo ended
        true -> % else block
            {chat_server, FrodoNode} ! {chat_msg, Name, Message, ReceiverPid},
            send_messages(Name, ReceiverPid, FrodoNode, ShellPid)
    end.

% helper function for send_messages()
get_input(Name) ->
    % prompt the user (user name) and read a line of text
    case io:get_line(Name ++ ": ") of
        {error, Reason} -> 
            io:format("Error reading input: ~s~n", [Reason]),
            error;
        Data ->
            % clean up the trailing newline character (\n)
            CleanData = string:trim(Data),
            CleanData
    end.

% receiver loop
chat(ShellPid) ->
    receive
        {partner_left, LeftName} -> % 1 terminal leaves but chat is still open
            io:format("~s disconnected.~n", [LeftName]),
            chat(ShellPid); % recursive call keeps this terminal alive

        {SenderName, Message} -> % simple printing of message
            io:format("~s: ~s~n", [SenderName, Message]),
            chat(ShellPid); % recursive call

        bye ->
            % closing message and terminate
            io:format("Your partner disconnected.~n"),
            % no chat() recursive call since end of convo na
            ShellPid ! chat_ended;
        
        _ -> % for catching unrecognized messages
            io:format("Unrecognized message.~n"),
            chat(ShellPid)
    end.

% server that is in the host ('Clients' list of all connected 'people' or processes)
server(Clients) ->
    receive
        {join, NewClientPid} ->
            % add new client to list of clients (front of the list)
            server([NewClientPid | Clients]);
            
        {chat_msg, Name, Message, SenderPid} ->
            % send to everyone except the sender
            lists:foreach(fun(ClientPid) -> % iterate over each client inside the list
                if ClientPid /= SenderPid -> 
                       ClientPid ! {Name, Message};
                    true -> % like 'else'
                       ok
                end
            end, Clients), % this is the list (Client)
            server(Clients); % keep the server listening/running
            
        {bye, Name, SenderPid} ->
            Remaining = lists:delete(SenderPid, Clients), %create a new list w/o the terminal that left

            % check if more than 1 people (2 and above) are still 'active' or alive
            if 
                length(Remaining) =< 1 ->
                    % only 1 person left, end the convo
                    lists:foreach(fun(ClientPid) ->
                        ClientPid ! bye 
                    end, Remaining);
                true -> % if more than 1, send notif but do not end the convo
                    lists:foreach(fun(ClientPid) ->
                        ClientPid ! {partner_left, Name}
                    end, Remaining)
            end,
            
            %= keep server running with the remaining clients/terminals
            server(Remaining);

        _ -> % for invalidities
            server(Clients)
    end.

% puts the terminal/shell to idle/sleep until receive 'chat_ended' after typing 'bye'
wait_for_end(SenderPid) ->
    receive
        chat_ended ->
            exit(SenderPid, kill), % fircefully end the field for user input of the terminal that did not exit/say 'bye'
            ok
    end.
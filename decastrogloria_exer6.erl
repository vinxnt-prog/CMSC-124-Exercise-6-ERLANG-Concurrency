-module(decastrogloria_exer6).
-compile(export_all).
-compile(nowarn_export_all).

% host the chat
init_chat() ->
    % get user name and trim newline character
    Name = string:trim(io:get_line("Enter Your Name: ")),

    ReceiverPid = spawn(decastrogloria_exer6, chat, []),
    register(chat, ReceiverPid), % start the receiver

    ServerPid = spawn(decastrogloria_exer6, server, [[]]),
    register(chat_server, ServerPid), % start the server

    chat_server ! {join, ReceiverPid}, % host (this) joins the server

    send_messages(Name, ReceiverPid). % para sa input to (another function)

% guest of the chat
init_chat2(FrodoNode) ->
    Name = string:trim(io:get_line("Enter Your Name: ")),

    % start the receiver
    ReceiverPid = spawn(decastrogloria_exer6, chat, []),
    register(chat, ReceiverPid),

    % guest joins the server
    {chat_server, FrodoNode} ! {join, ReceiverPid},

    send_messages(Name, ReceiverPid). % para sa input to (another function)


% continuously read terminal input 
% send messages to chat server
% keep looping
% terminate on "bye"
send_messages(Name, ReceiverPid) ->
    Input = get_input(),
    if 
        Input == "bye" ->
            io:format("You disconnected.");
        true ->
            io:format("~s: ~s~n", [Name, Input]),
            send_messages(Name, ReceiverPid)
    end.

% helper function for send_messages()
% this helper function reads the terminal input
get_input() ->
    % Prompt the user and read a line of text
    case io:get_line("input> ") of
        {error, Reason} -> 
            io:format("Error reading input: ~s~n", [Reason]),
            error;
        Data ->
            % Clean up the trailing newline character (\n)
            CleanData = string:trim(Data),
            CleanData
    end.

% receiver loop
chat() ->
    receive
        {SenderName, Message} ->
            % print the message
            io:format("~s: ~s", [SenderName, Message]),
            chat(); % recursive call
            
        bye ->
            % closing message and terminate
            io:format("Chat ended.~n");
            % no chat() recursive call since end of convo na
        
        _ -> % for catching unrecognized messages
            io:format("Unrecognized message.~n"),
            chat()
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
            
        _ -> % for invalidities
            server(Clients)
    end.
-module(decastrogloria_exer6).
-compile(export_all).

% host the chat
init_chat() ->
    % get user name and trim newline character
    _Name = string:trim(io:get_line("Enter Your Name: ")),

    ReceiverPid = spawn(decastrogloria_exer6, chat, []),
    register(chat, ReceiverPid), % start the receiver

    ServerPid = spawn(decastrogloria_exer6, server, [[]]),
    register(chat_server, ServerPid), % start the server

    chat_server ! {join, ReceiverPid}, % host (this) joins the server

    ok. % para sa input to (another function)

% guest of the chat
init_chat2(FrodoNode) ->
    _Name = string:trim(io:get_line("Enter Your Name: ")),

    % start the receiver
    ReceiverPid = spawn(decastrogloria_exer6, chat, []),
    register(chat, ReceiverPid),

    % guest joins the server
    {chat_server, FrodoNode} ! {join, ReceiverPid},

    ok. % para sa input to (another function)

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
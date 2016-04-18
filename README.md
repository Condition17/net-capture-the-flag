Net Capture the Flag
=====================


The Flag is represented by a string. Example: "DVA7867a8s6aasahhh"
Implement a server and a client with the following rules:

### Server
Each server has a UNIQUE Identifier of minimum 16 chars starting with: {first char of first name}+{last name}+{.}+{random [az,09] up until 16 chars}

The server allows multiple clients to connect at a time.
Server replies to the following methods:

__"who_are_you?"__
- the server returns a strins containing the unique identifier

__"have_flag?"__
- if the server does not have the FLAG, the answer will be "NO"
- if the server does have the FLAG, then it will generate a unique_flag_token and the answer will be "YES {unique flag token}".

__"next_server"__
- the server will choose RANDOMLY the IP of a next server. The answer to this request cannot be its own IP.

__"capture_flag #{unique_flag_token}"__
- if unique_flag_token is correct (the one generated when asking the question "have_flag?") then it will return “FLAG: #{flag_value}” and the server will mark itself as not having the flag.
- if the unique_flag_token is not present or incorrect then it will answer "ERR: You're trying to trick me!"

__"hide_flag #{flag_value}"__
- the server will mark himself as having the flag (thus the next answer to "have_flag?" will be YES) and store somewhere the flag_value.
- the server will generate an unique_flag_token

### Client

The purpose of the client is to execute the following sequence:
<ul>
  <li>1. First time connect to his own server and ask "next_server".</li>
  <li>2. Connect to next_server and ask "who_are_you?"</li>
  <li>3. Prints "Talking with {SERVER_ID}"</li>
  <li>4. Ask next_server "have_flag?"
    <ul>
      <li>4.1 if NO
        <ul>
          <li>4.1.1 ask next_server "next_server"</li>
          <li>4.1.2 sleep for 0.5 seconds</li>
          <li>4.1.3 Go to step 2.</li>
        </ul>
      </li>
      <li>4.2 if YES
        <ul>
          <li>4.2.1 ask next_server "capture_flag" (with the key received previous)</li>
          <li>4.2.2 ask own_server hide_flag and pass {flag_value}</li>
          <li>4.2.3 print "Got the flag from {next_server_ID}"</li>
          <li>4.2.4 randomly generate a number of seconds between 1 and 10</li>
          <li>4.2.5 print "resting now for {n} seconds" and wait for N seconds</li>
          <li>4.2.6 ask own_server "next_server" and go to step 2</li>
        </ul>
      </li>
    </ul>
  </li>
</ul>

Setup
=====================
You can configure the game details in 'config.txt' file. Here you should insert your client and your server IPs( ":server_address" and ":client_address"), the server's port( ":port" ), the other servers IPs( ":hosts" ), the author name( ":author_name" ) and don't forgot to tell if your server has the flag or not( ":flag present" ) . <br>
__Run client__: go to the project folder and run "ruby client.rb"<br>
__Start the server__: go to the project folder and run "ruby server.rb"

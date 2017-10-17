local resourceRoot = getResourceRootElement(getThisResource())

local MAX_PLAYERS = 8

function cycle( ptab, x, dir, isPlaying ) -- +1 to cycle right, -1 to cycle left, isPlaying <=> the player has to have cards to be the next
  if dir == 1 then
    return linkForward(ptab,x,isPlaying)
  else
    return linkBackward(ptab,x,isPlaying)
  end
end

function linkForward( ptab, x, isPlaying )
  x = x+1
  for i = x, MAX_PLAYERS do
    if ptab.players[i] ~= nil and ( ptab.hasCards[i] or not isPlaying ) then
      return i
    end
  end
  for i = 1, x do
    if ptab.players[i] ~= nil and ( ptab.hasCards[i] or not isPlaying ) then
      return i
    end
  end
end

function linkBackward( ptab, x, isPlaying )
  x = x-1
  for i = x, 1, -1 do
    if ptab.players[i] ~= nil and ( ptab.hasCards[i] or not isPlaying ) then
      return i
    end
  end
  for i = MAX_PLAYERS, x, -1 do
    if ptab.players[i] ~= nil and ( ptab.hasCards[i] or not isPlaying ) then
      return i
    end
  end
end

function getPlayerNo(ptab,player)
  for k,v in pairs ( ptab.players ) do
    if v == player then
      return k
    end
  end
end

local pokerTable = {}

local playerSeats = {} -- lookup table
-- playerSeats[player] = ptab

local playerChips = {} -- player Chips
-- playerChips[player] = value

local blindStart = 100; -- this is the bet you have to place as a blind

function createPokerTable()
  for i = 1,1000 do
    if pokerTable[i] == nil then
      local ptab = pokerTable[i]
      ptab.game = {}
      ptab.board = {}
      ptab.players = {}--players[number]   = player
      ptab.hasCards = {}--hasCards[number] = true/false
      ptab.playing = {}--playing[number]   = true/false
      ptab.blind = 0
      ptab.turn = 0
      ptab.bets = {} -- bets[player]=value
      ptab.bet = 0
      ptab.pot = 0
      ptab.count = 0
      ptab.toCheck = 0
      
      ptab.showdown = false
      ptab.showing = 0 -- how many board cards are showing..
      break
    end
  end
end

function startRound(ptab)
  if ptab.count >= 2 then -- you need at least 2 players to play
    
    ptab.game, ptab.board = newGame(MAX_PLAYERS)
    
    if ptab.blind == 0 then -- if the table is new
      math.random(ptab.count) -- set a random blind
      for k,v in pairs(ptab.players) do
        ptab.playing[k] = true
      end
    else
      ptab.blind = cycle( ptab, ptab.blind, 1 ) -- cycle to the next player at the table
    end
    
    ptab.playing[ptab.blind] = true -- New players always start playing when they reach BB
    ptab.turn = cycle( ptab, ptab.blind, 1 ) -- the under-the-gun starts betting
    ptab.toCheck = ptab.blind -- the last one to check is the big blind
    ptab.showing = 0
    ptab.showdown= false
    
    --Deal the cards
    for k,v in pairs(ptab.players) do
      if ptab.playing[k] == true then
        ptab.hasCards[k] = true
      else
        ptab.hasCards[k] = false
      end
    end
    
    --YOU HAVE TO DEAL THE CARDS WITH hasCards FOR THIS TO WORK PROPERLY
    --Place the blind bets
    transactToPot( ptab.players[ blind ], ptab, blindStart )
    transactToPot( ptab.players[ cycle( ptab, blind, -1, true) ], ptab, blindStart/2 ) -- cycle to the last player that has cards
    --Those transaction can be all-in's also...
    ptab.bet = blindStart
    
    --SEND ALL THIS INFO TO PLAYERS
  end
end

function sendBoard(ptab)
  local board = {}
  for i = 1, ptab.showing do
    board[i] = ptab.board[i]
  end
  --TODO SEND BOARD TO ptab.players
end

function phase(ptab)
  if ptab.showing == 0 then
    ptab.showing = 3
    sendBoard(ptab)
  elseif ptab.showing < 5 then
    ptab.showing = ptab.showing + 1
    sendBoard(ptab)
  elseif ptab.showing == 5 then
    ptab.showdown = true
    --Kick out the game players who don't have cards anymore, so the winner() won't be affected by them.
    --Is this for necessary?
    for i = 1, MAX_PLAYERS do
      if not ptab.hasCards[i] then
        ptab.game[i] = nil
      end
    end
    
    local gameToSend = {}
    
    for k,v in pairs(ptab.game) do
      gameToSend[k] = v.hand
    end
    --SEND gameToSend to EVERYONE
    
  elseif ptab.showdown == true then
    --compute winners and stuff
    --Is this for necessary?
    for k,v in pairs(ptab.game) do
      if not ptab.hasCards[k] then
        ptab.game[k] = nil
      end
    end
    
    local winningHands = winner(ptab.game)
    --SPLIT THE POT...
    local winPlayers = {} -- winPlayers[n] = k -> winner number
    for k,v in pairs(winningHands) do --This can be furthered improved and modified so you don't create a "winningHands" table, and also replace the transactToPlayers function TODO
      table.insert(winPlayers,k)
    end
    transactToPlayers(winPlayers,ptab)
    
    ptab.turn = 0 -- STOP ACTIVITY
    return -- STOP THE FUNCTION HERE
    
  end
  
  
  --handle turns here
  local smallBlind = cycle(ptab,blind,-1) -- the SM
  local dealer = cycle(ptab,blind,-1) -- the Dealer
  --nextTurn(dealer) -- this will compute the immediate next player after the dealer, that has cards
  ptab.turn = dealer
  --TODO handle the ALL-IN situations
  
  --SEND INFO TO PLAYERS
end

function nextTurn(ptab)
  ptab.turn = cycle( ptab, ptab.turn, 1, true )
  --TODO handle the ALL-IN situations
  
  --SEND INFO TO PLAYERS
end

function transactToPot(player,ptab,value) -- Add the money from the player to the pot
  playerChips[player] = playerChips[player] - value
  ptab.pot = ptab.pot + value
  ptab.bets[player] = ptab.bets[player] + value
  
  ptab.bet = ptab.bets[player]
  
  --TODO : You have to manage all-in in here. ( because paying the BB's and SB's can be all-ins )
  
  --Just put this in the handler function
  if ptab.bets[player] + value > ptab.bet then -- if it is a raise, THOUGH YOU SHOULD IMPLEMENT A MINIMUM RAISE
    ptab.toCheck = cycle(ptab,ptab.turn,-1,true)--last one playing
    nextTurn(ptab)
  end
  if ptab.bets[player] + value == ptab.bet then -- if it is a check,
    if ptab.players[toCheck] == player then -- if it's the last guy to check turn... then move to flop,turn,river
      phase()
    else
      nextTurn(ptab)
    end
  end
  -- PUT THIS IN THE HANDLER FUNCTION
  
  --Send this info to the players
  --LOG THIS ACTION
end

function transactToPlayers(players,ptab) -- Share the pot, and log it, for the winners
  --Give players the prize
  local prize = math.floor( ptab.pot / #players ) -- the prize for every player
  for k,v in pairs(players) do
    playerChips[ ptab.players[ v ] ] = playerChips[ ptab.players[ v ] ] + prize -- I Modified this with the ptab.players[v] part.. i hope it works, because the winners are passed as numbers
  end
  --TODO LOG this transaction
  
  --Reset bets
  ptab.bets = {}
  ptab.pot = 0
end

function tableRemovePlayer(player, ptab)
  playerSeats[player] = nil
  --modify cycle function for linking..
  ptab.count = ptab.count - 1
  local playerNo = getPlayerNo(ptab,player)
  ptab.players[playerNo] = nil
  ptab.playing[playerNo] = nil
  ptab.hasCards[playerNo] = nil
  ptab.bets[player] = nil
  if ptab.toCheck == playerNo then
    -- HANDLE THAT
    --set this to the last player that hasCards
    ptab.toCheck = cycle(ptab, playerNo, -1, true) -- TODO : what happens if it's that player's turn? ( it should phase () )
  end
  if ptab.turn == playerNo then
    --HANDLE THIS
    --set this to the next player that hasCards
    nextTurn(ptab)--Continue..
  end
  --TODO: SEND INFO to players regarding someone leaving
end

function tableAddPlayer(player, ptab)
  playerSeats[player] = ptab
  --modify cycle function for linking..
  ptab.count = ptab.count + 1
  ptab.players[ptab.count] = player
  ptab.playing[ptab.count] = false
  ptab.hasCards[ptab.count] = false
end

function giveChips(player,command) --TODO remove this debug function
  playerChips[player] = (playerChips[player] or 0) + 10000
end
addCommandHandler("givechips",giveChips)
--TODO - modify the playerChips' table meta functions so that when you assign a value to it, it will automatically sync it with the clients ( the client whose money are in the function + the table players )

--CLIENT COMMANDS HANDLING

function playerBet( value )
  --client,value
  
  --TODO : if a player passes a value higher than his Chips, try to place the highest bet he can with the chips he has...
  
  --TODO : check if the player actually plays at a table, and also, check if it's HIS turn.
  
  local ptab = playerSeats[client]
  
  
  
  -- TODO : All-ins should be handled in the transactToPot function because of paying BB's and SB's.
  
  if ptab.bets[client] + value >= ptab.bet then -- if the value at least reaches a check..
    
    if playerChips[client] > value then--if it's not all-in
      
      transactToPot(client,ptab,value)
      
    elseif playerChips[client] == value then--if it's all-in
      
      transactToPot(client,ptab,value)
      
      --TODO -- proper way to handle all-ins
      
    end
  end
  
  --------------------------------------------------------------------------------------------
  
  

  --[[
  playerChips[player] = playerChips[player] - value
  ptab.pot = ptab.pot + value
  ptab.bets[player] = ptab.bets[player] + value
  
  ptab.bet = ptab.bets[player]
  ]]
  
  
end

function playerFold( )
  --client
  
  --TODO : First check if you are sitting at a table and stuff
  
  local ptab = playerSeats[client]
  if ptab ~= nil then
    ptab.hasCards[ getPlayerNo(ptab,client) ] = false
  end
  
  --TODO SEND INFORMATION TO THE PLAYERS
  
  nextTurn(ptab)
end
addEvent ( "onPlayerFold", true )
addEventHandler ( "onPlayerFold", getRootElement(), playerFold )


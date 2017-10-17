local resourceRoot = getResourceRootElement(getThisResource())

local pokerTable = {}

local playerSeats = {} -- lookup table
-- playersSeats[player] = tableNo

local playerChips = {} -- player Chips
-- playerChips[player] = value

local blindStart = 100; -- this is the bet you have to place as a blind

--When a player is removed from the table, and then someone else joins, they may have no cards :(

function createTable(  ) -- PlayerNo - this better be 8
  for i = 1, 1000 do
    if pokerTable[i] == nil then
      outputChatBox("Created table " .. tostring(i) )
      pokerTable[i] = {}
      --bets[i] = {}
      local ptab = pokerTable[i] -- alias
      --ptab.game, ptab.board = newGame( 8 ) -- maximum players allowed
      ptab.count = 0
      ptab.blind = 1
      ptab.pot = 0 -- the prize ;)
      ptab.bet = blindStart -- the bet you have to check to, or raise more than..
      ptab.bets = {} -- each player's bets
      ptab.players = {}
      ptab.phase = 0 -- 0-none, 1-flop, 2-turn, 3-river, 4-showdown
      ptab.showdown = false
      ptab.turn = 0 -- whose turn is it ? :D, initially noones.. until table starts
      ptab.toCheck = 0 -- the guy who checked... or you know..
      ptab.playing = {} -- the players who are playing,used for folds
      return
    end
  end
end

outputChatBox("Something should happen just about now")
createTable()
outputChatBox( type(pokerTable[1].game) )

function playerSendRestartData( ptab )
  outputChatBox("Sending Restart Data to Players")
  local names = {}
  for k,v in pairs(ptab.players) do
    names[k] = getPlayerName(v)
  end
  
  local board = {}
  local playing = {}
  
  if ptab.turn ~= 0 then
    for k,v in pairs(ptab.game) do
      playing[k] = true
    end
  end
  
  for k,v in pairs(ptab.players) do
    triggerClientEvent ( v, "pokerStart", resourceRoot, k, ptab.game[k], names, playing, board )
    outputChatBox("TRIGGERED THE EVENT FOR OPENING THE ... POKER TABLE " .. getPlayerName(v))
    outputChatBox("PTAB GAME ... " .. tostring(#ptab.game[k]) )
  end
end

function cycle( count, x, dir ) -- +1 to cycle right, -1 to cycle left
  local value = x+dir
  if value == 0 then
    return count
  end
  if value == count+1 then
    return 0
  end
end

function tableRestart( ptab )
  ptab.game, ptab.board = newGame( 8 ) -- maximum players allowed
  
  ptab.blind = cycle ( ptab.count, ptab.blind, 1 ) -- move de blind...
  ptab["playing"][ptab.blind] = true -- just to make sure
  
  ptab.showdown = false
  
  ptab.pot = 0 -- the prize ;)
  ptab.bet = blindStart -- the bet you have to check to, or raise more than..
  ptab.bets = {} -- each player's bets
  ptab.phase = 0 -- 0-none, 1-flop, 2-turn, 3-river, 4-showdown
  
  ptab.show = 0 -- how many community ( board ) cards are shown
  
  
  ptab.turn = cycle ( ptab.count, ptab.blind, 1 ) -- the turn of the under-the-gun .. which is normally set to 1+1 at the start..
  ptab.toCheck = ptab.turn
  
  for k,v in pairs(ptab.players) do
    ptab.bets[v] = 0 -- initialize bets
  end
  
  --place the blinds
  tableAddChips( ptab, ptab.players[ ptab.blind ], blindStart ) -- bigBlind
  tableAddChips( ptab, ptab.players [ cycle( ptab, ptab.blind, -1 ) ], blindStart/2 ) -- smallBlind
  
  playerSendRestartData( ptab )
end

function tableStart( tableNo )
  local ptab = pokerTable[tableNo]
  if ptab ~= nil then
    outputChatBox ( "trying to start a table")
    ptab.game, ptab.board = newGame( 8 ) -- maximum players allowed
    outputChatBox( " CREATE A NEW TABLE WITH " .. tostring(#ptab.game) .. " Hands " )
    
    ptab.turn = cycle ( ptab.count, ptab.blind, 1 ) -- the turn of the under-the-gun .. which is normally set to 1+1 at the start..
    ptab.toCheck = ptab.turn
    
    for k,v in pairs(ptab.players) do
      outputChatBox( "HEHEY")
      outputChatBox( getPlayerName(v) )
      ptab.bets[v] = 0 -- initialize bets
    end
    
    outputChatBox ( "Found " .. getPlayerName( ptab.players[ ptab.blind ] ) .. " " .. getPlayerName ( ptab.players [ cycle( ptab.count, ptab.blind, -1 ) ] ) .. "!"  )
    
    playerChips[ptab.players[ ptab.blind ]] = 100000
    playerChips[ptab.players [ cycle( ptab.count, ptab.blind, -1 ) ]] = 200000
    
    tableAddChips( ptab, ptab.players[ ptab.blind ], blindStart ) -- bigBlind
    tableAddChips( ptab, ptab.players [ cycle( ptab.count, ptab.blind, -1 ) ], blindStart/2 ) -- smallBlind
    
    playerSendRestartData( ptab )
  end
end
addCommandHandler("yostart",function() tableStart(1) end)

function tableAddChips( ptab, player, value )
  playerChips[player] = playerChips[player] - value
  ptab.pot = ptab.pot + value -- TRANSACTION GOING ON HERE . TRANSACTION GOING ON HERE . TRANSACTION GOING ON HERE . TRANSACTION GOING ON HERE . TRANSACTION GOING ON HERE . TRANSACTION GOING ON HERE . 
  ptab.bets[player] = ptab.bets[player]+value
  
  ptab.bet = ptab.bets[player] -- the validity of this is scripted in playerAddChips
  
  --WRITE ACTION TO LOG - TRANSACTION
end

function tablePhase(ptab)
  if ptab.phase == 0 then
    --FLOP
    ptab.phase = 3
  elseif ptab.phase == 3 then
    --TURN
    ptab.phase = 4
  elseif ptab.phase == 4 then
    --RIVER
    ptab.phase = 5
  elseif ptab.phase == 5 then
    --SHOWDOWN
    triggerClientEvent ( ptab.players, "pokerReceiveGame", resourceRoot, ptab.game)
    local winners = winner( ptab.game )
    for k,v in pairs(winners) do
      --AWARD THE PRIZE
      outputChatBox( "There are " .. tostring(#winners) .. " winners! They are awarded with " .. tonumber(floor ( ptab.pot / #winners )) .. "chips each!" )
      playerChips[ ptab.players(k) ] = playerChips[ ptab.players(k) ] + floor ( ptab.pot / #winners ) -- TRANSACTION GOING ON HERE . TRANSACTION GOING ON HERE . TRANSACTION GOING ON HERE . TRANSACTION GOING ON HERE . 
      tableRestart(ptab)
      
    end
    ptab.showdown = true
  end
  
  if ptab.showdown == false then -- save the energy on 1 case ;)
    local board = {}
    for i = 1, ptab.phase do
      board[i] = ptab.board[i]
    end
    triggerClientEvent ( ptab.players, "pokerReceiveBoard", resourceRoot, board )
  end
  
  --Then.... set turn and toCheck
  
  local newturn = ptab.blind
  
  --FIND THE IMMEDIATE PLAYER AFTER THE BB
  for i = 2, ptab.count do -- for the rest of the players ( this is why i start at 2 )
    newturn = cycle( ptab.count, newturn, 1 ) -- cycle normally
    if ptab.game[newturn] ~= nil then -- cycle until you find the immediate next playing player
      break-- and then break
    end
  end
  
  ptab.turn = newturn--Set the turn to the player immediately after the BB
  ptab.toCheck = ptab.turn -- Set the toCheck thingy
end

function tableNext(ptab)
  local newturn = ptab.turn
  for i = 2, ptab.count do -- for the rest of the players ( this is why i start at 2 )
    newturn = cycle( ptab.count, newturn, 1 ) -- cycle normally
    if ptab.game[newturn] ~= nil then -- cycle until you find the immediate next playing player
      break-- and then break
    end
  end
  
  if newturn == ptab.toCheck then -- IF THE BETTING ROUND ENDS
    ptab.turn = 0 -- DISABLE ANY PLAYER ACTIONS, for the moment
    tablePhase(ptab)
  else -- ELSE... if the betting is still going
    ptab.turn = newturn -- just set the turn to another person
  end
  
  triggerClientEvent ( ptab.players, "pokerReceiveTurn", resourceRoot, ptab.turn )--send the event of the turn change to everyone ....
end

function tableAddPlayer( ptab, player )
  outputChatBox("Adding player .. " .. getPlayerName(player) .. "to a table" )
  playerSeats[player] = ptab
  playerChips[player] = playerChips[player] or 0
  ptab.count = ptab.count + 1
  ptab["players"][ptab.count] = player
  ptab["playing"][ptab.count] = false -- usually goes false
  
  local names = {}
  for k,v in pairs(ptab.players) do
    names[k] = getPlayerName(v)
  end
  
  if ptab.turn ~= 0 then -- IS ACTUALLY PLAYING ------------------------------------------------------------------------------------------------------------------------------------------------------
    local playing = {}
    for k,v in pairs(ptab.game) do
      playing[k] = true
    end
  
    local board = {}
    for i = 1, ptab.phase do
      board[i] = ptab.board[i]
    end
  end
  
  local hand = {}
  
  if ptab.game ~= nil then
    hand = ptab.game[ptab.count]
  end
  
  triggerClientEvent ( player, "pokerStart", player, ptab.count, hand, names, playing, board )
  triggerClientEvent ( ptab.players, "pokerOnJoin", player, ptab.count, getPlayerName )
  
  outputChatBox("Added .. " .. getPlayerName(player) .. "to a table" )
end

function tableRemovePlayer( ptab, player, number )--As in leave...
  playerSeats[player] = nil
  ptab.count = ptab.count - 1
  ptab["players"][ptab.count] = nil
  ptab["playing"][ptab.count] = nil -- usually goes false
  ptab["bets"][player] = nil
  
  for i = number, ptab.count do -- shift the other players..
    ptab["players"][i] = ptab["players"][i+1]
    ptab["playing"][i] = ptab["playing"][i+1]
    ptab["game"][i] = ptab["game"][i+1]
  end
  
  triggerClientEvent ( ptab.players, "pokerOnLeave", player, number )
end

function tableFold( ptab, player, number )
  ptab["game"][number] = nil
  triggerClientEvent ( ptab.players, "pokerReceiveFold", player, number )
  --SEND TO THE PLAYERS THE FACT THAT THIS PLAYER FOLDED....
end

function playerFold( player )
  local ptab = playerSeats[player]
  if ptab ~= nil then
    for k,v in pairs(ptab.players) do
      if v == player then
        tableFold( ptab, player, k )
        tableNext(ptab)
        break
      end
    end
  end
end

function playerAddChips( player, command, value )
  playerChips[player] = playerChips[player] or 0
  if playerChips[value] < value then
    outputChatBox("Error, you do not have enough chips",player)
    return -- stop here
  end
  local ptab = playerSeats[player]
  if ptab ~= nil then
    if ptab.players[ptab.turn] == player then
      ptab.bets[player] = ptab.bets[player] or 0 -- initialize it
      if ptab.bet >= ptab.bets[player] + value then -- IF IT IS A RAISE OR CHECK
        
        if ptab.bet > ptab.bets[player] + value then--IF IT IS A RAISE
          ptab.toCheck = ptab.turn -- MODIFY THE LAST GUY TO CHECK
        end
        
        tabbleAddChips( ptab, player, value )
        tableNext(ptab) -- choose the turn for the next player
      else
        outputChatBox("Error, you are trying to add less chips than minimum, contact ADMIN", player)
      end
    end
  else
    outputChatBox("You are not playing poker!")
  end
end
addCommandHandler("addchips",playerAddChips)

function playerJoinTable(player,command,tableNo)
  tableNo = tonumber(tableNo) or 0
  local ptab = pokerTable[tableNo]
  if ptab ~= nil then
    if ptab.count < 8 then
      tableAddPlayer( ptab, player )
    else
      outputChatBox("Table " .. tableNo .. " is full!",player)
    end
  else
    outputChatBox("Table " .. tableNo .. " does not exist!",player)
  end
end
addCommandHandler("pokerplay", playerJoinTable)

function playerGiveChips(player,command)
  playerChips[player] = (playerChips[player] or 0) + 10000
end
addCommandHandler("pokergetchips", playerGiveChips)


--[[
clientEvent - "pokerStart" -- When the game starts, get blinds, get player names .. so on..
clientEvent - "pokerReceiveGame" -- Receive all cards on showdown
clientEvent - "pokerReceiveCards" -- Receive your cards
clientEvent - "pokerReceiveBoard" -- Receive cards involved in flop,turn,river
clientEvent - "pokerReceiveBet" -- receive betting / checking
clientEvent - "pokerReceiveTurn" -- receive turn
clientEvent - "pokerReceiveFold" -- receive betting / checking / turn
clientEvent - "pokerOnJoin" -- if someone joins the table..
clientEvent - "pokerOnLeave" -- if someone leaves the table..

serverEvent - "pokerPlayerBet" -- when someone bets or checks.. ( same shit )
serverEvent - "pokerPlayerFold" -- when someone folds
]]

--[[
function newGame(playerNo)
  local game = {}
  local deck = createDeck()
  local board = drawBoard(deck)
  for player = 1,playerNo do
    game[player] = {}
    game[player].hand = drawHand(deck)
    local check = compose(game[player].hand,board)
    table.sort( check, function( a, b ) return value(a.rank) > value(b.rank) end)
    local x,y,z = analyze( check )
    game[player].value = x
    game[player].rank = y
    game[player].kicker = z
  end
  return game, board
end
]]

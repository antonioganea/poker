do
--[[
highcard - 1
one pair - 2
two pair - 3
three of a kind - 4
straight - 5
flush - 6
fullhouse - 7
four of a kind - 8
straight flush - 9
royal flush - 10
]]

suits = { "S", "H", "D", "C" }
math.randomseed( 48384 )

function getCardName(rank, suit)
  if ( rank == 1 ) then
    s = "Ace"
  elseif ( rank == 11 ) then
    s = "Jack"
  elseif ( rank == 12 ) then
    s = "Queen"
  elseif ( rank == 13 ) then
    s = "King"
  else
    s = tostring(rank)
  end
  s = s .. " of " .. suit
  return s
end

function table.shuffle( t )
    assert( t, "shuffleTable() expected a table, got nil" )
    local iterations = #t
    local j
    for i = iterations, 2, -1 do
        j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function drawHand( t )
  if #t >= 2 then
    hand = {}
    hand[1] = table.remove(t)
    hand[2] = table.remove(t)
    return hand
  else
    assert(nil, "Table contains less than 2 cards")
  end
end

function drawBoard( t )
  if #t >= 5 then
    board = {}
    for i = 1,5 do 
      board[i] = table.remove( t )
    end
    return board
  else
    assert(nil, "Table contains less than 5 cards")
  end
end

function createDeck()
  deck = {}
  for i = 1, 13 do
    for k,v in pairs(suits) do
      card = {}
      card.suit = v
      card.rank = i
      table.insert(deck,card)
    end
  end
  table.shuffle(deck)
  return deck
end

function value( x )
  if x == 1 then
    return 14
  else
    return x
  end
end

function compose( x, y )
  local z = {}
  for k,v in pairs( x ) do
    table.insert(z,v)
  end
  for k,v in pairs( y ) do
    table.insert(z,v)
  end
  return z
end

function onepair( t )
  local empty = {}
  for k,v in pairs( t ) do
    if ( empty[v.rank] == nil ) then
      empty[v.rank] = 1
    else
      empty[v.rank] = empty[v.rank] + 1
    end
  end
  
  --compute max
  local max = 0
  for k,v in pairs( empty ) do
    if ( v > 1 ) then
      if value(k) > max then
        max = value(k)
      end
    end
  end
  
  --compute kickers
  local kickers = {}
  local cards = 0
  for k,v in pairs( t ) do
    if( value(v.rank) ~= max ) then
      table.insert(kickers,value(v.rank))
      cards = cards + 1
    end
    if ( cards == 3 ) then
      break
    end
  end

    return max, kickers
end

function twopair( t )
  local empty = {}
  for k,v in pairs( t ) do
    if ( empty[v.rank] == nil ) then
      empty[v.rank] = 1
    else
      empty[v.rank] = empty[v.rank] + 1
    end
  end
  
  --computer max
  local max = {}
  local pair = 0
  for k,v in pairs( empty ) do
    if ( v > 1 ) then
      pair = pair + 1
      table.insert(max,k)
    end
  end
  
  table.sort(max,function(a,b) return value(a) > value(b) end)
  
  if ( pair >= 2) then
    
    --compute kickers
    local kickers = {}
    kickers[1] = value(max[2]) -- first kicker is the other pair's rank
    
    
    for k,v in pairs( t ) do
      if( v.rank ~= max[1] and v.rank ~= max[2] ) then
        kickers[2] = value(v.rank) -- the second kicker is the other card in the hand
        break
      end
    end
    return value(max[1]),kickers
  else
    return 0
  end
end

function tok( t )
  local empty = {}
  for k,v in pairs( t ) do
    if ( empty[v.rank] == nil ) then
      empty[v.rank] = 1
    else
      empty[v.rank] = empty[v.rank] + 1
    end
  end
  local rank = 0
  for k,v in pairs( empty ) do
    if ( v == 3 ) then
      if rank < k then
        rank = k
      end
    end
  end
  
  if ( rank ~= 0 ) then -- if there is actually a three of a kind... bother finding kickers, else not
    local kicker = {}
    local cards = 0
    for k,v in pairs ( t ) do
      if ( v.rank ~= rank ) then
        table.insert(kicker,value(v.rank))
        cards = cards + 1
        if ( cards == 2 ) then
          break
        end
      end
    end
    return value(rank), kicker
  else
    return 0
  end
end

function fok( t )
  local empty = {}
  for k,v in pairs( t ) do
    if ( empty[v.rank] == nil ) then
      empty[v.rank] = 1
    else
      empty[v.rank] = empty[v.rank] + 1
    end
  end
  local rank = 0
  for k,v in pairs( empty ) do
    if ( v == 4 ) then
      rank = k
    end
  end

  if ( rank ~= 0 ) then -- if there is actually a three of a kind... bother finding kickers, else not
    local kicker = {}
    for k,v in pairs ( t ) do
      if ( v.rank ~= rank ) then
        table.insert(kicker,value(v.rank))
        break
      end
    end
    return value(rank), kicker
  else
    return 0
  end
end

function straight( t )
  local empty = {}
  for k,v in pairs(t) do
    empty[v.rank] = 1
    if v.rank == 1 then
      empty[14] = 1
    end
  end

  local prev = 0
  local count = 1
  local max = 0
  for k,v in pairs(empty) do
    if ( prev ~= k-1 ) then
      count = 1
    end
    if count >= 5 then -- remember the last value (Highest value)
      max = k
    end
    count = count + 1
    prev = k
  end
  return max
end

function flush( t )
  local empty = {}
  
  for k,v in pairs(suits) do
    empty[v] = {}
  end
  
  for k,v in pairs(t) do
    table.insert(empty[v.suit],value(v.rank))
  end
  
  local kickers = {}
  
  for k,v in pairs(empty) do
    
    if ( #v >= 5 ) then
      
      for i,j in pairs ( v ) do
        table.insert(kickers,j)
      end
      
      table.sort(kickers,function(a,b) return a > b end)
      
      while ( #kickers ~= 5 ) do -- Remove the last elements, so the hand has 5 cards
        table.remove(kickers)
      end
      
      return table.remove(kickers,1), kickers -- return the first card's rank, and then the kickers
    end
    
  end
  
  return 0
end

function strush( t )
empty = {}
for k,v in pairs(suits) do
  empty[v] = {}
end
for k,v in pairs(t) do
  table.insert(empty[v.suit],v)
end
for k,v in pairs(empty) do
  if ( #v >= 5 ) then
    return straight(v)
  end
end
return 0
end

function fullhouse( t )
  local empty = {}
  for k,v in pairs( t ) do
    if ( empty[v.rank] == nil ) then
      empty[v.rank] = 1
    else
      empty[v.rank] = empty[v.rank] + 1
    end
  end
  local brank = 0 -- BIG RANK (the 3 cards)
  local srank = 0 -- SMALL RANK (the 2 cards)
  local two = false
  local three = false
  
  for k,v in pairs(empty) do--Search for 3
    if v >= 3 then
      three = true
      if brank < value(k) then
        brank = value(k)
      end
    end
  end
  if brank == 14 then
    empty[1] = 0 -- Cut out the 3-card rank if rank is ACE
  else
    empty[brank] = 0 -- Cut out the 3-card rank
  end
  for k,v in pairs(empty) do--Search for 2
    if v >= 2 then
      two = true
      if srank < value(k) then
        srank = value(k)
      end
    end
  end
  
  if two and three then
    return brank, { [1]=srank }
  else
    return 0
  end
end

function analyze( t )
  local val = 0
  local kicker = {}
  local rank = 0
  if ( strush( t ) == 14 ) then
    val = 10
  elseif ( strush( t ) ~= 0 ) then
    val = 9
    rank = strush( t )
  elseif ( fok( t ) ~= 0 ) then
    val = 8
    rank, kicker = fok( t )
    --KICKER
  elseif ( fullhouse( t ) ~= 0 ) then
    val = 7
    rank, kicker = fullhouse( t )
  elseif ( flush( t ) ~= 0 ) then
    val = 6
    rank, kicker = flush( t )
    --KICKER
  elseif ( straight( t ) ~= 0 ) then
    val = 5
    rank = straight( t )
  elseif ( tok( t ) ~= 0 ) then
    val = 4
    rank, kicker = tok( t )
    --KICKER
  elseif ( twopair( t ) ~= 0 ) then
    val = 3
    rank,kicker = twopair( t )
    --KICKER
  elseif ( onepair( t ) ~= 0 ) then
    val = 2
    rank,kicker = onepair( t )
    --KICKER
  else
    val = 1
    rank = value(t[1].rank) -- first card's rank
    table.remove(t,1)
    for k,v in pairs(t) do
      table.insert(kicker,value(v.rank))
    end
    
    while ( #kicker ~= 4 ) do
      table.remove(kicker)
    end
    
    --kicker = t -- KICKER
  end
  return val, rank, kicker
end

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

local kickerscount =
{
  4, -- highcard
  3, -- one pair
  1, -- two pair
  2, -- three of a kind
  0, -- straight
  4, -- flush
  0, -- fullhouse
  1, -- four of a kind
  0, -- straight flush
  0, -- royal flush
}

function winner( t )
  game = {}
  for k,v in pairs( t ) do
    game[k] = v
  end
  
  local val = 0
  for k, v in pairs( game ) do
    if v.value > val then
      val = v.value
    end
  end
  for k, v in pairs( game ) do
    if v.value < val then
      game[k] = nil -- KICK OUT NON-MAX PLAYERS
    end
  end
  
  local max = 0
  for k, v in pairs( game ) do
    if v.rank > max then
      max = v.rank
    end
  end
  for k, v in pairs( game ) do
    if v.rank < max then
      game[k] = nil -- KICK OUT NON-MAX PLAYERS
    end
  end
  
  --Separate by Kickers
  
  for i = 1,kickerscount[val] do -- for every kicker....
    max = 0
    for k, v in pairs( game ) do
      if v.kicker[i] > max then
        max = v.kicker[i]
      end
    end
    for k, v in pairs( game ) do
      if v.kicker[i] < max then
        game[k] = nil -- KICK OUT NON-MAX PLAYERS
      end
    end
  end
  
  return game-- game[k] ... k are the winners
end

end

--[[DEBUG PATCH]]--

root = {}
function getResourceRootElement()
  return root
end

function createPlayer( name )
  return { ["name"] = name } --return this "player"
end

client = createPlayer( "NONAME" )

local opm = "Output:"
function outputChatBox( output, towards )
  if towards == nil then
    print ( opm, output )
    return
  end
  for k,v in pairs( towards ) do
    if k == "name" then
      print ( opm, v, output )
    else
      print ( opm, v.name, output )
    end
  end
end

function getPlayerName( player )
  return player["name"]
end

function triggerClientEvent( cause, event, attachedTo, arg)
  print ( "TriggerC", event)
end

function addEventHandler()
end

function setTimer ( func, time, times, tab ) -- call the winning procedure.. after 1 second .. animations and stuff..
  func(tab)
end

function getThisResource()
  return "brook"
end

function addEvent()
end

function getRootElement()
  return root
end

function addCommandHandler()
end

--[[DEBUG PATCH END]]--

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
--must be a multiple of 2

function createPokerTable() -- idea : you can adjust this to return the table or the number of it
  for i = 1,1000 do
    if pokerTable[i] == nil then
      pokerTable[i] = {}
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
      --break
      return i
    end
  end
end

function startRound(ptab)
  if ptab.count >= 2 then

    ptab.game, ptab.board = newGame(MAX_PLAYERS)

    if ptab.blind == 0 then -- if the table is new
      ptab.blind = math.random(ptab.count) -- set a random blind
      for k,v in pairs(ptab.players) do
        ptab.playing[k] = true
      end
    else -- if the table is not new...

      ptab.blind = cycle( ptab, ptab.blind, 1 ) -- cycle to the next player at the table
      ptab.playing[ptab.blind] = true -- New players always start playing when they reach BB
    end

    --Deal the cards, and set the bets
    for k,v in pairs(ptab.players) do
      ptab.hasCards[k] = ptab.playing[k] or false -- default value is false
      ptab.bets[v] = 0 -- default bet
    end

    ptab.turn = cycle( ptab, ptab.blind, 1, true ) -- the under-the-gun starts betting
    ptab.toCheck = ptab.blind -- the last one to check is the big blind
    ptab.showing = 0
    ptab.showdown= false

    --YOU HAVE TO DEAL THE CARDS WITH hasCards FOR THIS TO WORK PROPERLY
    --Place the blind bets
    transactToPot( ptab.players[ ptab.blind ], ptab, blindStart )
    transactToPot( ptab.players[ cycle( ptab, ptab.blind, -1, true) ], ptab, blindStart/2 ) -- cycle to the last player that has cards

    --transactToPot( ptab.players[1], ptab, 100 )

    --Those transaction can be all-in's also...
    ptab.bet = blindStart

    --SEND ALL THIS INFO TO PLAYERS

    --triggerClientEvent( player, "pokerStart", player, ptab.count, ptab.game[ptab.count], names, playing, board )

    --[[
    startTable( 2, -- playerNo
  { {["rank"] = 1, ["suit"]="S"}, {["rank"] = 1, ["suit"]="H"} }, -- hand
  { [1]="Bugatti", [2]="Zenibryum" }, -- player names
  { [1]=true, [2]=true }, -- hasCards
  {}, -- boardCards
  2 -- blind
)



    ]]

    local pnames = {}

    for k,v in pairs ( ptab.players ) do
      pnames[k] = getPlayerName(v)
    end

    for k,v in pairs ( ptab.players ) do
      --startTable( playerNumber, hand, pnames, pHasCards, pboard, pblind )
      triggerClientEvent( v,
        "pokerStart",
        resourceRoot,
        k,
        ptab.game[k].hand ,
        pnames,
        ptab.hasCards,
        {} ,
        ptab.blind,
        ptab.turn
        )
    end

  end
end

function sendBoard(ptab)
  local board = {}
  for i = 1, ptab.showing do
    board[i] = ptab.board[i]
  end
  --"pokerReceiveBoard"

  triggerClientEvent( ptab.players, "pokerReceiveBoard", resourceRoot, board )
end

--TODO make triggerClientEvent ( ptab.players, "pokerTurn", resourceRoot, ptab.turn ), autosync for ptab.turn :D

function endround( ptab )
  outputChatBox("End of round")
    --compute winners and stuff
    --Is this for necessary? I think it is for the cases when people win by other's folding.
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
    triggerClientEvent ( ptab.players, "pokerTurn", resourceRoot, ptab.turn )
    
    -- TODO : For all-in situations, kick the busted players
end

function phase(ptab)
  if ptab.showing == 0 then
    ptab.showing = 3
    sendBoard(ptab)
  elseif ptab.showing < 5 then
    ptab.showing = ptab.showing + 1
    sendBoard(ptab)
  elseif ptab.showing == 5 and ptab.showdown == false then
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

    triggerClientEvent( ptab.players, "pokerReceiveGame", resourceRoot, game )

    ptab.turn = 0 -- stop processing inputs
    triggerClientEvent ( ptab.players, "pokerTurn", resourceRoot, ptab.turn )

    setTimer ( endround, 1000, 1, ptab ) -- call the winning procedure.. after 1 second .. animations and stuff..
    return
  end




  --TODO : (last todos to solve) : verify if the ptab.turn and ptab.toCheck are assigned right, because they might be faulty
  --handle turns here
  local smallBlind = cycle(ptab,ptab.blind,-1) -- the SM
  local dealer = cycle(ptab,smallBlind,-1) -- the Dealer
  --nextTurn(dealer) -- this will compute the immediate next player after the dealer, that has cards
  ptab.turn = dealer
  ptab.toCheck = cycle( ptab, smallBlind, -1, true ) --the last man to check is the dealer, or someone behind ( if the dealer has no cards )
  nextTurn(ptab) --TODO : is this right? ( 95% yes.. it seems right ) bcs nextTurn will compute the immediate next player after the dealer, that has cards

  --triggerClientEvent ( ptab.players, "pokerTurn", resourceRoot, ptab.turn )

  --SEND INFO TO PLAYERS
end

function nextTurn(ptab)
  ptab.turn = cycle( ptab, ptab.turn, 1, true )

  --TODO : this seems faulty bcs of the recurrence
  if playerChips [ ptab.players [ ptab.turn ] ] == 0 then --In case of all-inners..
    if ptab.toCheck == ptab.turn then
      phase(ptab)
      return
    else
      nextTurn(ptab)
      return
    end
  end

  --SEND INFO TO PLAYERS
  triggerClientEvent ( ptab.players, "pokerTurn", resourceRoot, ptab.turn )
end

function transactToPot(player,ptab,value) -- Add the money from the player to the pot

  --You have to manage all-ins  here. ( because paying the BB's and SB's can be all-ins )

  value = math.floor(value)

  if value < 0 then
    outputChatBox ( "Poker erorr : Value of bet is negative for player " .. getPlayerName(player) )
    return -- no good for negative / null values
  end
  
  if value == 0 then
    return -- it's useless to continue...
  end

  -- playerChips[player] = value
  if playerChips[ player ] then

    if value > playerChips[player] then
      value = playerChips[player]
    end

    --value = math.min( value, playerChips[ client ] )--if a player passes a value higher than his Chips, try to place the highest bet he can with the chips he has...
  else
    outputChatBox ( "Poker erorr : No playerChips(nil) for player " .. getPlayerName(player) )
    return
  end

  --Subtract the values from the players ;)
  playerChips[player] = playerChips[player] - value
  ptab.pot = ptab.pot + value
  ptab.bets[player] = ptab.bets[player] + value

  if ptab.bet < ptab.bets[player] then --conditionated this in case of under-check all-ins
    ptab.bet = ptab.bets[player]
  end

  --Send this info to the players, if value is bigger than 0
  --LOG THIS ACTION
end

function transactToPlayers(players,ptab) -- Share the pot, and log it, for the winners
  --Give players the prize
  
  -- For all-in situations, get the minimum value out of all the bets that are in the showdown ( players with hasCards == true ), then, return extra money for all-inners, then split the money..  
  local minbet = 999999999
  for k,v in pairs(ptab.hasCards) do -- for all the players at the table
    if v then -- if it hasCards
      minbet = math.min( minbet, ptab.bets[ ptab.players[k] ] )
    end
  end
  
  for k,v in pairs(ptab.hasCards) do -- for all the players at the table
    if v then -- if it hasCards
      playerChips[ ptab.players[ k ] ] = playerChips[ ptab.players[ k ] ] + ptab.bets[ ptab.players[ k ] ] - minbet
    end
  end

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
  
  -- when someone leaves always check how many players are left ( consider winning by folding of others )
  local hasCardsNo = 0
  --ptab.hasCards[number] = true/false
  for k,v in pairs( ptab.hasCards ) do
    if v == true then
      hasCardsNo = hasCardsNo + 1
    end
  end
  if hasCardsNo == 1 then
    endround( ptab )
  else
    if ptab.toCheck == playerNo then
      if ptab.turn == playerNo then
        phase(ptab)
      else
        ptab.toCheck = cycle(ptab,playerNo,-1,true)
      end
    elseif ptab.turn == playerNo then
      nextTurn(ptab)
    end
  end
  
  --TODO: SEND INFO to players regarding someone leaving
end

function tableAddPlayer(player, ptab) --TODO : only add players that have playerChips[player] > certain amount

  if not playerChips[player] then
    outputChatBox ("Poker error : no chips for " .. getPlayerName ( player ) )
    return false
  end --error handling

  if playerChips[player] > blindStart then
    if ptab.count < MAX_PLAYERS then
      local playerNo = 0
      for i = 1, MAX_PLAYERS do
        if ptab.players[i] == nil then
          playerNo = i
          break
        end
      end
      
      playerSeats[player] = ptab
      --modify cycle function for linking..
      ptab.count = ptab.count + 1
      ptab.players[playerNo] = player
      ptab.playing[playerNo] = false
      ptab.hasCards[playerNo] = false

      triggerClientEvent ( ptab.players, "pokerOnJoin", resourceRoot, playerNo, getPlayerName(player) )
      
      --TODO : If the player has been successfully added, send him the turn, table, bets.. bla bla bla
      --send him the game state.
      return true
    end
  else
    outputChatBox( "Poker error : player " .. getPlayerName(player) .. " has too few chips to join")
  end
  --If nothing returns true...
  return false
end

--CLIENT COMMANDS HANDLING

function playerBet( value )
  --client,value
  
  
  --TODO :If the player bets a value under a "check" at least... the game won't turn() when he adds more until a check
  --because of how it's written below... - make sure he cannot bet something under "check" except for all-ins
  
  
  
  outputChatBox( "Player " .. client.name .. " betted " .. value )

  if value < 0 then
    return -- no good for negative values
  end

  -- playerChips[player] = value
  if playerChips[ client ] then

    if value > playerChips[client] then
      value = playerChips[client]
    end

   -- value = math.min( math.floor(value), playerChips[ client ] )--if a player passes a value higher than his Chips, try to place the highest bet he can with the chips he has...
  else
    outputChatBox ( "Poker erorr : No playerChips for player " .. getPlayerName(client) )
    return
  end

  --check if the player actually plays at a table, and also, check if it's HIS turn.
  local ptab = playerSeats[client]

  if not ptab then
    return -- the player is not sitting at a table
  end

  if ptab.turn ~= getPlayerNo(ptab,client) then
    return -- it is not his turn
  end

  --TODO NOTE : The if's and else's below can be rewritten so than you have less ifs... ( only in this form )
  --because its about the fact that instructions repeat, only the condition on the all-in checks differ...
  --even though, you have to have this form to implement a cleaner way to handle minimum raises

  if value == playerChips[client] then -- if it is an all-in

    if ptab.bets[client] + value > ptab.bet then -- if it is an all-in raise...

      transactToPot( client, ptab, value )
      ptab.toCheck = cycle(ptab,ptab.turn,-1,true)--last one playing
      nextTurn(ptab)

    else -- if it is an all-in check..

      transactToPot( client, ptab, value )
      if ptab.players[toCheck] == client then -- if it's the last guy to check turn... then move to flop,turn,river
        phase()
      else
        nextTurn(ptab)
      end

    end

  elseif ptab.bets[client] + value > ptab.bet then -- if it is a raise, TODO : Implement a minimum raises
    transactToPot( client, ptab, value )
    ptab.toCheck = cycle(ptab,ptab.turn,-1,true)--last one playing
    nextTurn(ptab)

  elseif ptab.bets[client] + value == ptab.bet then -- if it is a check,
    transactToPot( client, ptab, value )
    outputChatBox("CHECK CHECK CHECK" .. ptab.toCheck)
    if ptab.players[ptab.toCheck] == client then -- if it's the last guy to check turn... then move to flop,turn,river
      outputChatBox("PHASE")
      phase(ptab)
      
    else
      outputChatBox("check")
      nextTurn(ptab)
    end

  end

end

function playerFold( )
  --client

  local ptab = playerSeats[client]
  if ptab ~= nil then
    local playerNo = getPlayerNo(ptab,client)
    if ptab.hasCards[ playerNo ] == true and ptab.turn == playerNo then

      ptab.hasCards[ playerNo ] = false

      triggerClientEvent ( ptab.players, "playerFolded", resourceRoot, playerNo ) -- send info to players
      
      -- when someone folds always check how many players are left ( consider winning by folding of others )
      local hasCardsNo = 0
      --ptab.hasCards[number] = true/false
      for k,v in pairs( ptab.hasCards ) do
        if v == true then
          hasCardsNo = hasCardsNo + 1
        end
      end
      if hasCardsNo == 1 then
        endround( ptab )
      else
        nextTurn(ptab)
      end
    end
  end
end
addEvent ( "onPlayerFold", true )
addEventHandler ( "onPlayerFold", getRootElement(), playerFold )

--[[DEBUG FUNCTIONS]]--
--[[
function debugfunc(player, command)
  outputChatBox("The command ran")
  createPokerTable()
  outputChatBox("Created the table")

  playerChips[player] = 1000
  outputChatBox("Got some chips")

  tableAddPlayer( player, pokerTable[1] )
  outputChatBox("add player")
end

addCommandHandler( "pp1", debugfunc )

function debugfunc1(player, command)
  playerChips[player] = 1000
  outputChatBox("Got some chips")

  tableAddPlayer( player, pokerTable[1] )
  outputChatBox("add player")
  startRound( pokerTable[1] )

  outputChatBox("Round started")
end

addCommandHandler( "pp2", debugfunc1 )

function giveChips(player,command) --TODO remove this debug function
  playerChips[player] = (playerChips[player] or 0) + 10000
  outputChatBox("Chips have been added to you: " .. playerChips[player], player)
end
addCommandHandler("givechips",giveChips)
]]
--[[DEBUG FUNCTIONS END]]--

--TODO - modify the playerChips' table meta functions so that when you assign a value to it, it will automatically sync it with the clients ( the client whose money are in the function + the table players )


--[[CONTROL FUNCTIONS]]--

--local pokerTable = {}
function listTables( player, command )

  for k,v in pairs(pokerTable) do
    outputChatBox( "ID : " .. k .. " turn : " .. v.turn .. " players : " .. v.count .. "/8", player )
  end
end
addCommandHandler( "listtables", listTables )

function createTab( player,command )
  local tabNo = createPokerTable()
  outputChatBox( "Table with number " .. tabNo .. " has been created!", player )
end
addCommandHandler( "createtab", createTab )

function joinTab( player, command, tableNo )
  tableNo = tonumber(tableNo)
  if tableNo then
    local ptab = pokerTable[tableNo]
    if ptab then
      if ptab.count < MAX_PLAYERS then
        tableAddPlayer(player, ptab)
        outputChatBox("You have joined table " .. tableNo, player)
      end
    end
  end
end
addCommandHandler( "jointab", joinTab )

function startTab ( player, command ) -- TODO : make sure everyone has to vote for the round to start. or create a votemanager
  local ptab = playerSeats[player]
  if ptab then
    if ptab.count >= 2 then
      startRound( ptab )
      outputChatBox( "Round has started" )
    else
      outputChatBox( "Not enough players to start the round " )
    end
  end
end
addCommandHandler( "starttab", startTab )

function checkChips(player,command)
  if playerChips[player] then
    outputChatBox("This is how many chips you have: " .. playerChips[player], player)
  else
    outputChatBox("You have no chips ( pchips = false )", player)
  end
end
addCommandHandler("chips",checkChips)

--[[CONTROL FUNCTIONS END]]--

--TODO's : optimize server-client sync.. ( minimize table sending overhead )
--TODO's : clean the code, and comment every bit.


--[[DEBUG PATCH]]--

function giveChips(player,command) --TODO remove this debug function
  playerChips[player] = (playerChips[player] or 0) + 10000
  outputChatBox("Chips have been added to you: " .. playerChips[player], player)
end

local zenon = createPlayer("Zenon")
local bugatti = createPlayer("Bugatti")
local jeff = createPlayer("Jeff")
local matt = createPlayer("Matt")

giveChips(zenon)
giveChips(bugatti)
giveChips(jeff)
giveChips(matt)

createTab()
listTables()

ptab = pokerTable[1]

joinTab( zenon, "jointab", 1 )
joinTab( bugatti, "jointab", 1 )
joinTab( jeff, "jointab", 1 )



playerChips[zenon] = 500

startTab( zenon )

function state()
print("-----------------------------")
io.write( "Bets : " )
for k,v in pairs(ptab.players) do
  io.write ( v.name, k, "-", tostring(ptab.bets[v]), " ")
end print()

io.write( "Money : " )
for k,v in pairs(ptab.players) do
  io.write ( v.name, "-", tostring(playerChips[v]), " ")
end print()

if ptab.turn ~= 0 then
  print ( "Turn : ", ptab.turn, ptab.players[ptab.turn].name ) 
else
  print ( "Turn : 0 - table is paused" )
end
print("-----------------------------\n")
end

--[[
client = bugatti
playerFold()
]]

tableRemovePlayer(bugatti, ptab)
joinTab( matt, "jointab", 1 )

state()

client = jeff
playerBet( 50 )
state()

client = zenon
playerBet( 0 )
state()

---------------- FLOP

client = jeff
playerBet( 0 )
state()

client = zenon
playerBet( 0 )
state()

---------------- Turn

client = jeff
playerBet( 0 )
state()

client = zenon
playerBet( 0 )
state()

---------------- River

client = jeff
playerBet( 40000 )
state()

client = zenon
playerBet( 40000 )

state()

--[[DEBUG PATCH END]]--

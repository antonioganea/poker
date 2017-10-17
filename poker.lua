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

--[[
function fff( game )
  for k,v in pairs( game ) do
    local strkicker = table.concat(v.kicker,", ")
    io.write( k .. " : " .. v.value .. " : " .. v.rank .. " : " .. strkicker .. " -- | ")
    for i,j in pairs( v.hand ) do
      io.write(j.rank .. " " .. j.suit.. " | ")
    end
    print()
  end
end

local x,b = newgame(5)
for k,v in pairs(b) do
  io.write(getCardName(v.rank,v.suit) .. ", ")
end

print()
fff(x)
print("Winner(s) : ")
winner(x)
]]


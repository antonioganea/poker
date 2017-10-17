resourceRoot = getResourceRootElement(getThisResource()) 

local playerSeats = {}
playerSeats[2] = {1,5}
playerSeats[3] = {1,4,6}
playerSeats[4] = {1,3,5,7}
playerSeats[5] = {1,3,4,6,7}
playerSeats[6] = {1,3,4,5,6,7}
playerSeats[7] = {8,2,3,4,5,6,7}
playerSeats[8] = {1,2,3,4,5,6,7,8}

local ScreenWidth, ScreenHeight = guiGetScreenSize()

local tablePosition = {}

tablePosition[1] = { ScreenWidth/2, ScreenHeight * 3/4 }
tablePosition[2] = { ScreenWidth * 2/8, ScreenHeight * 3/4 }
tablePosition[3] = { ScreenWidth * 1/8, ScreenHeight/2 }

tablePosition[4] = { ScreenWidth * 2/8, ScreenHeight * 1/4 }
tablePosition[5] = { ScreenWidth/2, ScreenHeight * 1/4 }
tablePosition[6] = { ScreenWidth * 6/8, ScreenHeight * 1/4 }

tablePosition[7] = { ScreenWidth * 7/8, ScreenHeight/2 }
tablePosition[8] = { ScreenWidth * 6/8, ScreenHeight * 3/4 }

local suits = { ["C"]=1, ["H"]=2, ["S"]=3, ["D"]=4 }
local cardX = 73
local cardY = 98

local cardSpacing = 8
  
local cardMaterial = dxCreateTexture( "pcards.png" )  -- Create texture
local backMaterial = dxCreateTexture( "back.png" )
local smallBlind = dxCreateTexture( "sblind.png" )
local bigBlind = dxCreateTexture( "bblind.png" )
local pricedown = dxCreateFont ( "pricedown.ttf", 16 ) 

local BoardX = ScreenWidth/2 - cardX * 5/2 - cardSpacing * 4
local BoardY = ScreenHeight/2 + cardY / 2

--Controls
local foldButton = guiCreateButton ( ScreenWidth/2 - 75, ScreenHeight*9/10, 50, 20 , "Fold" , false )
local checkButton= guiCreateButton ( ScreenWidth/2 - 25, ScreenHeight*9/10, 50, 20 , "Check" , false )
local raiseButton= guiCreateButton ( ScreenWidth/2 + 25, ScreenHeight*9/10, 50, 20 , "Raise" , false )

function fold()
  outputChatBox("DEBUG! YOU CLICKED THE FOLD BUTTON!",0,0,255)
  --TODO : First check if you are sitting at a table and stuff
  triggerServerEvent ( "onPlayerFold", resourceRoot ) -- no arguments
end
addEventHandler ( "onClientGUIClick", foldButton, fold )

function check()
  outputChatBox("DEBUG! YOU CLICKED THE CHECK BUTTON!",0,0,255)
  --TODO : First check if you are sitting at a table and stuff
  triggerServerEvent ( "onPlayerCheck", resourceRoot ) -- no arguments
end
addEventHandler ( "onClientGUIClick", checkButton, check )

function raise()
  outputChatBox("DEBUG! YOU CLICKED THE RAISE BUTTON!",0,0,255)
  --TODO : First check if you are sitting at a table and stuff
  triggerServerEvent ( "onPlayerRaise", resourceRoot ) -- no arguments
end
addEventHandler ( "onClientGUIClick", raiseButton, raise )

-------------------------------------------------

--ASPECTS ABOUT THE TABLE
local seats = {} -- local seats
local isGameOn = false

local cards = {} -- cards[1] = { card1, card2 }
local hasCards = {} -- cards[1] = true / false
local boardCards = {} -- boardCards = { bcard1, bcard2, bcard3, bcard4, bcard5 }
local blind = 0 -- Who is the bigblind

local playerNo = 8 -- how the seats are arranged
local myPlayer = 1
local names = {}

-- seats[PLAYER] = SEAT
function arrangeSeats( myplayer, playerNo )
  local pos = 1
  for i = myPlayer, playerNo do
    --print(i .. " " .. pos)
    seats[i] = playerSeats[playerNo][pos]
    pos = pos + 1
  end

  for i = 1, myPlayer-1 do
    seats[i] = playerSeats[playerNo][pos]
    pos = pos + 1
  end
end

function startTable( playerNumber, hand, pnames, pHasCards, pboard, pblind )
  outputChatBox("INITIATING TABLE!",255,255,0)
  isGameOn = true
  blind = pblind
  game = {}
  game[playerNumber] = hand
  playerNo = #pnames
  hasCards = pHasCards
  board = pboard
  names = pnames
  myPlayer = playerNumber
  arrangeSeats( playerNumber, playerNo )
end
addEvent ( "pokerStart", true )
addEventHandler ( "pokerStart", getRootElement(), startTable )
--triggerClientEvent ( player, "pokerStart", player, ptab.count, ptab.game[ptab.count], names, playing, board )

startTable( 2, -- playerNo
  { {["rank"] = 1, ["suit"]="S"}, {["rank"] = 1, ["suit"]="H"} }, -- hand
  { [1]="Bugatti", [2]="Zenibryum" }, -- player names
  { [1]=true, [2]=true }, -- hasCards
  {}, -- boardCards
  2 -- blind
)

function receiveGame( pgame )
  game = pgame
end
addEvent ( "pokerReceiveGame", true )
addEventHandler ( "pokerReceiveGame", getRootElement(), receiveGame, true )
--triggerClientEvent ( ptab.players, "pokerReceiveGame", resourceRoot, ptab.game)

function receiveBoard( pboard )
  board = pboard
end
addEvent ( "pokerReceiveBoard", true )
addEventHandler ( "pokerReceiveBoard", getRootElement(), receiveBoard, true )
--triggerClientEvent ( ptab.players, "pokerReceiveBoard", resourceRoot, board )


--triggerClientEvent ( ptab.players, "pokerReceiveBoard", resourceRoot, board )

function onPlayerJoin( playerNumber, name )
  if playerNumber ~= myPlayer then
    hasCards[playerNumber] = false
    names[playerNumber] = name
  end
end
addEvent ( "pokerOnJoin", true )
addEventHandler ( "pokerOnJoin", getRootElement(), onPlayerJoin, true )
--triggerClientEvent ( player, "pokerOnJoin", player, ptab.count, getPlayerName )


function onPlayerLeave( number )
  playing[playerNumber] = nil
  names[playerNumber] = nil
end
addEvent ( "pokerOnLeave", true )
addEventHandler ( "pokerOnLeave", getRootElement(), onPlayerLeave, true )
--triggerClientEvent ( ptab.players, "pokerOnLeave", player, number )

for k,v in pairs(seats) do
  outputChatBox( "player " .. k .. " seats at position " .. v)
end

function cycle( x, dir ) -- +1 to cycle right, -1 to cycle left
  local value = x+dir
  if value == 0 then
    return playerNo
  end
  if value == playerNo+1 then
    return 0
  end
  return value
end

--[[
function last(x)
  if x == 1 then
    return playerNo
  else
    return x-1
  end
end
]]

function drawBoard()
  for k,v in pairs(board) do
    dxDrawImageSection ( BoardX+(k-1)*(cardX+2*cardSpacing), BoardY, cardX, cardY, (board[k].rank-1)*cardX+2, (suits[board[k].suit]-1)*cardY+2, cardX-2, cardY-2, cardMaterial )
  end
end

function drawBlinds()
  if blind ~= 0 then
    if hasCards[blind] then
      dxDrawImage( tablePosition[seats[blind]][1]+cardSpacing*2+cardX, tablePosition[seats[blind]][2]-32, 64, 64, bigBlind)
    end
    
    if hasCards[cycle(blind,-1)] then
      dxDrawImage( tablePosition[seats[cycle(blind,-1)]][1]+cardSpacing*2+cardX, tablePosition[seats[cycle(blind,-1)]][2]-32, 64, 64, smallBlind)
    end
  end
end

function drawCards()
    --local v = game[myPlayer]
    --local k = myPlayer
    for k,v in pairs(game) do
      --local v = game[k]
      if hasCards[k] then
        dxDrawImageSection ( tablePosition[seats[k]][1]-cardSpacing-cardX, tablePosition[seats[k]][2] - cardY / 2, cardX, cardY, (v[1].rank-1)*cardX+2, (suits[v[1].suit]-1)*cardY+2, cardX-2, cardY-2, cardMaterial )
        dxDrawImageSection ( tablePosition[seats[k]][1]+cardSpacing, tablePosition[seats[k]][2] - cardY / 2, cardX, cardY, (v[2].rank-1)*cardX+2, (suits[v[2].suit]-1)*cardY+2, cardX-2, cardY-2, cardMaterial )
      end
    end
end

function drawBacks()
    --local v = game[myPlayer]
    --local k = myPlayer
    for k = 1,playerNo do
      --local v = game[k]
      if hasCards[k] then
        dxDrawImageSection ( tablePosition[seats[k]][1]-cardSpacing-cardX, tablePosition[seats[k]][2] - cardY / 2, cardX, cardY, 0, 0, cardX-2, cardY-2, backMaterial )
        dxDrawImageSection ( tablePosition[seats[k]][1]+cardSpacing, tablePosition[seats[k]][2] - cardY / 2, cardX, cardY, 0, 0, cardX-2, cardY-2, backMaterial )
        --dxDrawImage(400, 300, 128, 128, 'img.jpg') -- Draw the whole image to be able to identify the difference
      end
    end
end

local lineColor = tocolor(0, 127, 0)

function drawNames()
    --local v = game[myPlayer]
    --local k = myPlayer
    for k = 1,playerNo do
      --local v = game[k]
      if names[k] ~= nil then
        dxDrawText ( names[k], tablePosition[seats[k]][1], tablePosition[seats[k]][2]+cardY/2,

           tablePosition[seats[k]][1], tablePosition[seats[k]][2]+cardY/2, lineColor, 1,
                  pricedown, "center", "top", false, false )
                  --bool postGUI=false, bool colorCoded=false, bool subPixelPositioning=false,
                  --float fRotation=0, float fRotationCenterX=0, float fRotationCenterY=0 ] )
      end
    end
end



addEventHandler('onClientRender', root, function()
  if isGameOn then
    
    dxDrawRectangle ( 0, 0, ScreenWidth, ScreenHeight, tocolor ( 0, 0, 0, 200 ) )
    drawBoard()
    drawBacks()
    drawCards()
    drawBlinds()
    drawNames()
    
    dxDrawLine( BoardX,BoardY+cardY+cardSpacing, BoardX+ 5*cardX +8*cardSpacing, BoardY+cardY+cardSpacing, lineColor )
    --dxDrawLine( ScreenWidth/2, 0, ScreenWidth/2, ScreenHeight, lineColor )
  end
end)

-- Use 'toggle' command to switch image on and off
addCommandHandler( "toggle",
    function()
        isGameOn = not isGameOn
    end
)
outputChatBox("DEBUG! CLIENTSIDE SCRIPT LAUNCHED!",0,0,255)

functor
export
   isTurnByTurn:IsTurnByTurn
   useExtention:UseExtention
   printOK:PrintOK
   nbRow:NbRow
   nbColumn:NbColumn
   map:Map
   nbBombers:NbBombers
   bombers:Bombers
   colorsBombers:ColorBombers
   nbLives:NbLives
   nbBombs:NbBombs
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   fire:Fire
   timingBomb:TimingBomb
   timingBombMin:TimingBombMin
   timingBombMax:TimingBombMax
    player1KeyUp:Player1KeyUp
    player1KeyDown:Player1KeyDown
    player1KeyLeft:Player1KeyLeft
    player1KeyRight:Player1KeyRight
    player1KeyBomb:Player1KeyBomb

    player2KeyUp:Player2KeyUp
    player2KeyDown:Player2KeyDown
    player2KeyLeft:Player2KeyLeft
    player2KeyRight:Player2KeyRight
    player2KeyBomb:Player2KeyBomb

    keyPlayer1:KeyPlayer1
    keyPlayer2:KeyPlayer2
define
   IsTurnByTurn UseExtention PrintOK
   NbRow NbColumn Map
   NbBombers Bombers ColorBombers
   NbLives NbBombs
   ThinkMin ThinkMax
   TimingBomb TimingBombMin TimingBombMax Fire
  Player1KeyUp
  Player1KeyDown
  Player1KeyLeft
  Player1KeyRight
  Player1KeyBomb

  Player2KeyUp
  Player2KeyDown
  Player2KeyLeft
  Player2KeyRight
  Player2KeyBomb

  KeyPlayer1
  KeyPlayer2
in 


%%%% Style of game %%%%
   
   IsTurnByTurn = true
   UseExtention = false
   PrintOK = false


%%%% Description of the map %%%%
   
   NbRow = 7
   NbColumn = 13
   %Map = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
    % [1 0 2 0 0 0 0 0 0 0 0 0 1]
     %[1 0 0 0 2 2 0 0 0 0 0 0 1]
     %[1 0 0 2 0 0 0 3 0 0 0 0 1]
     %[1 0 0 0 0 0 3 0 0 2 0 0 1]
     %[1 4 0 0 0 0 0 0 0 0 0 4 1]
     %[1 1 1 1 1 1 1 1 1 1 1 1 1]]
   Map = [[1 1 1 1 1 1 1 1 1 1 1 1 1]
	  [1 4 0 2 2 2 2 2 2 2 0 4 1]
	  [1 0 1 3 1 2 1 2 1 2 1 0 1]
	  [1 2 2 2 3 2 2 2 2 3 2 2 1]
	  [1 0 1 2 1 2 1 3 1 2 1 0 1]
	  [1 4 0 2 2 2 2 2 2 2 0 4 1]
	  [1 1 1 1 1 1 1 1 1 1 1 1 1]]

%%%% Players description %%%%

   NbBombers = 2
   Bombers = [player096IA player096Player1]
   ColorBombers = [green red]

%%%% Parameters %%%%

   NbLives = 3
   NbBombs = 1
 
   ThinkMin = 500  % in millisecond
   ThinkMax = 2000 % in millisecond
   
   Fire = 3
   TimingBomb = 3 
   TimingBombMin = 3000 % in millisecond
   TimingBombMax = 4000 % in millisecond

  %%%% Parameters %%%%

  %% /!\ the Y Axis is inverted
  Player1KeyUp = w
  Player1KeyDown = s
  Player1KeyLeft = a
  Player1KeyRight = d
  Player1KeyBomb = b

  KeyPlayer1 = [Player1KeyUp
    Player1KeyDown
    Player1KeyLeft
    Player1KeyRight
    Player1KeyBomb ]

  Player2KeyUp = 'Up'
  Player2KeyDown = 'Down'
  Player2KeyLeft = 'Left'
  Player2KeyRight = 'Right'
  Player2KeyBomb = 'Return'

  KeyPlayer2 = [Player2KeyUp
    Player2KeyDown
    Player2KeyLeft
    Player2KeyRight
    Player2KeyBomb ]

end

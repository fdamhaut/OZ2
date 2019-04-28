functor
import
  GUI
  Input
  PlayerManager
define
  % Procs & Fun

  SendGui
  SendMult
  SendPlayers

  WaitList
  ListRemove

  ReadMap
  FindMap
  IsNear

  RemoveAllFire
  PlaceBomb
  RemoveBomb
  Move
  RemoveBox
  Die

  InitPlayers
  GeneratePlayers
  SpawnPlayers
  DataPlayers
  GetActions

  DestroyBox
  ExplodeBomb
  PlayerActions
  TickBombs

  Game


  % Data

  PortPlayers
  PortGUI

  ThisMap

  Players
  PlayersData
  Spawns
  Walls
  Boxes
in

  %%%%% UTILS : Communication

  PortGUI = {GUI.portWindow}

  proc{SendGui Msg}
    {Send PortGUI Msg}
  end

  proc{SendMult Ports Msg}
    case Ports of H|T then
      {Send Msg H}
      {SendMult Msg T}
    end
  end

  proc{SendPlayers Msg}
    {SendMult PortPlayers Msg}
  end


  %%%%% UTILS : List Function

  proc{WaitList List}
    case List of H|T then
      {Wait H}
      {WaitList T}
    end
  end

  fun{ListRemove List Rem}
    fun{ListRemoveIn List Rem Acc}
      case List of Rem|T then
        Acc|T
      [] H|T then
        {ListRemoveIn T Rem Acc|H}
      else
        Acc|nil
      end
    end
  in
    case List of Rem|T then 
      T
    [] H|T then
      {ListRemoveIn T Rem H}
    else
      nil
    end
  end

  %%%%%% UTILS : Map

  ThisMap = Input.map

  fun{ReadMap Pos}
    case Pos of pt(x:X y:Y) then
      {List.nth {List.nth ThisMap Y} X}
    else
      raise
        unknownPOS('POS unavailable')
      end
      0
    end
  end


  fun{FindMap ToFind}
    fun{Pos Line Y X Acc}
      case Line of H|T then
        if H == ToFind then
          {Pos T Y X+1 pt(x:X y:Y)|Acc}
        else
          {Pos T Y X+1}
        end
      else
        Acc
      end
    end

    fun{Line Map Y Acc}
      case Map of H|T then
        {Line T Y+1 {Pos H Y 1 nil}|Acc}
      else
        Acc
      end
    end
  in
    {Flatten {Line ThisMap 1 nil}}
  end

  fun{IsNear Pos1 Pos2}
    case Pos1#Pos2 of pt(x:X1 y:Y1)#pt(x:X2 y:Y2) then
      if X1 == X2 then
        (Y1 == Y2+1) || (Y1 == Y2-1) 
      elseif Y1 == Y2 then
        (X1 == X2+1) || (X1 == X2-1)
      end
    end
    false
  end

  %%%%% UTILS : MapEvents & Mandatory Messages to Players

  proc{RemoveAllFire Pos}
    case Pos of H|T then
      {SendGui hideFire(Pos)}
      {RemoveAllFire T}
    end
  end

  proc{PlaceBomb Pos}
    {SendGui spawnBomb(Pos)}
    {SendPlayers info(bombPlanted(Pos))}
  end

  proc{RemoveBomb Pos}
    {SendGui hideBomb(Pos)}
    {SendPlayers info(bombExploded(Pos))}
  end  

  proc{Move ID Pos}
    {SendGui movePlayer(ID Pos)}
    {SendPlayers info(movePlayer(ID Pos))}
  end

  proc{RemoveBox Pos}
    {SendGui hideBox(Pos)}
    {SendPlayers info(boxRemoved(Pos))}
  end

  proc{Die ID}
    {SendGui hidePlayer(ID)}
    {SendPlayers info(deadPlayer(ID))}
  end


  %%%%% UTILS : Players

  fun{InitPlayers}
    fun{InitPlayer ID Colors}
      Bomber
    in
      case Colors of HColors|TColors then
        Bomber = bomber(id:ID color:HColors name:ID)
        {SendGui InitPlayer(Bomber)}
        Bomber|{InitPlayer ID+1 TColors}
      else
        nil
      end
    end
  in
    {InitPlayer 1 Input.colorsBombers}
  end

  fun{GeneratePlayers}
    fun{GeneratePlayer Bombers Types}
      case Types#Bombers of (HTypes|TTypes)#(HBombers|TBombers) then
        {PlayerManager.PlayerGenerator HTypes HBombers}|{InitPlayer ID+1 TTypes TBombers}
      else
        nil
      end
    end
  in
    {GeneratePlayer Players Input.Bombers}
  end

  fun{SpawnPlayers}
    proc{SpawnPlayer Bombers Spawns}
      case Bombers#Spawns of (HB|TB)#(HS|TS) then
        {SendGui spawnPlayer(HB HS)}
        {SendPlayers info(SpawnPlayer(HB HS))}
        {SpawnPlayer TB TS}
      end
    end
    Spawns
  in
    Spawns = {FindMap 4}
    {SpawnPlayer Players Spawns}
    Spawns
  end

  fun{DataPlayers}
    fun{DataPlayer Bombers Spawns}
      case Bombers#Spawns of (bomber(id:ID color:COLOR name:NAME)|TBombers)#(HS|TS) then
        Bdata(id:bomber(id:ID color:COLOR name:NAME) life:Input.NbLives bombs:Input.NbBombs pos:HS spawn:HS score:0)|{DataPlayer TBombers TS}
      else
        nil
      end
    end
  in
    {DataPlayer Players Spawns}
  end

  fun{GetActions}
    fun{GetPlayerAction PortPlayer}
      ID
      Act
    in
      case PortPlayer of H|T then
        {Send H doaction(ID Act)}
        Act|{GetPlayerAction T}
      else
        nil
      end
    end
  in
    {GetPlayerAction PortPlayer}
  end


  %%%%% GameEvent

  proc{DetroyBox Pos Boxes Bonus Points NewBoxes NewBonus NewPoints}
    if {List.member Pos Boxes} then
      if {ReadMap Pos} == 2 then
        {RemoveBox Pos}
        {SendGui spawnPoint(Pos)}
        NewPoints = Pos|Points
        NewBonus = Bonus
        NewBoxes = {ListRemove Boxes Pos}
      else
        {RemoveBox Pos}
        {SendGui spawnBonus(Pos)}
        NewBonus = Pos|Bonus
        NewBoxes = {ListRemove Boxes Pos}
        NewPoints = Points
      end
    end
  end
      

  fun{ExplodeBomb Pos Walls Boxes Bonus Bombs Points NewBoxes NewBonus NewBombs NewPoints NewFire}
    fun{SpreadFire X Y DeltaX DeltaY Remaining Boxes Bonus Bombs Points NewBoxes NewBonus NewBombs NewPoints NewFire}
      if {List.member pt(x:X y:Y) Walls} then
        skip
      elseif {List.member pt(x:X y:Y) Boxes} then
        {DestroyBox pt(x:X y:Y) Boxes Bonus Points NewBoxes NewBonus NewPoints}
        NewFire
      elseif {List.member pt(x:X y:Y)#Time Bombs} then
        {ExplodeBomb pt(x:X y:Y) Pos|Walls Boxes Bonus Bombs Points NewBoxes NewBonus NewBombs NewPoints NewFire}
      elseif Remaining > 0 then
        {SpreadFire X+DeltaX Y+DeltaY DeltaX DeltaY Remaining-1 Boxes Bonus Bombs Points NewBoxes NewBonus NewBombs NewPoints Pos|NewFire}
      else
        NewFire
      end

      MidBoxes1
      MidBoxes2
      MidBoxes3
      MidBonus1
      MidBonus2
      MidBonus3
      MidPoints1
      MidPoints2
      MidPoints3
      MidBombs1
      MidBombs2
      MidBombs3
      Fire1
      Fire2
      Fire3

      FireDist
  in
    if {list.member Pos Bombs} then
      FireDist = Input.Fire
      case Pos of pt(x:X y:Y) then
        Fire1 = {SpreadFire X Y 1 0 FireDist Boxes Bonus {ListRemove Pos Bombs} Points MidBoxes1 MidBonus1 MidBombs1 MidPoints1 nil}
        Fire2 = {SpreadFire X Y -1 0 FireDist MidBoxes1 MidBonus1 MidBombs1 MidPoints1 MidBoxes2 MidBonus2 MidBombs2 MidPoints2 Fire1}
        Fire3 = {SpreadFire X Y -1 0 FireDist MidBoxes2 MidBonus2 MidBombs2 MidPoints2 MidBoxes3 MidBonus3 MidBombs3 MidPoints3 Fire2}
        {SpreadFire X Y -1 0 FireDist MidBoxes3 MidBonus3 MidBombs3 MidPoints3 NewBoxes NewBonus NewBombs NewPoints Fire3}
      end
    end
  end

  fun{PlayerActions PlayerData Actions Bonus Bombs Points NewBonus NewBombs NewPoints Fire}
    fun{PlayerAction PlayersData Action Bonus Bombs Points}
      if{Value.isDet Action} then
        case PlayersData of Bdata(id:ID life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE)|TData then
          case Action 
          of move(Pos)|T then
            if {IsNear Pos POS} && !({List.member Pos Walls} || {List.member Pos Boxes} || {List.member Pos Bombs}) then
              if {List.member Pos Fire} then
                if LIFE > 1 then
                  {Move ID SPAWN}
                  Bdata(id:ID life:LIFE-1 bombs:BOMBS pos:SPAWN spawn:SPAWN score:SCORE)|{PlayerAction TData T Bonus Bombs Points}
                else
                  {Die ID}
                  Bdata(id:ID life:LIFE-1 bombs:BOMBS pos:SPAWN spawn:SPAWN score:SCORE)|{PlayerAction TData T Bonus Bombs Points}
                end
              else
                {Move ID Pos}
                if {List.member Pos Points} then
                  Bdata(id:ID life:LIFE bombs:BOMBS pos:Pos spawn:SPAWN score:SCORE+1)|{PlayerAction TData T Bonus Bombs {ListRemove Points Pos}}
                elseif {List.member Pos Bonus} then
                  if ({OS.rand} mod 2) == 0 then
                    Bdata(id:ID life:LIFE bombs:BOMBS+1 pos:Pos spawn:SPAWN score:SCORE)|{PlayerAction TData T {ListRemove Bonus Pos} Bombs Points}
                  else
                    Bdata(id:ID life:LIFE bombs:BOMBS pos:Pos spawn:SPAWN score:SCORE+10)|{PlayerAction TData T {ListRemove Bonus Pos} Bombs Points}
                  end
                else
                  Bdata(id:ID life:LIFE bombs:BOMBS pos:Pos spawn:SPAWN score:SCORE+1)|{PlayerAction TData T Bonus Bombs Points}
                end
              end
            else
              Bdata(id:ID life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE)|{PlayerAction TData T Bonus Bombs}
            end
          [] bomb(Pos)|T then
            if Pos == POS && BOMBS > 1 then
              {PlaceBomb Pos}
              Bdata(id:ID life:LIFE bombs:BOMBS-1 pos:POS spawn:SPAWN score:SCORE)|{PlayerAction TData T Pos#TickingBomb|Bombs}
            else
              Bdata(id:ID life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE)|{PlayerAction TData T Bombs}
            end
          [] H|T then
            Bdata(id:ID life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE)|{PlayerAction TData T Bombs}
          else
            NewBombs = Bombs
            NewBonus = Bonus
            NewPoints = Points
            nil
          end
        end
      end
    end
  in
    {PlayerAction PlayerData Actions Bombs NewBombs}
  end


  proc{TickBombs Boxes Bonus Bombs Points Walls NewBoxes NewBonus NewBombs NewPoints NewFire}
    proc{TickBomb Boxes Bonus Bombs BombsLeft Points Walls Fire NewBoxes NewBonus NewBombs NewPoints NewFire}
      MidBoxes
      MidBombs
      MidPoints
      MidFire 
    in
      case Bombs of Pos#Time|T then
        if Input.isTurnByTurn then
          if Time > 1 then
            {TickBomb Boxes Bonus Bombs BombsLeft Points Walls Fire NewBoxes NewBonus NewBombs NewPoints NewFire}
          else
            MidFire = fun{ExplodeBomb Pos Walls Boxes Bonus Bombs Points NewBoxes NewBonus NewBombs NewPoints NewFire}



  %%%%% GameLoop

  proc{Game}
    proc{GameLoop PlayersData Boxes Bonus Bombs Point Fire}
      Actions

      MidBombs

      NewData
      NewPos
      NewBoxes
      NewBonus
      NewPoint
      NewFire
    in
      {RemoveAllFire Fire}

      Actions = {GetActions}

      {TickBombs Boxes Bonus Bombs Points Walls NewBoxes NewBonus MidBombs MidPoints NewFire}

      if Input.isTurnByTurn then
        {Delay Input.ThinkMin}
      else
        {WaitList Actions}
      end

      NewData = {PlayerActions PlayerData Actions MidBonus MidBombs MidPoints NewBonus NewBombs NewPoints NewFire}

      %% Check If Games Continues

      {GameLoop NewData NewBoxes NewBonus NewPoint NewFire}
    end
  in
    {GameLoop Data Boxes Bombs nil nil nil}
  end


  %%%%% Do Stuff

  {SendGui buildWindow}

  Players = {InitPlayers}
  PortPlayers = {GeneratePlayers}
  Spawns = {SpawnPlayers}
  PlayersData = {DataPlayers}

  Boxes = {Flatten {FindMap 2}|{FindMap 3}}
  Walls = {FindMap 1}

  {Game}
end
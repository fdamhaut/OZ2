functor
import
  GUI
  Input
  Browser
  PlayerManager
  OS
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
  PosEqual

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
  Respawn
  BEqual

  DestroyBox
  ExplodeBomb
  PlayerActions
  TickBombs
  RecuperateBombs

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

  TickingBomb
  TimeByTick
in

  %%%%% UTILS : Communication

  PortGUI = {GUI.portWindow}

  proc{SendGui Msg}
    {Send PortGUI Msg}
  end

  proc{SendMult Ports Msg}
    case Ports of H|T then
      {Send H Msg}
      {SendMult T Msg}
    else
      skip
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
    else
      skip
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
          {Pos T Y X+1 Acc}
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
        ( (Y1 == Y2+1) orelse (Y1 == Y2-1) ) %%% ERROR 
      elseif Y1 == Y2 then
        ( (X1 == X2+1) orelse (X1 == X2-1) ) %%% ERROR
      else
        false
      end
    else
      false
    end
  end

  fun{PosEqual Pos1 Pos2}
    case Pos1#Pos2 of pt(x:X1 y:Y1)#pt(x:X2 y:Y2) then
      X1 == X2 andthen Y1 == Y2
    else
      false
    end
  end

  %%%%% UTILS : MapEvents & Mandatory Messages to Players

  proc{RemoveAllFire Pos}
    case Pos of H|T then
      {SendGui hideFire(Pos)}
      {RemoveAllFire T}
    else
      skip
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

  proc{Die Port}
    ID
    Res
  in
    {Send Port gotHit(ID Res)}
    {SendPlayers info(deadPlayer(ID))}
  end


  %%%%% UTILS : Players

  fun{InitPlayers}
    fun{InitPlayer ID Colors}
      Bomber
    in
      case Colors of HColors|TColors then
        Bomber = bomber(id:ID color:HColors name:ID)
        {SendGui initPlayer(Bomber)}
        Bomber|{InitPlayer ID+1 TColors}
      else
        nil
      end
    end
  in
    {InitPlayer 1 Input.colorsBombers}
  end

  fun{GeneratePlayers}
    fun{GeneratePlayer Types Bombers}
      case Types#Bombers of (HTypes|TTypes)#(HBombers|TBombers) then
        {PlayerManager.playerGenerator HTypes HBombers}|{GeneratePlayer TTypes TBombers}
      else
        nil
      end
    end
  in
    {GeneratePlayer Input.bombers Players}
  end

  fun{SpawnPlayers}
    proc{SpawnPlayer Bombers Ports Spawns}
      ID
      Pos
    in
      case Bombers#Ports#Spawns of (HB|TB)#(HP|TP)#(HS|TS) then
        {SendGui spawnPlayer(HB HS)}
        {Send HP assignSpawn(HS)}
        {Send HP spawn(ID Pos)}
        {SendPlayers info(spawnPlayer(HB HS))}
        {SpawnPlayer TB TP TS}
      else
        skip
      end
    end
    Spawns
  in
    Spawns = {FindMap 4}
    {SpawnPlayer Players PortPlayers Spawns}
    Spawns
  end

  fun{DataPlayers}
    fun{DataPlayer Bombers Spawns Ports}
      case Bombers#Spawns#Ports of (HBombers|TBombers)#(HS|TS)#(HP|TP) then
        bdata(id:HBombers life:Input.nbLives bombs:Input.nbBombs pos:HS spawn:HS score:0 port:HP)|{DataPlayer TBombers TS TP}
      else
        nil
      end
    end
  in
    {DataPlayer Players Spawns PortPlayers}
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
    {GetPlayerAction PortPlayers}
  end

  fun{BEqual B1 B2}
    case B1#B2 of bomber(id:ID1 color:HColors1 name:N1)#bomber(id:ID2 color:HColors2 name:N2) then
      ID1 == ID2
    else
      false
    end
  end


  %%%%% GameEvent

  proc{DestroyBox Pos Boxes Bonus Points NewBoxes NewBonus NewPoints}
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
        NewFire
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
      FireDist = Input.fire
      case Pos of pt(x:X y:Y) then
        Fire1 = {SpreadFire X Y 1 0 FireDist Boxes Bonus {ListRemove Pos Bombs} Points MidBoxes1 MidBonus1 MidBombs1 MidPoints1 nil}
        Fire2 = {SpreadFire X Y ~1 0 FireDist MidBoxes1 MidBonus1 MidBombs1 MidPoints1 MidBoxes2 MidBonus2 MidBombs2 MidPoints2 Fire1}
        Fire3 = {SpreadFire X Y 0 1 FireDist MidBoxes2 MidBonus2 MidBombs2 MidPoints2 MidBoxes3 MidBonus3 MidBombs3 MidPoints3 Fire2}
        {SpreadFire X Y 0 ~1 FireDist MidBoxes3 MidBonus3 MidBombs3 MidPoints3 NewBoxes NewBonus NewBombs NewPoints Fire3}
      end
    end
  end

  fun{PlayerActions PlayerData Actions Boxes Bonus Bombs Points RecupBombs NewBonus NewBombs NewPoints Fire NewRecupBombs}
    fun{PlayerAction PlayersData Actions Bonus Bombs Points RecupBombs}
      case PlayersData#Actions of (bdata(id:ID life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE port:PORT)|TData)#(Action|TAct) then
        if{Value.isDet Action} then
          case Action
          of move(Pos) then
            if {IsNear Pos POS} andthen ( ({List.member Pos Walls} orelse {List.member Pos Boxes} orelse {List.member Pos Bombs}) ) == false then
              if {List.member Pos Fire} then
                if LIFE > 1 then
                  {Die PORT}
                  {Respawn PORT}
                  bdata(id:ID life:LIFE-1 bombs:BOMBS pos:SPAWN spawn:SPAWN score:SCORE port:PORT)|{PlayerAction TData TAct Bonus Bombs Points RecupBombs}
                else
                  {Die PORT}
                  bdata(id:ID life:LIFE-1 bombs:BOMBS pos:SPAWN spawn:SPAWN score:SCORE port:PORT)|{PlayerAction TData TAct Bonus Bombs Points RecupBombs}
                end
              else
                {Move ID Pos}
                if {List.member Pos Points} then
                  {SendGui scoreUpdate(ID SCORE+1)}
                  {Send PORT add(point 1)}
                  bdata(id:ID life:LIFE bombs:BOMBS pos:Pos spawn:SPAWN score:SCORE+1 port:PORT)|{PlayerAction TData TAct Bonus Bombs {ListRemove Points Pos} RecupBombs}
                elseif {List.member Pos Bonus} then
                  if ({OS.rand} mod 2) == 0 then
                    {Send PORT add(bomb 1)}
                    bdata(id:ID life:LIFE bombs:BOMBS+1 pos:Pos spawn:SPAWN score:SCORE port:PORT)|{PlayerAction TData TAct {ListRemove Bonus Pos} Bombs Points RecupBombs}
                  else
                    {Send PORT add(point 10)}
                    bdata(id:ID life:LIFE bombs:BOMBS pos:Pos spawn:SPAWN score:SCORE+10 port:PORT)|{PlayerAction TData TAct {ListRemove Bonus Pos} Bombs Points RecupBombs}
                  end
                else
                  bdata(id:ID life:LIFE bombs:BOMBS pos:Pos spawn:SPAWN score:SCORE port:PORT)|{PlayerAction TData TAct Bonus Bombs Points RecupBombs}
                end
              end
            else
              bdata(id:ID life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE port:PORT)|{PlayerAction TData TAct Bonus Bombs Points RecupBombs}
            end
          [] bomb(Pos) then
            {Browser.browse Pos#POS}
            if Pos == POS andthen BOMBS >= 1 then
              {PlaceBomb Pos}
              {Browser.browse 'BOOOOOOM'}
              bdata(id:ID life:LIFE bombs:BOMBS-1 pos:POS spawn:SPAWN score:SCORE port:PORT)|{PlayerAction TData TAct Bonus Pos#TickingBomb|Bombs Points (ID#TickingBomb)|RecupBombs}
            else
              bdata(id:ID life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE port:PORT)|{PlayerAction TData TAct Bonus Bombs Points RecupBombs}
            end
          else
            bdata(id:ID life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE port:PORT)|{PlayerAction TData TAct Bonus Bombs Points RecupBombs}
          end
        else
          bdata(id:ID life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE port:PORT)|{PlayerAction TData TAct Bonus Bombs Points RecupBombs}
        end
      else
        NewBombs = Bombs
        NewBonus = Bonus
        NewPoints = Points
        NewRecupBombs = RecupBombs
        nil
      end
    end
  in
    {PlayerAction PlayerData Actions Bonus Bombs Points RecupBombs}
  end


  proc{TickBombs Boxes Bonus Bombs Points Walls NewBoxes NewBonus NewBombs NewPoints NewFire}
    proc{TickBomb Boxes Bonus Bombs BombsLeft Points Walls Fire NewBoxes NewBonus NewBombs NewPoints NewFire}
      MidBoxes
      MidBombs
      MidPoints
      MidBonus
      MidFire 
    in
      case Bombs of (Pos#Time)|TBombs then
        if Time > TimeByTick then
          {TickBomb Boxes Bonus TBombs (Pos#(Time-TimeByTick))|BombsLeft Points Walls Fire NewBoxes NewBonus NewBombs NewPoints NewFire}
        else
          MidFire = {ExplodeBomb Pos {Flatten Bombs|Walls} Boxes Bonus BombsLeft Points MidBoxes MidBonus MidBombs MidPoints NewFire}
          {TickBomb MidBoxes MidBonus TBombs MidBombs MidPoints Pos|Walls {Flatten MidFire|Fire} NewBoxes NewBonus NewBombs NewPoints NewFire}
        end
      else
        NewFire = Fire
        NewBoxes = Boxes
        NewBonus = Bonus
        NewPoints = Points
        NewBombs = Bombs
      end
    end
  in
    {TickBomb Boxes Bonus Bombs nil Points Walls nil NewBoxes NewBonus NewBombs NewPoints NewFire}
  end


  fun{RecuperateBombs Recup PlayersData NewData}
    fun{AddBomb ID PlayersData}
      case PlayersData of bdata(id:IDB life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE port:PORT)|TData then
        if {BEqual ID IDB} then
          bdata(id:IDB life:LIFE bombs:BOMBS+1 pos:POS spawn:SPAWN score:SCORE port:PORT)|TData
        else
          bdata(id:IDB life:LIFE bombs:BOMBS pos:POS spawn:SPAWN score:SCORE port:PORT)|{AddBomb ID TData}
        end
      else
        nil
      end
    end
  in
    case Recup of (ID#Timimg)|T then
      if Timimg > TimeByTick then
        (ID#(Timimg-TimeByTick))|{RecuperateBombs T PlayersData NewData}
      else
        {RecuperateBombs T {AddBomb ID PlayersData} NewData}
      end
    else
      NewData = PlayersData
    end
  end
  %%%%% GameLoop

  proc{Game}
    proc{GameLoop PlayersData Boxes Bonus Bombs Points Fire RecupBombs}
      Actions

      MidRecupBombs
      NewRecupBombs

      MidBombs
      MidPoints
      MidBonus
      MidData

      NewData
      NewPos
      NewBoxes
      NewBonus
      NewBombs
      NewPoints
      NewFire
    in
      {Browser.browse 'NewTurn'}
      
      {RemoveAllFire Fire}

      Actions = {GetActions}

      {TickBombs Boxes Bonus Bombs Points Walls NewBoxes MidBonus MidBombs MidPoints NewFire}

      MidRecupBombs = {RecuperateBombs RecupBombs PlayersData MidData}

      if Input.isTurnByTurn then
        {WaitList Actions}
      else
        {Delay Input.thinkMin}
      end

      {Browser.browse Actions}
      {Delay 5000}

      NewData = {PlayerActions MidData Actions NewBoxes MidBonus MidBombs MidPoints MidRecupBombs NewBonus NewBombs NewPoints NewFire NewRecupBombs}

      %% Check If Games Continues
      {Browser.browse 'EndTurn'}

      {GameLoop NewData NewBoxes NewBonus NewBombs NewPoints NewFire NewRecupBombs}
    end
  in
    {GameLoop PlayersData Boxes nil nil nil nil nil}
  end


  %%%%% Do Stuff

  {SendGui buildWindow}

  Players = {InitPlayers}
  PortPlayers = {GeneratePlayers}
  Spawns = {SpawnPlayers}
  PlayersData = {DataPlayers}

  Boxes = {Flatten {FindMap 2}|{FindMap 3}}
  Walls = {FindMap 1}

  if Input.isTurnByTurn then
    TickingBomb = Input.timingBomb
    TimeByTick = 1
  else
    TickingBomb = Input.timingBombMin
    TimeByTick = Input.thinkMin
  end

  {Game}
end
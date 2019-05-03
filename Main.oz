functor
import
  GUI
  Input
  Browser
  System
  PlayerManager
  OS
define
  % Procs & Fun

  SendGui
  SendMult
  SendPlayers

  WaitList
  WaitActions
  ListRemove
  ListRemoveB
  ListInB

  ReadMap
  FindMap
  IsNear

  RemoveAllFire
  PlaceBomb
  RemoveBomb
  Move
  RemoveBox
  Die
  Death
  DeathByFire

  InitPlayers
  GeneratePlayers
  SpawnPlayers
  GetActions
  Respawn
  GetPort
  GetWinner

  DestroyBox
  ExplodeBomb
  Simu
  Tbt
  TickBombs

  Game

  PlayerAction
  ActionUpdate

  ListRemoveID
  ListRemoveIDs 


  % Data

  PortPlayers
  PortGUI
  PortPlayersID

  ThisMap

  Players
  PortID
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

  proc{WaitActions List}
    case List of action(act:ACT id:_)|T then
      {Wait ACT}
      {WaitActions T}
    else
      skip
    end
  end

  fun{ListRemove List Rem}
    case List of H|T then
      if H == Rem then
        T
      else
        H|{ListRemove T Rem }
      end
    else
      nil
    end
  end

  fun{ListRemoveID List Rem}
    case List of (POS#ID)|T then
      if ID == Rem then
        T
      else
        (POS#ID)|{ListRemoveID T Rem }
      end
    else
      nil
    end
  end

  fun{ListRemoveIDs List Rem}
    case Rem of ID|T then
      {ListRemoveIDs {ListRemoveID List ID} T}
    else
      List
    end
  end

  fun{ListInB List Pos ID}
    case List of (P#_#BID)|T then
      if P == Pos then
        ID = BID
        true
      else
        {ListInB T Pos ID}
      end
    else
      false
    end
  end


  fun{ListRemoveB List Rem}
    case List of (H#Time#ID)|T then
      if H == Rem then
        T
      else
        (H#Time#ID)|{ListRemoveB T Rem}
      end
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

  %%%%% UTILS : MapEvents & Mandatory Messages to Players

  proc{RemoveAllFire Pos}
    case Pos of H|T then
      {SendGui hideFire(H)}
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
    NL
  in
    {Send Port gotHit(ID Res)}
    {WaitList [Res ID]}
    case Res of death(NL) then
      if NL > 0 then
        {Death ID NL}
        {Respawn Port}
      else
        {Death ID NL}
      end
    else
      {Death ID 0}
    end
  end

  proc{Death ID Life}
    {SendGui lifeUpdate(ID Life)}
    {SendPlayers info(deadPlayer(ID))}
    {SendGui hidePlayer(ID)}
  end

  proc{Respawn Port}
    ID
    Pos
  in
    {Send Port spawn(ID Pos)}
    {WaitList [ID Pos]}
    {SendGui spawnPlayer(ID Pos)}
    {SendGui movePlayer(ID Pos)}
    {SendPlayers info(spawnPlayer(ID Pos))}
  end

  fun{GetWinner Alive}
    fun{GetBestScore PortID Score BestID}
      Res
    in
      case PortID of (HP#ID)|T then
        {Send HP add(point 0 Res)}
        if Res > Score then
          {GetBestScore T Res ID}
        else
          {GetBestScore T Score BestID}
        end
      else
        BestID
      end
    end

    fun{GetAlive PortID}
      IDS
      S
    in
      case PortID of (HP#_)|T then
        {Send HP getState(IDS S)}
        if S == on then
          IDS
        else
          {GetAlive T}
        end
      else
        nil
      end
    end

    fun{GetBestAlive PortID Score BestID}
      IDS
      S
      Res
    in
      case PortID of (HP#_)|T then
        {Send HP getState(IDS S)}
        if S == on then
          {Send HP add(point 0 Res)}
          if Res > Score then
            {GetBestAlive T Res IDS}
          else
            {GetBestAlive T Score BestID}
          end
        else
          {GetBestAlive T Score BestID}
        end
      else
        BestID
      end
    end

  in
    if Input.useExtention == false then
      {GetBestScore PortPlayersID ~1 nil}
    elseif Alive == 0 then
      {GetBestScore PortPlayersID ~1 nil}
    elseif Alive == 1 then
      {GetAlive PortPlayersID}
    else
      {GetBestAlive PortPlayers ~1 nil}
    end
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

  fun{PortID}
    fun{PID Ports}
      ID
    in
      case Ports of HP|TP then
        {Send HP getId(ID)}
        {Wait ID}
        (HP#ID)|{PID TP}
      else
        nil
      end
    end
  in
    {PID PortPlayers}
  end

  fun{GetActions Alive}
    fun{GetPlayerAction PortPlayer AliveIn}
      IDS
      S
      ID
      Act
    in
      case PortPlayer of H|T then
        {Send H getState(IDS S)}
        if S == on then
          {Send H doaction(ID Act)}
          action(act:Act id:ID)|{GetPlayerAction T AliveIn+1}
        else
          {GetPlayerAction T AliveIn}
        end
      else
        Alive = AliveIn
      end
    end
  in
    {GetPlayerAction PortPlayers 0}
  end

  fun{ActionUpdate Alive Actions Dead NewDead}
    fun{ActionUpdateIn AliveIn ActionsIN Dead}
      Port
      IDS
      S
      NID
      NACT
      MidDead
    in
      case ActionsIN of action(act:ACT id:ID)|T then
        if {Value.isDet ACT} andthen {Value.isDet ID} then
          if {List.member ID Dead} then
            {Die {GetPort ID}}
            MidDead = {ListRemove Dead ID}
          else
            MidDead = Dead
          end
          Port = {GetPort ID}
          {Send Port getState(IDS S)}
          if S == on then
            {Send Port doaction(NID NACT)}
            action(act:NACT id:NID)|{ActionUpdateIn AliveIn+1 T MidDead}
          else
            {ActionUpdateIn AliveIn+1 T MidDead}
          end
        else
          action(act:ACT id:ID)|{ActionUpdateIn AliveIn+1 T Dead}
        end
      else
        Alive = AliveIn
        NewDead = Dead
        ActionsIN
      end
    end
  in
    if Actions == nil then 
      NewDead = nil
      {GetActions Alive}
    else
      {ActionUpdateIn 0 Actions Dead}
    end
  end

  fun{GetPort ID}
    fun{GetPortIN PID}
      case PID of (P#IDP)|TPID then
        if ID == IDP then
          P
        else
          {GetPortIN TPID}
        end
      else
        nil
      end
    end
  in
    {GetPortIN PortPlayersID}
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
        NewPoints = Points
        NewBoxes = {ListRemove Boxes Pos}
      end
    end
  end
      

  fun{ExplodeBomb Pos ID Walls Boxes Bonus Bombs Points NewBoxes NewBonus NewBombs NewPoints NewFire}
    fun{SpreadFire X Y DeltaX DeltaY Remaining Boxes Bonus Bombs Points NewBoxes NewBonus NewBombs NewPoints NewFire}
      IDS
    in
      if {List.member pt(x:X y:Y) Walls} then
        NewBoxes = Boxes
        NewBonus = Bonus
        NewBombs = Bombs
        NewPoints = Points
        NewFire
      elseif {List.member pt(x:X y:Y) Boxes} then
        {DestroyBox pt(x:X y:Y) Boxes Bonus Points NewBoxes NewBonus NewPoints}
        {SendGui spawnFire(pt(x:X y:Y))}
        NewBombs = Bombs
        pt(x:X y:Y)|NewFire
      elseif {ListInB Bombs pt(x:X y:Y) IDS} then
        {ExplodeBomb pt(x:X y:Y) IDS Pos|Walls Boxes Bonus {ListRemoveB Bombs Pos} Points NewBoxes NewBonus NewBombs NewPoints NewFire}
      elseif Remaining > 0 then
        {SendGui spawnFire(pt(x:X y:Y))}
        {SpreadFire X+DeltaX Y+DeltaY DeltaX DeltaY Remaining-1 Boxes Bonus Bombs Points NewBoxes NewBonus NewBombs NewPoints pt(x:X y:Y)|NewFire}
      else
        {SendGui spawnFire(pt(x:X y:Y))}
        NewBoxes = Boxes
        NewBonus = Bonus
        NewBombs = Bombs
        NewPoints = Points
        pt(x:X y:Y)|NewFire
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

    Res
  in
    FireDist = Input.fire
    case Pos of pt(x:X y:Y) then
      {Send {GetPort ID} add(bomb 1 Res)}
      {RemoveBomb Pos}
      {SendGui spawnFire(Pos)}
      Fire1 = {SpreadFire X+1 Y 1 0 FireDist-1 Boxes Bonus Bombs Points MidBoxes1 MidBonus1 MidBombs1 MidPoints1 Pos|NewFire}
      Fire2 = {SpreadFire X Y+1 0 1 FireDist-1 MidBoxes1 MidBonus1 MidBombs1 MidPoints1 MidBoxes2 MidBonus2 MidBombs2 MidPoints2 Fire1}
      Fire3 = {SpreadFire X Y-1 0 ~1 FireDist-1 MidBoxes2 MidBonus2 MidBombs2 MidPoints2 MidBoxes3 MidBonus3 MidBombs3 MidPoints3 Fire2}
      {SpreadFire X-1 Y ~1 0 FireDist-1 MidBoxes3 MidBonus3 MidBombs3 MidPoints3 NewBoxes NewBonus NewBombs NewPoints Fire3}
    else
      nil
    end
  end

  proc{PlayerAction Action Boxes Bonus Bombs Points PosPlayers NewBonus NewBombs NewPoints Fire NewPosPlayers}
    PORT
    POINTTOT
    BOMBSTOT
    IDS
  in
    case Action of action(act:Act id:ID) then
      if {Value.isDet Act} then
        PORT = {GetPort ID}
        case Act
        of move(Pos) then
          if ( ({List.member Pos Walls} orelse {List.member Pos Boxes} orelse {ListInB Bombs Pos IDS}) ) then
            skip
          elseif {List.member Pos Fire} then
            {Die PORT}
            NewPosPlayers = {ListRemoveID PosPlayers ID}
          else
            {Move ID Pos}
            NewPosPlayers = (Pos#ID)|{ListRemoveID PosPlayers ID}
            if {List.member Pos Points} then
              {SendGui hidePoint(Pos)}
              {Send PORT add(point 1 POINTTOT)}
              {Wait POINTTOT}
              {SendGui scoreUpdate(ID POINTTOT)}
              NewPoints = {ListRemove Points Pos}
            elseif {List.member Pos Bonus} then
              {SendGui hideBonus(Pos)}
              if ({OS.rand} mod 2) == 0 then
                {Send PORT add(bomb 1 BOMBSTOT)}
                NewBonus = {ListRemove Bonus Pos}
              else
                {Send PORT add(point 10 POINTTOT)}
                {Wait POINTTOT}
                {SendGui scoreUpdate(ID POINTTOT)}
                NewBonus = {ListRemove Bonus Pos}
              end
            end
          end
        [] bomb(Pos) then
          {PlaceBomb Pos}
          NewBombs = (Pos#TickingBomb#ID)|Bombs
        else
          skip
        end
      end
    end

    if {Value.isDet NewBombs} == false then
      NewBombs = Bombs
    end
    if {Value.isDet NewBonus} == false then
      NewBonus = Bonus
    end
    if {Value.isDet NewPoints} == false then
      NewPoints = Points
    end
    if {Value.isDet NewPosPlayers} == false then
      NewPosPlayers = PosPlayers
    end
  end

  proc{Simu Actions Boxes Bonus Bombs Points PosPlayers NewBonus NewBombs NewPoints Fire NewPosPlayers}
    MidBonus
    MidBombs
    MidPoints
    MidPosPlayers
  in
    case Actions of H|T then
      {PlayerAction H Boxes Bonus Bombs Points PosPlayers MidBonus MidBombs MidPoints Fire MidPosPlayers}
      {Simu T Boxes MidBonus MidBombs MidPoints MidPosPlayers NewBonus NewBombs NewPoints Fire NewPosPlayers}
    else
      NewPoints = Points
      NewBonus = Bonus
      NewBombs = Bombs
      NewPosPlayers = PosPlayers
    end
  end

  fun{Tbt PortPlayer Boxes Bonus Bombs Points NewBonus NewBombs NewPoints Fire Alive}
    MidBonus
    MidBombs
    MidPoints
    IDS
    S
    ID
    Act
    TRASH
  in
    case PortPlayer of HP|TP then
      {Send HP getState(IDS S)}
      if S == on then
        {Send HP doaction(ID Act)}
        {WaitList [ID Act]}
        {PlayerAction action(act:Act id:ID) Boxes Bonus Bombs Points nil MidBonus MidBombs MidPoints Fire TRASH}
        {Tbt TP Boxes MidBonus MidBombs MidPoints NewBonus NewBombs NewPoints Fire Alive+1}
      else
        {Tbt TP Boxes Bonus Bombs Points NewBonus NewBombs NewPoints Fire Alive}
      end
    else
      NewBonus = Bonus
      NewBombs = Bombs
      NewPoints = Points
      Alive
    end
  end

  fun{DeathByFire PosPlayers Fire Dead}
    case PosPlayers of (POS#ID)|T then
      if {List.member POS Fire} then
        ID|{DeathByFire T Fire Dead}
      else
        {DeathByFire T Fire Dead}
      end
    else
      Dead
    end
  end

  proc{TickBombs Boxes Bonus Bombs Points Walls NewBoxes NewBonus NewBombs NewPoints NewFire}
    proc{TickBomb Boxes Bonus Bombs BombsLeft Points Walls Fire NewBoxes NewBonus NewBombs NewPoints NewFire}
      MidBoxes
      MidBombs
      MidPoints
      MidBonus
      MidFire 
    in
      case Bombs of (Pos#Time#ID)|TBombs then
        if Time > TimeByTick andthen {List.member Pos Fire}== false then
          {TickBomb Boxes Bonus TBombs (Pos#(Time-TimeByTick)#ID)|BombsLeft Points Walls Fire NewBoxes NewBonus NewBombs NewPoints NewFire}
        else
          MidFire = {ExplodeBomb Pos ID {Flatten Bombs|Walls} Boxes Bonus BombsLeft Points MidBoxes MidBonus MidBombs MidPoints nil}
          {TickBomb MidBoxes MidBonus TBombs MidBombs MidPoints Pos|Walls {Flatten MidFire|Fire} NewBoxes NewBonus NewBombs NewPoints NewFire}
        end
      else
        NewFire = Fire
        NewBoxes = Boxes
        NewBonus = Bonus
        NewPoints = Points
        NewBombs = BombsLeft
      end
    end
  in
    {TickBomb Boxes Bonus Bombs nil Points Walls nil NewBoxes NewBonus NewBombs NewPoints NewFire}
  end


  %%%%% GameLoop

  proc{Game}
    proc{GameLoop Boxes Bonus Bombs Points Fire Actions Dead PosPlayers}
      Alive

      MidBombs
      MidPoints
      MidBonus

      NewBoxes
      NewBonus
      NewBombs
      NewPoints
      NewFire

      NewActions
      MidDead
      NewDead

      MidPosPlayers
      NewPosPlayers
    in
    
      {RemoveAllFire Fire}

      {TickBombs Boxes Bonus Bombs Points Walls NewBoxes MidBonus MidBombs MidPoints NewFire}

      if Input.isTurnByTurn then
        Alive = {Tbt PortPlayers NewBoxes MidBonus MidBombs MidPoints NewBonus NewBombs NewPoints NewFire 0}
        NewActions = nil
        NewPosPlayers = nil
        NewDead = nil
      else
        {Simu Actions NewBoxes MidBonus MidBombs MidPoints PosPlayers NewBonus NewBombs NewPoints NewFire MidPosPlayers}
        MidDead = {DeathByFire MidPosPlayers NewFire Dead}
        NewPosPlayers = {ListRemoveIDs MidPosPlayers MidDead}
        NewActions = {ActionUpdate Alive Actions MidDead NewDead}
        {Delay TimeByTick}
      end

      %% Check If Games Continues
      if Boxes == nil orelse Alive < 2 then
        {SendGui displayWinner({GetWinner Alive})}
      else
        {GameLoop NewBoxes NewBonus NewBombs NewPoints NewFire NewActions NewDead NewPosPlayers}
      end
    end
  in
    {GameLoop Boxes nil nil nil nil nil nil nil}
  end


  %%%%% Do Stuff

  {SendGui buildWindow}

  Players = {InitPlayers}
  PortPlayers = {GeneratePlayers}
  Spawns = {SpawnPlayers}
  PortPlayersID = {PortID}

  Boxes = {Flatten {FindMap 2}|{FindMap 3}}
  Walls = {FindMap 1}

  if Input.isTurnByTurn then
    TickingBomb = Input.timingBomb+1
    TimeByTick = 1
  else
    TimeByTick = 100
    TickingBomb = Input.timingBombMin + TimeByTick
  end

  {Game}
end
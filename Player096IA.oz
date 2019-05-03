functor
import
  Input
  Projet2019util
  GUI
  System
  OS
export
  portPlayer:StartPlayer
define   
  StartPlayer
  InitState
  AssignSpawn
  Spawn
  AddBomb
  AddPoint
  Move
  RemoveBP
  BoxRem
  AddLife
  Add
  Get
  TreatStream
  GetAction
  BombRadius
  DangerZone
  ReadMap
  ListRemove
  FindMap
  AddPos
  BFS
  Closest
  Safety

in
  fun{StartPlayer ID}
    Stream Port OutputStream State
  in
    thread
      OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
    end
    {NewPort Stream Port}
    thread
      State = {InitState ID}
      {TreatStream OutputStream State}
    end

    Port
  end

  fun{InitState ID}
    SPAWN
    POS
  in
    data(id:ID nextAct:nil nbombs:Input.nbBombs life:Input.nbLives score:0 pos:POS spawn:SPAWN walls:{FindMap 1} boxes:{Flatten {FindMap 2}|{FindMap 3}} bonus:nil points:nil bombs:nil)
  end

  proc{AssignSpawn Data Spawn}
    Data.spawn = Spawn
  end

  fun{Spawn Data}
    {AdjoinAt Data pos Data.spawn}
  end

  fun{AddBomb Data N}
    {AdjoinAt Data nbombs Data.nbombs+N}
  end

  fun{AddPoint Data N}
    {AdjoinAt Data score Data.score+N}
  end

  fun{Move Data P}
    MidData1
  in
    MidData1 = {AdjoinAt Data pos P}
    {RemoveBP MidData1 P}
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

  fun{RemoveBP Data P}
    MidData1
  in 
    MidData1 = {AdjoinAt Data bonus {ListRemove Data.bonus P}}
    {AdjoinAt MidData1 points {ListRemove MidData1.points P}}
  end

  fun{BoxRem Data P}
    MidData1
  in 
    MidData1 = {AdjoinAt Data boxes {ListRemove Data.boxes P}}
    if {ReadMap P} == 2 then
      {AdjoinAt MidData1 points {Append [P] MidData1.points}}
    else
      {AdjoinAt MidData1 bonus {Append [P] MidData1.bonus}}
    end
  end

  fun{AddLife Data N}
    {AdjoinAt Data life Data.life+N}
  end

  fun{Add Data Type N}
    case Type
    of bomb then
      {AddBomb Data N}
    [] point then
      {AddPoint Data N}
    [] life then
      {AddLife Data N}
    else
      Data
    end
  end

  fun{Get Data Type}
    case Type
    of bomb then
      Data.nbombs
    [] point then
      Data.score
    [] life then
      Data.life
    else
      0
    end
  end


  proc{TreatStream Stream Data}
    NewData
  in
    case Stream
    of nil then
      skip
    [] getId(ID)|T then
      ID = Data.id
      {TreatStream T Data}
    [] getState(ID State)|T then
      ID = Data.id
      if Data.life > 0 then
        State = on
      else
        State = off
      end
      {TreatStream T Data}
    [] assignSpawn(Pos)|T then
      {AssignSpawn Data Pos}
      {TreatStream T Data}
    [] spawn(ID Pos)|T then
      NewData = {Spawn Data}
      ID = NewData.id
      Pos = NewData.pos
      {TreatStream T NewData}
    []add(Type Option Result)|T then
      NewData = {Add Data Type Option}
      Result = {Get NewData Type}
      {TreatStream T NewData}
    []gotHit(ID Result)|T then
      NewData = {Add Data life ~1}
      ID = NewData.id
      Result = death(NewData.life)
      {TreatStream T NewData}
    []doaction(ID Action)|T then
      NewData = {GetAction Data Action}
      ID = NewData.id
      {TreatStream T NewData}
    []info(Message)|T then
      case Message
      of movePlayer(ID Pos) then
        if ID == Data.id then
          NewData = {Move Data Pos}
        else
          NewData = {RemoveBP Data Pos}
        end
        {TreatStream T NewData}
      [] bombPlanted(Pos) then
        NewData = {AdjoinAt Data bombs {Append Data.bombs [Pos]}}
        {TreatStream T NewData}
      [] bombExploded(Pos) then
        NewData = {AdjoinAt Data bombs {ListRemove Data.bombs Pos}}
        {TreatStream T NewData}
      []boxRemoved(Pos) then
        NewData = {BoxRem Data Pos}
        {TreatStream T NewData}
      else
        {TreatStream T Data}
      end
    [] H|T then
      {TreatStream T Data}
    else 
      {TreatStream Stream Data}
    end
  end

  fun{GetAction Data Action}
    BPoints
    BBonus
    Mur
    DZone
    FD X Y
    NewData
  in
    if Input.isTurnByTurn == false then
      {Delay Input.thinkMin}
    end
    case Data.nextAct of H|T then 
      Action = move(H)
      {AdjoinAt Data nextAct T}
    else
      DZone = {DangerZone Data.bombs Data.walls Data.boxes}
      Mur = {Append Data.walls DZone}
      BBonus = {Closest Data.bonus Data.pos Mur}
      if BBonus \=nil then 
        Action = move(BBonus.1)
        Data
      
      else 
        BPoints = {Closest Data.points Data.pos Mur}
        if BPoints \= nil then
          Action = move(BPoints.1)
          Data

        else
          if Data.nbombs > 0 andthen {OS.rand} mod 3 < 2 then
            Action = bomb(Data.pos)
            NewData = {AdjoinAt Data nbombs Data.nbombs-1}
            {AdjoinAt NewData nextAct {Safety Data.pos {DangerZone {Append [Data.pos] Data.bombs} Data.walls Data.boxes} {Append Data.walls Data.boxes}}}
          else
            FD = {OS.rand} mod 4
            Data.pos = pt(x:X y:Y)

            if FD == 0 then
              Action = move(pt(x:X+1 y:Y))
            elseif FD == 1 then
              Action = move(pt(x:X-1 y:Y))
            elseif FD == 2 then
              Action = move(pt(x:X y:Y+1))
            else
              Action = move(pt(x:X y:Y-1))
            end
            Data
          end
        end
      end
    end
  end


  fun{BombRadius Pos Walls Boxes}
    fun{SpreadFire X Y DeltaX DeltaY Remaining NewFire}
      if {List.member pt(x:X y:Y) Walls} orelse {List.member pt(x:X y:Y) Boxes} then
        NewFire
      elseif Remaining > 0 then
        {SpreadFire X+DeltaX Y+DeltaY DeltaX DeltaY Remaining-1 pt(x:X y:Y)|NewFire}
      else
        pt(x:X y:Y)|NewFire
      end
    end
    Fire1
    Fire2
    Fire3

    FireDist

    Res
  in
    FireDist = Input.fire
    case Pos of pt(x:X y:Y) then
      Fire1 = {SpreadFire X+1 Y 1 0 FireDist-1 Pos|nil}
      Fire2 = {SpreadFire X Y+1 0 1 FireDist-1 Fire1}
      Fire3 = {SpreadFire X Y-1 0 ~1 FireDist-1 Fire2}
      {SpreadFire X-1 Y ~1 0 FireDist-1 Fire3}
    else
      nil
    end
  end

  fun{DangerZone Bombs Wall Boxes}
    case Bombs of H|T then
      {Append {BombRadius H Wall Boxes} {DangerZone T Wall Boxes}}
    else
      nil
    end
  end

  fun{ReadMap Pos}
    case Pos of pt(x:X y:Y) then
      {List.nth {List.nth Input.map Y} X}
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
    {Flatten {Line Input.map 1 nil}}
  end


  proc{AddPos A B Path Posi BoolMap NewPos NewMap}
    if {List.member pt(x:A y:B) BoolMap} then
      NewPos = Posi
      NewMap = BoolMap
    else
      NewPos = {Append Posi [v(x:A y:B path:Path)]}
      NewMap = {Append [pt(x:A y:B)] BoolMap}
    end
  end

  fun{BFS Start End Walls}
    StartX StartY EndX EndY
    fun{BFSIn Pos BoolMap EndX EndY}
      X Y Path
      MidPos1 MidPos2 MidPos3 MidPos4
      MidMap1 MidMap2 MidMap3 MidMap4
    in
      case Pos of H|T then
        X = H.x
        Y = H.y
        Path = {Append [pt(x:X y:Y)] H.path}
        if X == EndX andthen Y == EndY then
          {List.reverse Path}
        else
          {AddPos X+1 Y Path T BoolMap MidPos1 MidMap1}
          {AddPos X-1 Y Path MidPos1 MidMap1 MidPos2 MidMap2}
          {AddPos X Y+1 Path MidPos2 MidMap2 MidPos3 MidMap3}
          {AddPos X Y-1 Path MidPos3 MidMap3 MidPos4 MidMap4}
          {BFSIn MidPos4 MidMap4 EndX EndY}
        end
      else
        nil
      end
    end
  in
    Start = pt(x:StartX y:StartY)
    End = pt(x:EndX y:EndY)
    {BFSIn [v(x:StartX y:StartY path:nil)] Walls EndX EndY}
  end


  fun{Closest Items Pos Walls}
    Out
    fun{ClosestIn Items Long Best}
      B
    in

      case Items of H|T then
        B = {BFS Pos H Walls}
        if B == nil orelse {List.length B} >= Long then
          {ClosestIn T Long Best}
        else
          {ClosestIn T {List.length B} B}
        end
      else
        Best
      end
    end
  in

    Out = {ClosestIn Items 99 nil}
    case Out of H|T then
      T
    else
      Out
    end
  end

  fun{Safety Start Dangerzone Walls}
    StartX StartY
    fun{SafeIn Pos BoolMap}
      X Y Path Out
      MidPos1 MidPos2 MidPos3 MidPos4
      MidMap1 MidMap2 MidMap3 MidMap4
    in
      case Pos of H|T then
        X = H.x
        Y = H.y
        Path = {Append [pt(x:X y:Y)] H.path}
        if {List.member pt(x:X y:Y) Dangerzone} == false then
          Out = {List.reverse Path}
          case Out of H|T then
            T
          else
            Out
          end
        else
          {AddPos X+1 Y Path T BoolMap MidPos1 MidMap1}
          {AddPos X-1 Y Path MidPos1 MidMap1 MidPos2 MidMap2}
          {AddPos X Y+1 Path MidPos2 MidMap2 MidPos3 MidMap3}
          {AddPos X Y-1 Path MidPos3 MidMap3 MidPos4 MidMap4}
          {SafeIn MidPos4 MidMap4}
        end
      else
        nil
      end
    end
  in
    Start = pt(x:StartX y:StartY)
    {SafeIn [v(x:StartX y:StartY path:nil)] Walls}
  end

end
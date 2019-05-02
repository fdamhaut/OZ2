functor
import
  Input
  Projet2019util
export
  portPlayer:StartPlayer
define   
  StartPlayer
  TreatStream
  InitState
  UpdateState
  FindMap
  Walls

  RemoveList

  Name = 'AI'
  AssignSpawn
  Spawn
  GotHit
  AddBomb
  AddPoint
  SpawnPlayer
  MovePlayer
  DeadPlayer
  BombPlanted
  BombExploded
  BoxRemoved
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
    data(id:ID bombs:Input.nbBombs life:Input.nbLives score:0 pos:POS spawn:SPAWN)
  end

  proc{AssignSpawn Data Spawn}
    Data.spawn = Spawn
  end

  fun{Spawn Data}
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN)
      data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:SPAWN spawn:SPAWN)
    else
      Data
    end
  end

  fun{AddBomb Data N}
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN)
      data(id:ID bombs:BOMBS+N life:LIFE score:SCORE pos:POS spawn:SPAWN)
    else
      Data
    end
  end

  fun{AddPoint Data N}
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN)
      data(id:ID bombs:BOMBS life:LIFE score:SCORE+N pos:SPAWN spawn:SPAWN)
    else
      Data
    end
  end

  fun{Move Data P}
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN)
      data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:P spawn:SPAWN)
    else
      Data
    end
  end

  fun{AddLife N}
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN)
      data(id:ID bombs:BOMBS life:LIFE+N score:SCORE pos:POS spawn:SPAWN)
    else
      Data
    end
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
      Data.bombs
    [] point then
      Data.score
    [] life then
      Data.life
    else
      0
    end
  end


  fun{TreatStream Stream Data}
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
      if Data.life > 0
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
      Result = NewData.life
      {TreatStream T NewData}
    []doaction(ID Action)|T then
      NewData = {GetAction Data Action}
      ID = NewData.id
      {TreatStream T NewData}
    []info(Message)|T then
      case Message
      of MovePlayer(ID Pos) then
        if ID == Data.id then
          NewData = {Move Data Pos}
        else
          NewData = Data
        end
        {TreatStream T NewData}
      else
        {TreatStream T Data}
      end
    [] H|T then
      {TreatStream T NewData}
    else skip
    end
  end

  fun{GetAction Data Action}
    if Data.bombs > 0 andthen 
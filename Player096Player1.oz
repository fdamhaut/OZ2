functor
import
  Input
  Projet2019util
  GUI
  System
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
  AddLife
  Add
  Get
  TreatStream
  GetAction
  ResetStream

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
      {TreatStream OutputStream State GUI.entryStreamP1}
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
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN) then
      data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:SPAWN spawn:SPAWN)
    else
      Data
    end
  end

  fun{AddBomb Data N}
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN) then
      data(id:ID bombs:BOMBS+N life:LIFE score:SCORE pos:POS spawn:SPAWN)
    else
      Data
    end
  end

  fun{AddPoint Data N}
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN) then
      data(id:ID bombs:BOMBS life:LIFE score:SCORE+N pos:POS spawn:SPAWN)
    else
      Data
    end
  end

  fun{Move Data P}
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN) then
      data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:P spawn:SPAWN)
    else
      Data
    end
  end

  fun{AddLife Data N}
    case Data of data(id:ID bombs:BOMBS life:LIFE score:SCORE pos:POS spawn:SPAWN) then
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


  proc{TreatStream Stream Data EStream}
    NewData LeftStream
  in
    case Stream
    of nil then
      skip
    [] getId(ID)|T then
      ID = Data.id
      {TreatStream T Data EStream}
    [] getState(ID State)|T then
      ID = Data.id
      if Data.life > 0 then
        State = on
      else
        State = off
      end
      {TreatStream T Data EStream}
    [] assignSpawn(Pos)|T then
      {AssignSpawn Data Pos}
      {TreatStream T Data EStream}
    [] spawn(ID Pos)|T then
      NewData = {Spawn Data}
      ID = NewData.id
      Pos = NewData.pos
      {TreatStream T NewData EStream}
    []add(Type Option Result)|T then
      NewData = {Add Data Type Option}
      Result = {Get NewData Type}
      {TreatStream T NewData EStream}
    []gotHit(ID Result)|T then
      NewData = {Add Data life ~1}
      ID = NewData.id
      Result = death(NewData.life)
      {TreatStream T NewData EStream}
    []doaction(ID Action)|T then
      NewData = {GetAction Data Action EStream LeftStream}
      ID = NewData.id
      {TreatStream T NewData LeftStream}
    []info(Message)|T then
      case Message
      of movePlayer(ID Pos) then
        if ID == Data.id then
          NewData = {Move Data Pos}
        else
          NewData = Data
        end
        {TreatStream T NewData EStream}
      else
        {TreatStream T Data EStream}
      end
    [] H|T then
      {TreatStream T NewData EStream}
    else 
      {TreatStream Stream Data EStream}
    end
  end

  fun{GetAction Data Action EStream NewStream}
  BOMBS POS X Y
  UP DO LE RI BO
  in
    Data = data(id:_ bombs:BOMBS life:_ score:_ pos:POS spawn:_)
    POS = pt(x:X y:Y)
    UP = Input.player1KeyUp
    {System.show UP}
    DO = Input.player1KeyDown
    LE = Input.player1KeyLeft
    RI = Input.player1KeyRight
    BO = Input.player1KeyBomb
    case EStream 
    of nil then 
      nil
    [] key(KEY)|T then 
      if KEY == UP then
        {System.show 'P2GoUp'}
        Action = move(pt(x:X y:Y-1))
        NewStream = T
        Data
      elseif KEY == LE then 
      {System.show 'P2GoL'}
      Action = move(pt(x:X-1 y:Y))
      NewStream = T
      Data
      elseif KEY == DO then
      {System.show 'P2GoD'}
      Action = move(pt(x:X y:Y+1))
      NewStream = T
      Data
      elseif KEY == RI then
      {System.show 'P2GoR'}
      Action = move(pt(x:X+1 y:Y))
      NewStream = T
      Data
      elseif KEY == BO andthen BOMBS > 0 then
      {System.show 'P2BoomBot'}
      Action = bomb(POS)
      NewStream = T
      {AddBomb Data ~1}
      else
        {GetAction Data Action T NewStream}
      end
    [] H|T then
      {GetAction Data Action T NewStream}
    else
      nil
    end
  end

  fun{ResetStream Stream}
    case Stream of H|T then
      {ResetStream T}
    else
      Stream
    end
  end
end
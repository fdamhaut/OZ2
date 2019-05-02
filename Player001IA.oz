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
      state(id:ID maxBombs:Input.nbBombs activeBombs:0 score:0 life:Input.nbLives spawn:pt(x:0 y:0) boxList:{FindMap 2} bonusList:{FindMap 3} bomberPos:pos() bombList:nil)
   end

   fun{UpdateState State Field Param}
      {AdjoinAt State Field Param}
   end

   fun{RemoveList List Elem}
      case List of H|T then
	 if H == Elem then T
	 else
	    H|{RemoveList T Elem}
	 end
      [] nil then nil
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

   fun{AssignSpawn State Pos}
      {UpdateState State spawn Pos}
   end

   fun{Spawn State}
      {AdjoinAt State bomberPos {AdjoinAt State.bomberPos State.id.id spawn}}
   end

   fun{GotHit State NewLife}
      {UpdateState State life State.life-1}
   end

   fun{SpawnPlayer State ID Pos}
      {AdjoinAt State bomberPos {AdjoinAt State.bomberPos ID.id Pos}}
   end

   fun{MovePlayer State ID Pos}
      {AdjoinAt State bomberPos {AdjoinAt State.bomberPos ID.id Pos}}
   end

   fun{DeadPlayer State ID}
      State
   end

   fun{BombPlanted State Pos}
      {UpdateState State bombList {Append State.bombList Pos}}
   end

   fun{BombExploded State Pos}
      {UpdateState State bombList {RemoveList State.bombList Pos}}
   end

   fun{BoxRemoved State Pos}
      if {List.nth {List.nth Input.map Pos.y} Pos.x} == 2 then %box
	 {UpdateState State boxList {RemoveList State.boxList Pos}}
      else %bonus
	 {UpdateState State bonusList {RemoveList State.bonusList Pos}}
      end
   end

   fun{AddPoint State Option}
      {UpdateState State score State.score+Option}
   end

   fun{AddBomb State Option}
      {UpdateState State maxBombs State.maxBombs+Option}
   end


   
   proc{TreatStream Stream State}
      case Stream of nil then skip
      [] getId(?ID)|S then
	 ID = State.id
	 {TreatStream S State}
      [] getState(?ID ?RState)|S then
	 ID = State.id
	 if State.life > 0 then
	    RState = on
	 else
	    RState = off
	 end
	 {TreatStream S State}
      [] assignSpawn(Pos)|S then NewState in
	 NewState = {AssignSpawn State Pos}
	 {TreatStream S NewState}
      [] spawn(?ID ?Pos)|S then NewState in
	 if State.live > 0 then
	    ID = State.id
	    Pos = State.spawn
	    NewState = {Spawn State}
	    {TreatStream S NewState}
	 else
	    ID = null
	    Pos = null
	    {TreatStream S State}
	 end
      [] doaction(?ID ?Action)|S then
	 if State.live > 0 then
	    skip
	 else
	    ID = null
	    Action = null
	    {TreatStream S State}
	 end
      [] add(Type Option ?Return)|S then NewState in
	 case Type of bomb then
	    NewState = {AddBomb State Option}
	    Return = NewState.bombs
	 [] point then
	    NewState = {AddPoint State Option}
	    Return = NewState.score
	 end
	 {TreatStream S NewState}
      [] gotHit(?ID ?Result)|S then NewState in
	 if State.live > 0 then
	    ID = State.id
	    Result = State.life - 1
	    NewState = {GotHit State Result}
	    {TreatStream S NewState}
	 else
	    ID = null
	    Result = null
	    {TreatStream S State}
	 end
      [] info(spawnPlayer(ID Pos))|S then NewState in
	 NewState = {SpawnPlayer State ID Pos}
	 {TreatStream S NewState}
      [] info(movePlayer(ID Pos))|S then NewState in
	 NewState = {MovePlayer State ID Pos}
	 {TreatStream S NewState}
      [] info(deadPlayer(ID))|S then NewState in
	 NewState = {DeadPlayer State ID}
	 {TreatStream S NewState}
      [] info(bombPlanted(Pos))|S then NewState in
	 NewState = {BombPlanted State Pos}
	 {TreatStream S NewState}
      [] info(bombExploded(Pos))|S then NewState in
	 NewState = {BombExploded State Pos}
	 {TreatStream S NewState}
      [] info(boxRemoved(Pos))|S then NewState in
	 NewState = {BoxRemoved State Pos}
	 {TreatStream S NewState}
      else
	 skip
      end
   end

   Walls = {FindMap 1}
end

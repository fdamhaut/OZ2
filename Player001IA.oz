functor
import
   Input
   OS
   Projet2019util
export
   portPlayer:StartPlayer
define   
   StartPlayer
   TreatStream
   InitState
   UpdateState

   RemoveList
   IsTouch
   IsTouched
   EditMap


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
      state(id:ID maxBombs:Input.nbBombs activeBombs:0 score:0 life:Input.nbLives spawn:pt(x:0 y:0) map:Input.map bomberPos:pos() bombList:nil )
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

   fun{IsTouched State X Y MaxDist To ToRange PX PY}
      case To of H|T then
         case H of to(x:ToX y:ToY) then NewX NewY Status in
	         NewX = X+(ToX*ToRange)
	         NewY = Y+(ToY*ToRange)
            Status = {List.nth {List.nth State.map NewY} NewX}
	         if PX == NewX andthen PY==NewY then
	            true
	         elseif Status == 1 orelse Status == 2 orelse Status == 3 then
	            {IsTouched State X Y MaxDist T 1 PX PY}
	         elseif Status == 0 then
	            if ToRange<MaxDist then
	               {IsTouched State X Y MaxDist To ToRange+1 PX PY}
	            else
	               {IsTouched State X Y MaxDist T 1 PX PY}
	            end
	         end
         end
      [] nil then false
      end
   end
   fun{IsTouch State Pos Bomb}
      case Pos of pt(x:X y:Y) then
         case Bomb of pt(x:BX y:BY)|T then Test in
	         Test = {IsTouched State BX BY Input.fire [to(x:1 y:0) to(x:0 y:1) to(x:~1 y:0) to(x:0 y:~1)] 1 X Y}
	         if Test then true
	         else
	            {IsTouch State Pos T}
	         end
         []nil then false
         end
      end
   end

   fun{EditMap Map X Y New}
      SubList BigList in
      fun{SubList L X New}
         if X == 1 then
            New|L.2
        else
            L.1|{SubList L.2 X-1 New}
        end
      end
      fun{BigList L X Y New}
         if Y==1 then
            {SubList L.1 X New}|L.2
         else
            L.1|{BigList L.2 X Y-1 New}
         end
      end
      {BigList Map X Y New}
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
      {UpdateState State map {EditMap State.map Pos.x Pos.y 0}}
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
            if Input.isTurnByTurn then
               %Action = {FindAction}
               ID = State.id
               %{TreatStream S NewState}
            else X in 
               thread {Delay {OS.rand} mod(Input.thinkMax - Input.thinkMin) + Input.thinkMin}
                  X = 1
               end
               thread 
                  %{FindAction}
                  {Wait X}
                  %Action = {FindAction}
                  ID = State.id
               end
               %{TreatStream S NewState}
            end
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
         case Stream of H|T then
            {TreatStream T State}
         [] nil then skip
         end
      end
   end
end

functor
import
   Input
   OS
   Projet2019util
   System
export
   portPlayer:StartPlayer
define   
   StartPlayer
   TreatStream
   InitState
   UpdateState
   PossibleMove

   RemoveList
   FindAction
   FindMap


   Name = 'Random'
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
      state(id:ID maxBombs:Input.nbBombs score:0 life:Input.nbLives mypos:pt(x:0 y:0) spawn:pt(x:0 y:0) wallList:{Flatten {Flatten {FindMap 2}|{FindMap 3}}|{FindMap 1}})
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
      {UpdateState State mypos State.spawn}
   end

   fun{GotHit State NewLife}
      {UpdateState State life State.life-1}
   end

   fun{SpawnPlayer State ID Pos}
      {AdjoinAt State mypos {AdjoinAt State.mypos ID.id Pos}}
   end

   fun{MovePlayer State ID Pos}
      {AdjoinAt State mypos {AdjoinAt State.mypos ID.id Pos}}
   end

   fun{DeadPlayer State ID}
      State
   end

   fun{BombPlanted State Pos}
      {UpdateState State bombList {Append State.bombList Pos}}
   end

   fun{BombExploded State Pos}
      {UpdateState State wallList {RemoveList State.bombList Pos}}
   end

   fun{BoxRemoved State Pos}
      {UpdateState State wallList {RemoveList State.wallList Pos}}
   end

   fun{AddPoint State Option}
      {UpdateState State score State.score+Option}
   end

   fun{AddBomb State Option}
      {UpdateState State maxBombs State.maxBombs+Option}
   end

   fun{PossibleMove State Pos To}
        case To of H|T then
            case H of to(x:X y:Y) then NewX NewY in
                NewX = Pos.x + X
                NewY = Pos.y + Y
                if{List.member pt(x:NewX y:NewY) State.wallList } then
                    {PossibleMove State Pos T}
                else
                    move(pt(x:NewX y:NewY))|{PossibleMove State Pos T}
                end
            end
        [] nil then nil
        end
    end

    fun{FindAction State NewState} Choice Move in
        Choice = {OS.rand} mod 10
        if Choice < 8 orelse State.maxBombs == 0 then NChoice Action Nposs in 
            Move = {PossibleMove State State.mypos [to(x:1 y:0) to(x:0 y:1) to(x:~1 y:0) to(x:0 y:~1)]}
            Nposs = {OS.rand} mod {List.length Move}
            Action = {List.nth Move Nposs+1}
            NewState = {UpdateState State mypos pt(x:Action.1.x y:Action.1.y)}
            Action
        else Action in %Bomb
            NewState = {UpdateState State maxBombs State.maxBombs-1}
            bomb(pt(x:State.mypos.x y:State.mypos.y))
        end
    end


   proc{TreatStream Stream State}
      case Stream of nil then skip
      [] getId(ID)|S then
	      ID = State.id
	      {TreatStream S State}
      [] getState(ID RState)|S then
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
      [] spawn(ID Pos)|S then
	      if State.life > 0 then NewState in
	         ID = State.id
	         Pos = State.spawn
	         NewState = {Spawn State}
	         {TreatStream S NewState}
	      else
	         ID = null
	         Pos = null
	         {TreatStream S State}
	      end
      [] doaction(ID Action)|S then
	      if State.life > 0 then
            if Input.isTurnByTurn then NewState in 
                Action = {FindAction State NewState}
                ID = State.id
                {TreatStream S NewState}
            else X NewState in
               thread {Delay {OS.rand} mod(Input.thinkMax - Input.thinkMin) + Input.thinkMin}
                  X = 1
               end
               thread
                  Action = {FindAction State NewState}
                  {Wait X}
                  ID = State.id
               end
               {TreatStream S NewState}
            end
	      else
	         ID = null
	         Action = null
	         {TreatStream S State}
	      end
      [] add(Type Option Return)|S then NewState in
	      case Type of bomb then
	         NewState = {AddBomb State Option}
	         Return = NewState.maxBombs
	      [] point then
	         NewState = {AddPoint State Option}
	         Return = NewState.score
	      end
	      {TreatStream S NewState}
      [] gotHit(ID Result)|S then NewState in
	      if State.life > 0 then
	         ID = State.id
	         Result = death(State.life - 1)
	         NewState = {GotHit State Result}
	         {TreatStream S NewState}
	      else
	         ID = null
	         Result = null
	         {TreatStream S State}
	      end
      [] info(spawnPlayer(ID Pos))|S then
	      {TreatStream S State}
      [] info(movePlayer(ID Pos))|S then
	      {TreatStream S State}
      [] info(deadPlayer(ID))|S then
	      {TreatStream S State}
      [] info(bombPlanted(Pos))|S then
	      {TreatStream S State}
      [] info(bombExploded(Pos))|S then
	      {TreatStream S State}
      [] info(boxRemoved(Pos))|S then NewState in
	      NewState = {BoxRemoved State Pos}
	      {TreatStream S NewState}
      [] H|T then
         {TreatStream T State}
      else
         {TreatStream Stream State}
      end
   end
end

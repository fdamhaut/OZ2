functor
import
   Input
   Browser
   Projet2019util
export
   portPlayer:StartPlayer
define   
   StartPlayer
   TreatStream
   Name = 'AI'
   AssignSpawn
   Spawn
   GotHit
   SpawnPlayer
   MovePlayer
   DeadPlayer
   BombPlanted
   BombExploded
   BoxRemoved
in
   fun{StartPlayer ID}
      Stream Port OutputStream
   in
      thread %% filter to test validity of message sent to the player
         OutputStream = {Projet2019util.portPlayerChecker Name ID Stream}
      end
      {NewPort Stream Port}
      thread
	     {TreatStream OutputStream}
      end
      Port
   end

   fun{AssignSpawn State Pos}
      State
   end

   fun{Spawn State}
      State
   end

   fun{GotHit State NewLife}
      State
   end

   fun{SpawnPlayer State ID Pos}
      State
   end

   fun{MovePlayer State ID Pos}
      State
   end

   fun{DeadPlayer State ID}
      State
   end

   fun{BombPlanted State Pos}
      State
   end

   fun{BombExploded State Pos}
      State
   end

   fun{BoxRemoved State Pos}
      State
   end

   
   proc{TreatStream Stream State}
      case Stream
      of nil then skip
      [] getId(?ID)|S then
         ID = State.id
         {TreatStream S State}
      [] getState(?ID ?RState)|S then
         if State.live > 0 then
            RState = on
         else
            RState = off
         end
         {TreatStream S NewState}
      [] assignSpawn(Pos)|S then
         NewState = {AssignSpawn State Pos}
         {TreatStream S NewState}
      [] spawn(?ID ?Pos)|S then
         ID = State.id
         Pos = State.spawnPosition
         NewState = {Spawn State}
         {TreatStream S NewState}
      [] doaction(?ID ?Action)|S then
         skip
      [] add(Type Option)|S then
         skip
      [] gotHit(?ID ?Result)|S then
         ID = State.id
         NewLife = State.live - 1
         NewState = {GotHit State NewLife}
         {TreatStream S NewState}
      [] info(spawnPlayer(ID Pos))|S then
         NewState = {SpawnPlayer State ID Pos}
         {TreatStream S NewState}
      [] info(movePlayer(ID Pos))|S then
         NewState = {MovePlayer State ID Pos}
         {TreatStream S NewState}
      [] info(deadPlayer(ID))|S then
         NewState = {DeadPlayer State ID}
         {TreatStream S NewState}
      [] info(bombPlanted(Pos))|S then
         NewState = {BombPlanted State Pos}
         {TreatStream S NewState}
      [] info(bombExploded(Pos))|S then
         NewState = {BombExploded State Pos}
         {TreatStream S NewState}s
      [] info(boxRemoved(Pos))|S then
         NewState = {BoxRemoved State Pos}
         {TreatStream S NewState}
      else
         skip
      end
   end
   

end

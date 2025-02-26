functor
import
   Player000bomber
   Player096Player1
   Player096Player2
   Player096Rnd
   Player096IA
   Player096IAEvolved
   %% Add here the name of the functor of a player
   %% Player000name
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind ID}
      case Kind
      of player000bomber then {Player000bomber.portPlayer ID}
      %% Add here the pattern to recognize the name used in the 
      %% input file and launch the portPlayer function from the functor
      [] player096Player1 then {Player096Player1.portPlayer ID}
      [] player096Player2 then {Player096Player2.portPlayer ID}
      [] player096Rnd then {Player096Rnd.portPlayer ID}
      [] player096IA then {Player096IA.portPlayer ID}
      [] player096IAEvolved then {Player096IAEvolved.portPlayer ID}
      else
         raise 
            unknownedPlayer('Player not recognized by the PlayerManager '#Kind)
         end
      end
   end
end
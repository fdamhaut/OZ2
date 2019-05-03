# ----------------------------
# group nb XXX
# 3613-16-00 : LOUCHEUR BENOÎT
# 0045-16-00 : DAMHAUT FLORIAN
# ----------------------------

SRC = GUI.oz Main.oz Player096Player1.oz Player096Player2.oz Player096Rnd.oz PlayerManager.oz
PLAYER = Player096Player1.oz Player096Player2.oz Player096Rnd.oz
all :compile run

compile :
	@ozc -c $(SRC)

compilePlayer :
	@ozc -c $(PLAYER)
	
GUI.ozf:
	@ozc -c GUI.ozf

Input.ozf:
	@ozc -c Input.ozf
	
Main.ozf:
	@ozc -c Main.ozf
	
Player096Player1.ozf:
	@ozc -c Player096Player1.ozf

Player096Player2.ozf:
	@ozc -c Player096Player2.ozf
	
PlayerManager.ozf:
	@ozc -c PlayerManager.ozf
	
run :
	@ozengine Main.ozf

clean :
	@del -rf Input.ozf $(SRC)

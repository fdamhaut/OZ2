# ----------------------------
# group nb XXX
# 3613-16-00 : LOUCHEUR BENOÎT
# noma2 : DAMHAUT FLORIAN
# ----------------------------

all :compile start

compile :
	@ozc -c *.oz

compilePlayer :
	@ozc -c Player000name.ozf

Input:
	@ozc -c Input.oz
	
start :
	@ozengine Main.ozf

clean :
	@del -rf GUI.ozf Input.ozf Main.ozf PlayerManager.ozf Player000name.ozf

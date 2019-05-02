# ----------------------------
# group nb XXX
# 3613-16-00 : LOUCHEUR BENOÎT
# 0045-16-00 : DAMHAUT FLORIAN
# ----------------------------

all :compile run

compile :
	@ozc -c *.oz

compilePlayer :
	@ozc -c Player000name.ozf

Input:
	@ozc -c Input.oz
	
run :
	@ozengine Main.ozf

clean :
	@del -rf GUI.ozf Input.ozf Main.ozf PlayerManager.ozf Player000name.ozf

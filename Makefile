########################################################################
# Makefile for ID compiler improved
########################################################################

.PHONY: all
all: idc REPL.state
	chmod -R go+rX .

# generate saved state for Curry->FLVM compiler:
# idc: Compile.curry FlatCurry2AbstractHaskell.curry FlatCurry2Types.curry \
# 	         Names.curry AbstractHaskell.curry \
# 	         AbstractHaskellGoodies.curry AbstractHaskellPrinter.curry
idc: *.curry
	pakcs -s Compile && mv Compile.state idc

# generate saved state for REPL:
REPL.state: REPL.curry
	pakcs -s REPL

# install required cabal packages 
.PHONY: installhaskell
installhaskell:
	cabal install parallel
	cabal install tree-monad
	cabal install parallel-tree-search

.PHONY: clean
clean:
	cleancurry
	rm -f idc
	rm -f *.hi *.o
	rm -f lib/*.hi lib/*.o lib/*.nda lib/*.info lib/Curry_*.hs
	rm -f idsupply*/*.hi idsupply*/*.o
	rm -f ./examples/Curry_*.hs

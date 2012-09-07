# by convention, use this first.
all: lazyjson.o
	dmd  lazyjson.o

lazyjson.o: lazyjson.d
	dmd -c lazyjson.d






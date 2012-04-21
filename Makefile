DC = gdmd
DFLAGS = -O -release -inline
DREGSRC = dregs/core.d dregs/codetermine.d

all: test

test: test.d $(DREGSRC)
	$(DC) $(DFLAGS) -of$@ $^

.PHONY: clean

clean:
	rm -f test *.o

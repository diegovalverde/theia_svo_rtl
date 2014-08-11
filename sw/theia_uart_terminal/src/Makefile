CXX=g++
RM=rm -f
LDFLAGS=-g 
LDLIBS=-lreadline -lcurses
BINNAME=theia_term

SRCS=CDevice.cpp CDeviceManager.cpp main.cpp
OBJS=$(subst .cpp,.o,$(SRCS))

all: theia_term

theia_term: $(OBJS)
	    $(CXX) $(LDFLAGS) -o $(BINNAME) $(OBJS) $(LDLIBS) 


clean:
	$(RM) $(OBJS)

dist-clean: clean
	$(RM) $(BINNAME) 

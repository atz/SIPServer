#
# There's not a lot to "make", but this simplifies the usual
# sorts of tasks
#

all:
	@echo Nothing to make.  The command '"make run"' will run the server.

# just run the server from the command line
run: 
	perl SIPServer.pm SIPconfig.xml

tags:
	find . -name '*.pm' -print | etags -

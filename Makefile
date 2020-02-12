
ADA_COMPILER = gnatmake

all: leader_election.adb
	$(ADA_COMPILER) leader_election.adb -o LeaderElection

clean:
	rm *.ali *.o LeaderElection
	

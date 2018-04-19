#define N 4
bool leaderState[N];
byte order[N];
bool hasEnded = false;
chan pipes[N] = [1] of {byte};


//prop vars
byte leaderProcCount = 0;
byte leaderValues[N];
byte loopCount = 0;
byte computedLeader = 0;
byte computedMaximum = 0;
bool isMaximumCorrect = false;

init{
	int initState;
	for (initState : 0 .. N - 1){
		order[initState] = initState;
	}
   
	byte randNum;
	byte shuffle;
	byte randIndex;
	byte otherIndex;
	byte currentIndex = 0;
	
	select(randNum : 1 .. N);
	for (shuffle : 0 .. randNum){
		select(randIndex : 0 .. N - 1);
		select(otherIndex : 0 .. N - 1);
		// otherIndex = (randIndex == 0 ? N - 1 : randIndex - 1);
		byte tmp = order[randIndex];
		order[randIndex] = order[otherIndex];
		order[otherIndex] = tmp;
	}

	atomic{
		for (currentIndex : 0 .. N-1){
			//printf("RUN proc nb %d\n", order[currentIndex]);
			run dkrProc2(order[currentIndex]);
		}
	}

}

proctype dkrProc2(byte id){
	bool activeMode = true;
	byte leader = id;
	byte val;
	byte val1;
	byte val2;
	byte reciever;

	reciever = (id == 0 -> N - 1 : id - 1);
	//a
	petitA2:
	atomic{
		loopCount++;
		//printf("loop %d\n", loopCount);
	}

	val = leader;
	pipes[id] ! val;
	pipes[reciever] ? val1;
	if
	:: val == val1 ->
		leaderState[id] = true;
		//printf("proc %d is now leader\n", id);
		atomic{
			leaderProcCount++;
		}

	:: else ->
		//b
		pipes[id] ! val1;
		pipes[reciever] ? val2;
		if
		:: (val1 < val || val1 < val2) ->
			activeMode = false;
		:: else ->
			leader = val1;
			goto petitA2;
		fi
	fi

	leaderValues[id] = leader;
	if
	:: activeMode -> goto propCheck;
	:: else ->;
	fi

	//passive mode
	//printf("proc %d goes into passive mode\n", id);
	byte data;
	do
	:: !hasEnded && full(pipes[reciever]) ->
		pipes[reciever] ? data;
		pipes[id] ! data;
	:: hasEnded -> goto procEnd;
	od
	
	propCheck:
	//printf("Checking asserts\n");
	// 1. There is a leader one day
	//assert(leaderProcCount >= 1);

	// 2. There is not 2 leaders (a bit of tautology with 1)
	//assert(leaderProcCount < 2);

	// 3. Leader proc must have the maximum 'leader' value
	// byte otherIndex;
	// select(otherIndex : 0 .. N-1);
	// if
	// :: otherIndex != id ->
	// 	assert(leader >= leaderValues[otherIndex]);
	// :: else ->;
	// fi

	// // 4. Loop count (b->a) is capped at N + 1)
	// assert(loopCount <= N + 1);

	// printf("Nothing broke ?\n");
	hasEnded = true;
	procEnd:
	//printf("Proc %d terminated\n", id);
}

//propCheck but with LTL formulas
// 1. There is a leader one day
ltl prop1 { <> (leaderProcCount > 0)}

// 2. There is not 2 leaders (a bit of tautology with 1)
ltl prop2 { [] (leaderProcCount < 2)}

// 3. Leader proc must have the maximum 'leader' value
//???

// 4. Loop count (b->a) is capped at N + 1)
ltl prop4 { [] (loopCount <= N + 1)};


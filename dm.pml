#define N 5
bool activeState[N];

chan pipes[N] = [1] of {byte};


init{
    int initState;
    bool chosen[N];
    for (initState : 0 .. N - 1){
        activeState[initState] = true;
        chosen[initState] = false;
    }

    byte callOrder[N];
    byte currentIndex = 0;
    do
    ::  currentIndex == N -> break;
    ::  else -> byte try; select(try : 0 .. N-1);
                if
                :: !chosen[try] ->  callOrder[currentIndex] = try;
                                    chosen[try] = true;
                                    currentIndex = currentIndex + 1;
                                    printf("try = %d, currentIndex = %d\n", try, currentIndex);
                :: else ->
                fi
    od


    for (currentIndex : 0 .. N-1){
        printf("RUN\n");
        run dkrProc(callOrder[currentIndex]);
    }

}

proctype dkrProc(byte id){
    byte val;
    byte val1;
    byte val2;
    byte leader = id;
    val = id;

    // A
    petitA:
    pipes[id] ! val;
    byte reciever;
    if
    :: id == 0 -> reciever = N - 1;
    :: else -> reciever = id - 1;
    fi

    pipes[reciever] ? val1;
    if
    :: val == val1 -> activeState[id] = true;
    :: else ->
        //B
        pipes[id] ! val1;
        pipes[reciever] ? val2;
        if
        :: (val1 < val || val1 < val2) -> activeState[id] = false;
        :: else -> leader = val1; goto petitA;
        fi
    fi
    atomic{
        byte i = 0;
        byte j;
        for (j : 0 .. N - 1){
            if
            :: activeState[j] -> i = i + 1;
            :: else ->
            fi
        }

        //assert(i == 1);
    }
}
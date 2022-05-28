// Script to launch Kerbal X to Orbit of kerbin and circularize

function main {
    launch().
    ascent().
    until apoapsis > 80000 {
        AutoStage().
    }
}

function launch {
    // Set throttle to max and activate first stage
    print "Launching".
    lock throttle to 1.
    SafeStage.
}

function SafeStage {
    // Function to wait until stage ready before activating
    wait until stage:ready.
    stage.
    print "Stage " + stage:number.
}

function ascent { 
    // Set steering for gravity turn
    lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
    set targetDirection to 90.
    lock steering to heading(targetDirection, targetPitch).
}

function AutoStage {
    list engines in EngineList.
    for engine in EngineList {
        if engine:FLAMEOUT {
            SafeStage().
            wait 5.
        }    
        list engines in EngineList.
    }
}

// Perform launch
main().
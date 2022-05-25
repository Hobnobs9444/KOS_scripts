//Functional script to launch a Kerbal X

// Heavily plagirised from CheersKevin's excellent youtube tutorial 
// https://www.youtube.com/watch?v=1yS3BUxQ-VQ&list=RDCMUC-Fn23Q_91AEQHr2uNMd2VQ&index=2


function main {
  doLaunch().
  doAscent().
  until apoapsis >100000 {
    doAutoStage().
  }
  doShutdown().
  executeManeuver(time:seconds + 210, 0, 0, 480).
  print "Launch script complete".
}

function doLaunch {
  print "Launching".
  lock throttle to 1.
  doSafeStage().
}

function doAscent {
  lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
  set targetDirection to 90.
  lock steering to heading(targetDirection, targetPitch).
}

function doAutoStage {
  if not(defined oldThrust) {
    declare global oldThrust to ship:availablethrust.
  }
  if ship:availableThrust < (oldThrust - 10) {
    doSafeStage(). wait 1.
    declare global oldThrust to ship:availablethrust.
  }
}

function doShutdown {
  lock throttle to 0.
  lock steering to prograde.
  print "Shutdown".
}

function doSafeStage {
  wait until stage:ready.
  stage.
  print "Stage".
}

function executeManeuver {
  parameter utime, radial, normal, prog.
  print "Planning maneuver".
  local mnv is node(utime, radial, normal, prog).
  add mnv.
  local startTime is calculateStartTime(mnv).
  wait until time:seconds > startTime - 10.
  lockSteeringAtManeuverTarget(mnv).
  wait until time:seconds > startTime.
  lock throttle to 1.
  print "Burning".
  wait until isManeuverComplete(mnv).
  remove mnv.
  print "Burn complete, removing node".
}

function calculateStartTime {
  parameter mnv.
  return time:seconds + mnv:eta - (maneuverBurnTime(mnv) / 2).
}

function maneuverBurnTime {
  parameter mnv.
  return mnv:deltav:mag/(ship:maxthrust/ship:mass).
}

function lockSteeringAtManeuverTarget {
  parameter mnv.
  lock steering to mnv:burnvector.
}

function isManeuverComplete {
  parameter mnv.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vang(originalVector, mnv:burnvector) > 90 {
    declare global originalVector to -1.
    return True.
  }
}

// Initiate launch
main().
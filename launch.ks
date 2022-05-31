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
  doCircularization().
  print "Orbital insertion complete".
}

function doLaunch {
  print "Launching".
  lock throttle to 1.
  doSafeStage().
}

function doAscent {
  lock targetPitch to 0.0012 * alt:radar.
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
  print "Engine shutdown".
}

function doSafeStage {
  wait until stage:ready.
  stage.
  print "Staging".
}

function doCircularization {
  print "Computing optimal circularization maneuver".
  local circ is list(time:seconds +120, 0, 0, 0).
  until false {
    local oldScore is score(circ).
    set circ to improve(circ).
    if oldScore <= score(circ) {
      break.
    } 
  }
  print "Optimal circularization maneuver identified".
  executeManeuver(circ).
}

function score {
  parameter nd.
  local mnv is node(nd[0], nd[1], nd[2], nd[3]).
  add mnv.
  local result is mnv:orbit:eccentricity.
  remove mnv.
  return result.
}

function improve {
  parameter nd.
  local scoreToBeat is score(nd).
  local bestCandidate is nd.
  local candidates is list(
    list(nd[0] + 1, nd[1], nd[2], nd[3]),
    list(nd[0] - 1, nd[1], nd[2], nd[3]),
    list(nd[0], nd[1] + 1, nd[2], nd[3]),
    list(nd[0], nd[1] - 1, nd[2], nd[3]),
    list(nd[0], nd[1], nd[2] + 1, nd[3]),
    list(nd[0], nd[1], nd[2] - 1, nd[3]),
    list(nd[0], nd[1], nd[2], nd[3] + 1),
    list(nd[0], nd[1], nd[2], nd[3] - 1)
  ).
  for candidate in candidates {
    local candidateScore is score(candidate).
    if candidateScore < scoreToBeat {
      set scoreToBeat to candidateScore.
      set bestCandidate to candidate.
    }  
  }
  return bestCandidate.
}

function executeManeuver {
  parameter mList.
  local mnv is node(mList[0], mList[1], mList[2], mList[3]).
  add mnv.
  local startTime is calculateStartTime(mnv).
  wait until time:seconds > startTime - 30.
  lock steering to mnv:burnvector.
  print "Locking steering to burn vector".
  wait until time:seconds > startTime.
  lock throttle to 1.
  print "Burning".
  wait until isManeuverComplete(mnv).
  unlock steering.
  remove mnv.
}

function calculateStartTime {
  parameter mnv.
  return time:seconds + mnv:eta - (maneuverBurnTime(mnv) / 2).
}

function maneuverBurnTime {
  parameter mnv.

  local dV is mnv:deltav:mag.
  local g0 is 9.80665.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:ignition and not en:flameout {
      set isp to isp + (en:isp * (en:maxThrust / ship:maxThrust)).
    }
  }

  local massFinal is ship:mass / constant():e^(dV /(isp * g0)).
  local massFlowRate is ship:maxthrust / (isp * g0).
  local t is (ship:mass - massFinal)/massFlowRate.

  print "Burntime is " + t + "s".
  return t.
// return mnv:deltav:mag/(ship:maxthrust/ship:mass). // simplified calculation (works)
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
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
  // doTransfer().
  print "Orbital insertion complete".
  wait until false.
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
  print "Engine shutdown".
}

function doSafeStage {
  wait until stage:ready.
  stage.
  print "Staging".
}

function doCircularization {
  print "Computing optimal circularization maneuver".
  local circ is list(time:seconds + 30, 0).
  set circ to improveConverge(circ, eccentricityScore@).
  print "Optimal Circularization maneuver identified".
  executeManeuver(circ[0], 0, 0, circ[1]).
}

function doTransfer {
  print "Computing optimal transfer maneuver".
  local transfer is list(time:seconds +30, 0, 0, 0).
  set transfer to improveConverge(transfer, munTransferScore@).
  print "Optimal transfer maneuver identified".
  executeManeuver(transfer).
}

function eccentricityScore {
  parameter nd.
  local mnv is node(nd[0], 0, 0, nd[1]).
  add mnv.
  local result is mnv:orbit:eccentricity.
  remove mnv.
  return result.
}

function munTransferScore {
// TODO
}

function improveConverge {
  parameter nd, scoreFunction.
  for stepSize in list(100, 10, 1) {
    until false {
      local oldScore is scoreFunction(nd).
      set nd to improve(nd, stepSize, scoreFunction@).
      if oldScore <= scoreFunction(nd) {
        break.
      } 
    }
  }  
}


function improve {
  parameter nd, stepSize, scoreFunction. // nd is list(t, n, r, p)
  local scoreToBeat is scoreFunction(nd).
  local bestCandidate is nd.
  local candidates is list().
  local index is 0.
  until index >= nd:length {
    local incCandidate is nd:copy().
    local decCandidate is nd:copy().
    set incCandidate[index] to incCandidate[index] + stepSize.
    set decCandidate[index] to decCandidate[index] - stepSize.
    candidates:add(incCandidate).
    candidates:add(decCandidate).
    set index to index + 1.
  }
  //   list(nd[0] + 1, nd[1], nd[2], nd[3]),
  //   list(nd[0] - 1, nd[1], nd[2], nd[3]),
  //   list(nd[0], nd[1] + 1, nd[2], nd[3]),
  //   list(nd[0], nd[1] - 1, nd[2], nd[3]),
  //   list(nd[0], nd[1], nd[2] + 1, nd[3]),
  //   list(nd[0], nd[1], nd[2] - 1, nd[3]),
  //   list(nd[0], nd[1], nd[2], nd[3] + 1),
  //   list(nd[0], nd[1], nd[2], nd[3] - 1)
  // ).
  for candidate in candidates {
    local candidateScore is scoreFunction(candidate).
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
      set isp to isp + (en:isp * (en:availableThrust / ship:availableThrust)).
    }
  }

  local massFinal is ship:mass / constant():e^(dV /(isp * g0)).
  local massFlowRate is ship:availableThrust / (isp * g0).
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
#!/bin/bash
(trap '/usr/adaptive/kill_adaptive.sh' SIGINT; sudo rm -f /tmp/ama.log && sudo /usr/adaptive/startup.sh & sleep 10 && /usr/adaptive/kill_adaptive.sh & sleep 15 && sudo /usr/adaptive/startup.sh & sleep 20 && cd /usr/local/driveworks-5.10/apps/roadrunner-2.0/config && ./run.sh --product l2_4 --car sil-hyperion-81-m4-vehicle-two-time-multiplier --amend noUss.json,vehicle_two_223.app-config.json,vehicle_two_223_sim.app-config.json,bp_state_machine_sil.app-config.json,disableReactionToROI.app-config.json,imuGpsExternal.app-config.json,vioExternal.app-config.json,driverinteraction_enable.app-config.json,vioval_roadcast_enable.app-config.json,driverinteraction_roadcast_enable.app-config.json --time_multiplier --gui off --resolution 1920x1080 --rc2f  --disable_incident_ui --ds2_control 127.0.0.1:6666 & wait)

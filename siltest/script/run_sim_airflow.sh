#!/bin/bash

sp="/-\|"
i=1
ctrlc_count=0

touch /drivesim-ov/ds2_run.log
touch /drivesim-ov/scenario_run.log

chmod 755 /drivesim-ov/{ds2_run.log,scenario_run.log}

ds2_run_log="/drivesim-ov/ds2_run.log"
scenario_run_log="/drivesim-ov/scenario_run.log"


function define_exports {
    
    export DISPLAY=:1
    source /drivesim-ov/base.sh

    source /drivesim-ov/_build/linux-x86_64/release/setup_python_env.sh

    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/drivesim-ov/_build/linux-x86_64/release/exts/mercedes.vehicle_model.atgb/bin:/drivesim-ov/_build/linux-x86_64/release/exts/mercedes.vehicle_model.vehicle2/bin:/drivesim-ov/_build/linux-x86_64/release/exts/mercedes.osiprovider/bin:/drivesim-ov/_build/linux-x86_64/debug/exts/mercedes.osiprovider/bin:/drivesim-ov/SDK/source/extensions/mercedes.osiprovider/fmu/USV_SM_1.2.0:/opt/thirdparty/lib:/opt/thirdparty/lib/osi3:
    
    export GPU_CONFIG=" \
    --/renderer/multiGpu/enable=true \
    --/renderer/multiGpu/maxGpuCount=7 \
    --/renderer/rtx_context/activeDevices=\"0,1,2,3,4,5,6\" \
    "


    export DS_CONTROL=" \
    --/app/drivesim/control/port=6666 \
    --/app/drivesim/control/enabled=true \
    "
}


function wait_for_ds2_init {
    echo "Waiting for DS2 to initialize"
    echo "Reading $ds2_run_log to see drivesim status - waiting to start scenario"

    # Start Kit-Remote Viewer
    while true
    do
        if tail -n 500 $ds2_run_log | grep -q "ScenarioStateChange to eUninitialized broadcast completed"; then
            echo "Drivesim is ready to run scenarios. Starting the remote dekstop viewer."
            # pushd $kit_executable_folder
            # ./kit-remote --server 127.0.0.1 --width 1280 --height 720 &> /dev/null &
            # popd
            # TODO: Check if we really need sleep here
            sleep 10
            break
        fi
        printf "\b${sp:i++%${#sp}:1}"
        sleep 1
    done
}


##### Trap #####
trap trapint SIGINT SIGTERM
function trapint {
    let ctrlc_count++
    echo
    if [[ $ctrlc_count == 1 ]]; then
        echo "Press ctrl+c again to exit"
    else
        echo "Quitting..."
        pkill -9 kit
        pkill -9 testpgm
        copy_outputs
        exit
    fi
}


# Check for inputs
if [ $# -eq 0 ];
then
    echo "EBTB Scenario Parameter is missing. Exiting..."
    exit 5
fi

scenario=$1
echo "Got Scenario: $(basename $scenario)"

define_exports


# Start Drivesim e2e (kit)

sed -i "/mercedes.vehicle_model.*/d"  /drivesim-ov/_build/linux-x86_64/release/apps/omni.drivesim.simulation.kit
sed -i "/mercedes.osiprovider*/d"  /drivesim-ov/_build/linux-x86_64/release/apps/omni.drivesim.simulation.kit
sed -i "/mercedes.ebtb*/d"  /drivesim-ov/_build/linux-x86_64/release/apps/omni.drivesim.simulation.kit
sed -i "/omni.drivesim.sensors*/d"  /drivesim-ov/_build/linux-x86_64/release/apps/omni.drivesim.simulation.kit



#stdbuf -oL -eL /drivesim-ov/_build/linux-x86_64/release/omni.drivesim.e2e.sh \
#    --enable mercedes.service.set_initial_values \
#    --enable mercedes.restbus \
#    --enable mercedes.vehicle_model.atgb \
#    --enable mercedes.ebtb \
#     ${COMMON_DS2_ARGS} \
#     ${SIL3_ARGS} \
#     ${LIVESTREAM_ARGS} \
#     ${RECORDING} \
#     ${LOGGING}  \ 
#    ${DS_CONTROL} $@ \
#    > $ds2_run_log 2>&1 &



#/drivesim-ov/_build/linux-x86_64/release/omni.drivesim.e2e.sh \
#    --enable mercedes.service.set_initial_values \
#    --enable mercedes.restbus \
#    --enable mercedes.vehicle_model.atgb \
#    --enable mercedes.ebtb \
#     ${COMMON_DS2_ARGS} \
#     ${SIL3_ARGS} \
#     ${LIVESTREAM_ARGS} \
#     ${RECORDING} \ 
#     ${LOGGING} \
#     ${DS_CONTROL}   > $ds2_run_log 2>&1 &

stdbuf -oL -eL  /drivesim-ov/_build/linux-x86_64/release/omni.drivesim.e2e.sh --enable mercedes.osiprovider  --enable mercedes.service.set_initial_values --enable mercedes.restbus --enable mercedes.vehicle_model.atgb --enable mercedes.ebtb ${COMMON_DS2_ARGS} ${SIL3_ARGS} ${LIVESTREAM_ARGS} ${RECORDING} ${LOGGING} $@ --/app/drivesim/control/enabled=true --/app/drivesim/control/port=6666 > $ds2_run_log 2>&1 &
    

ds2_pid=$!
echo "Drivesim End to End Started with pid: $ds2_pid"
echo "Waiting for DS2 to initialize"


wait_for_ds2_init 

echo "Starting scenario: $scenario on drivesim2..."
rm -f /dev/shm/adaptive_simtime
(trap 'kill 0' SIGINT;
stdbuf -oL -eL /opt/stf/bin/testpgm \
    --config /opt/stf/lib/libdsov_config3.so \
    --frametime 10 \
    -s $scenario >  $scenario_run_log & wait
)
testpgm_pid=$(pgrep testpgm)
echo "Testpgm Started with pid: $testpgm_pid"


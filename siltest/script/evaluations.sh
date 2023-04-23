#!/bin/bash



siltest_dir=$1   #/data/siltest
siltest_case_path=$2   #Val 	/drivesim-ov/testcase_assets/scenarios/autonomous_emergency_braking_aeb/aeb_china/ivista/aeb_ccrm_day_100_impact_70_gvt_20_3521574.xebtb

ncdPath=$3    # /data/siltest/cache/
rrLogPath=$4





#rrLogPath = "${siltest_dir}/rrLog"
#ncdPath   = "${siltest_dir}/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1"


siltest_case_evaluation=$(basename ${siltest_case_path} |cut -d "." -f 1)

evaluation_path=`echo "${siltest_dir}/digital-testing-product${siltest_case_path%/*}/${siltest_case_evaluation}" | sed 's#drivesim-ov\/##g' | sed 's#scenarios#evaluations#g'`


evaluation_vehicle_dimensions_json="${evaluation_path}/vehicle_dimensions.json"


evaluation_test_case_file="${evaluation_path}/${siltest_case_evaluation}.xedf"


siltest_case_evaluation_dir=${siltest_case_evaluation}_$(date "+%Y_%m_%d_%H%M%S")


if [ ! -d ${siltest_dir}/silEvaluationOutput/${siltest_case_evaluationi_dir} ];then 
	mkdir -p $siltest_dir/silEvaluationOutput/${siltest_case_evaluation_dir}
fi


if [ ! -d ${siltest_dir}/silEvaluationInput/${siltest_case_evaluation_dir} ];then
        mkdir -p $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}
fi


ncd_file=$(find ${ncdPath} -name "*ncd.csv") 
rodecast_file=$(find ${rrLogPath} -name "roadcast_*.log") 
osi_file=$(find ${ncdPath}/osi_recording -name "*.hdf5") 

[ -n "${ncd_file}" ] && cp  ${ncd_file} $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}/
[ -n "${osi_file}" ] && cp  ${osi_file} $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}/
[ -n "${rodecast_file}" ] && cp  ${rodecast_file}  $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}/
[ -n "${evaluation_vehicle_dimensions_json}" ] && cp  ${evaluation_vehicle_dimensions_json}  $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}/
[ -n "${evaluation_test_case_file}" ] && cp  ${evaluation_test_case_file}  $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}/

#echo $rodecast_file
#echo $osi_file

#echo $evaluation_vehicle_dimensions_json
#echo $evaluation_test_case_file



json_file_path=$(find $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}  -name "*.json")
xedf_file_path=$(find $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}  -name "*.xedf")
csv_file_path=$(find $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}  -name "*.csv")
log_file_path=$(find $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}  -name "*.log")
hdf5_file_path=$(find $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}  -name "*.hdf5")


json_file_name=${json_file_path##*/}
xedf_file_name=${xedf_file_path##*/}
csv_file_name=${csv_file_path##*/}
log_file_name=${log_file_path##*/}
hdf5_file_name=${hdf5_file_path##*/}


docker run  --rm \
       -v $siltest_dir/silEvaluationInput/${siltest_case_evaluation_dir}:/home/ubuntu \
       -v /tmp/:/tmp/ \
       artifact.swf.daimler.com/adasdai-docker/davt/davt:v0.40.0  pipenv run python ./davt.py  -d --app=DetestEval --eval-description-file /home/ubuntu/${xedf_file_name}  \
       --abd-config /home/ubuntu/${json_file_name}  \
       --input-can /home/ubuntu/${csv_file_name} \
       --input-rclog /home/ubuntu/${log_file_name} \
       --input-ecal /home/ubuntu/${hdf5_file_name} \
       --force --output-path  /tmp/${siltest_case_evaluation}

cp -r /tmp/${siltest_case_evaluation}  $siltest_dir/silEvaluationOutput/${siltest_case_evaluation_dir}/

rm -rf /tmp/${siltest_case_evaluation}

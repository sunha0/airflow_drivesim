#!/bin/bash

siltest_dir=$1
siltest_case_name=$2

ncdPath=$3
rrLogPath=$4


echo $siltest_dir 
echo $siltest_case_name
echo $ncdPath
echo $rrLogPath

siltest_case_dir=${siltest_case_name}_$(date "+%Y_%m_%d_%H%M%S")

if [ ! -d ${siltest_dir}/silBackup/siltest_case_dir ];then 
	mkdir -p $siltest_dir/silBackup/${siltest_case_dir}
fi


ncd_file=$(find ${ncdPath} -name "*ncd.csv") 
rodecast_file=$(find ${rrLogPath} -name "roadcast_*.log") 
osi_file=$(find ${ncdPath}/osi_recording -name "*.hdf5") 


[ -n "${ncd_file}" ] && cp -r ${ncd_file} $siltest_dir/silBackup/${siltest_case_dir}
[ -n "${osi_file}" ] && cp -r ${osi_file} $siltest_dir/silBackup/${siltest_case_dir}
#[ -n "${rodecast_file}" ] && cp -r ${rodecast_file} $siltest_dir/silBackup/${siltest_case_dir}
tar zcvf  $siltest_dir/silBackup/${siltest_case_dir}/rrLog.tar.gz  $rrLogPath



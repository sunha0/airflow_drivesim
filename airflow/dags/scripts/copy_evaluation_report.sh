#!/bin/bash
siltest_case_evaluation=$1
siltest_case_evaluation_dir=$2
sudo chmod -R 777 /tmp/${siltest_case_evaluation}
sudo chmod -R 777 /data/siltest/silEvaluationOutput/${siltest_case_evaluation_dir}
echo '--- ll ---'
ls -al /tmp/${siltest_case_evaluation}
echo '--- ll ---'

sudo cp -r /tmp/${siltest_case_evaluation} /data/siltest/silEvaluationOutput/${siltest_case_evaluation_dir}
echo "--- end end ---"


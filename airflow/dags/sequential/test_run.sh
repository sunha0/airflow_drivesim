#!/bin/bash

./sequential_ndas_drivesim.sh \
'/data/siltest' \
'10.229.2.105' \
'artifact.swf.daimler.com/adasndas-docker/sil3/r5_containers/ndas:ndas_22_11_4b' \
'artifact.swf.daimler.com/adasndas-docker/sil3/r5_containers/ds:ds13_r5_1_final' \
'/drivesim-ov/testcase_assets/scenarios/blind_spot_monitoring_bsm/china_bsm_gbt/doubleside/bsd_50_double_gvt_overtaking_60_3623243.xebtb' \
'/data/airflow/dags/sequential'

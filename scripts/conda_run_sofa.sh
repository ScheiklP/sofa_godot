#!/bin/bash

sofa_run_binary=$1
sofa_scene=$2
log_dir=$3
#log_dir="/tmp/sofa_godot_out.txt"

#PYTHON_ROOT_DIR=$CONDA_PREFIX
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib

#sofa_python_3_plugin_path="$FOLDER_TARGET/install/plugins/SofaPython3/lib/libSofaPython3.so"
#$sofa_run_binary $sofa_scene -l "$sofa_python_3_plugin_path" > $log_dir

echo "SOFA log file: $log_dir"

$sofa_run_binary $sofa_scene > $log_dir




#!/bin/bash

# set up script constants
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRATCH_DIRECTORY="$( echo $PWD )"
JAVA_BIN=/opt/jre1.8.0_162/bin/java
LEGACY_CONVERTER_DIRECTORY=/data/ccms-massive/tools/MzTabConverter/2015.0309

# verify input file
if [ $# -ge 1 ]; then
    input=$1
    if [ ! -f "$input" ] && [ ! -r "$input" ]; then
        echo "ERROR: Argument input file [$input] is not a readable file."
        exit 1
    fi
else
    echo "ERROR: Please provide an input file."
    exit 1
fi

# verify output directory
if [ $# -ge 2 ]; then
    output=${2%/}
    if [ ! -d "$output" ]; then
        mkdir "$output"
    fi
else
    echo "ERROR: Please provide an output directory."
    exit 1
fi

# extract input file's base name and extension
filename="${input##*/}"
base="${filename%.*}"
extension="${filename##*.}"
# extract input file's collection directory
collection=`readlink -f $input | xargs -I {} dirname "{}"`
# extract input file's top-level task directory
task=`dirname "$collection"`
# trim paths from collection and task directories to get their flat names
collection="${collection##*/}"
task="${task##*/}"
# convert extension to lower case to allow case-insensitive comparison
lower_case_extension=`echo $extension | tr '[:upper:]' '[:lower:]'`
# if input file is an mzTab file, then just copy it to the output directory
if [ "$lower_case_extension" == "mztab" ]; then
    echo "Copying input file [$input] to output directory [$output]."
    cp "$input" "$output"
# if input file is an mzIdentML or PRIDE XML file, then convert before copying
elif [[ "$lower_case_extension" == "mzid" || "$lower_case_extension" == "xml" ]]; then
    # determine proper format for mzTab converter command line
    if [ "$lower_case_extension" == "mzid" ]; then
        format="MZIDENTML"
    elif [ "$lower_case_extension" == "xml" ]; then
        format="PRIDEXML"
    fi
    # copy input file to scratch space
    scratch_task=$SCRATCH_DIRECTORY/$task
    if [ ! -d "$scratch_task" ]; then
        mkdir "$scratch_task"
    fi
    scratch_collection=$scratch_task/$collection
    if [ ! -d "$scratch_collection" ]; then
        mkdir "$scratch_collection"
    fi
    scratch_input=$scratch_collection/$filename
    echo "Copying input file [$input] to scratch directory [$scratch_collection]."
    cp "$input" "$scratch_input"
    echo "Converting scratch input file [$scratch_input] to output mzTab file [$output/$base.mzTab]."
    command="$JAVA_BIN -Xmx8192M -cp $SCRIPT_DIRECTORY/MzTabConverter.jar edu.ucsd.mztab.ui.MzTabConverter -input \"$scratch_input\" -output \"$output/$base.mzTab\" -format $format"
    echo "Command: [$command]"
    $JAVA_BIN -Xmx8192M -cp $SCRIPT_DIRECTORY/MzTabConverter.jar edu.ucsd.mztab.ui.MzTabConverter -input "$scratch_input" -output "$output/$base.mzTab" -format $format
    status=$?
    # if the conversion failed, "fall back" to legacy converter
    if [ $status -ne 0 ]; then
        echo "Conversion failed with exit code $status, attempting to convert with legacy converter."
        command="$JAVA_BIN -jar $LEGACY_CONVERTER_DIRECTORY/mzTabCLI.jar -convert inFile=\"$scratch_input\" format=$format -outFile \"$output/$base.mzTab\""
        echo "Command: [$command]"
        $JAVA_BIN -jar $LEGACY_CONVERTER_DIRECTORY/mzTabCLI.jar -convert inFile="$scratch_input" format=$format -outFile "$output/$base.mzTab"
        status=$?
    fi
    # remove scratch input file
    echo "Deleting scratch input file [$scratch_input]."
    rm "$scratch_input"
    # if the conversion failed, pass that exit code
    if [ $status -ne 0 ]; then
        echo "Conversion failed: converter returned exit code $status"
        exit $status
    fi
# otherwise, input file is of an unsupported format, so fail
else
    echo "ERROR: Input file [$input] has unsupported format [.$extension]."
    exit 1
fi

exit

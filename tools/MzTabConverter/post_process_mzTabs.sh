#!/bin/bash

# set up script constants
MZTAB_UTILS_JAR=/data/beta-proteomics2/tools/MzTabUtils/2016.0517/MzTabUtils.jar
DEFAULT_VALIDATE_XMX="512m"
DEFAULT_CLEAN_XMX="512m"
DEFAULT_SUMMARIZE_XMX="1G"

# process and validate arguments
options=$(getopt -a -o "" -l validate_Xmx:,raw_mzTab_directory:,params:,validated_mzTab_directory:,mzTab_path:,peak_directory:,peak_path:,peak_collection:,scans_directory:,result_directory:,dataset:,validation_log:,invalid_threshold:,clean_Xmx:,cleaned_mzTab_directory:,pass_threshold:,decoy:,decoy_pattern:,psm_qvalue:,peptide_qvalue:,protein_qvalue:,psm_fdr:,peptide_fdr:,protein_fdr:,filter:,filter_type:,filter_fdr:,summarize_Xmx:,summary_file: -- "$@")
eval set -- "$options"
while true; do
    case "$1" in
    --validate_Xmx)
        shift;
        validate_Xmx=$1
        ;;
    --raw_mzTab_directory)
        shift;
        raw_mzTab_directory=$1
        ;;
    --params)
        shift;
        params_xml_file=$1
        ;;
    --validated_mzTab_directory)
        shift;
        validated_mzTab_directory=$1
        ;;
    --mzTab_path)
        shift;
        mzTab_path=$1
        ;;
    --peak_directory)
        shift;
        peak_directory=$1
        ;;
    --peak_path)
        shift;
        peak_path=$1
        ;;
    --peak_collection)
        shift;
        peak_collection=$1
        ;;
    --scans_directory)
        shift;
        scans_directory=$1
        ;;
    --result_directory)
        shift;
        result_directory=$1
        ;;
    --dataset)
        shift;
        dataset=$1
        ;;
    --validation_log)
        shift;
        validation_log=$1
        ;;
    --invalid_threshold)
        shift;
        invalid_threshold=$1
        ;;
    --clean_Xmx)
        shift;
        clean_Xmx=$1
        ;;
    --cleaned_mzTab_directory)
        shift;
        cleaned_mzTab_directory=$1
        ;;
    --pass_threshold)
        shift;
        pass_threshold=$1
        ;;
    --decoy)
        shift;
        decoy=$1
        ;;
    --decoy_pattern)
        shift;
        decoy_pattern=$1
        ;;
    --psm_qvalue)
        shift;
        psm_qvalue=$1
        ;;
    --peptide_qvalue)
        shift;
        peptide_qvalue=$1
        ;;
    --protein_qvalue)
        shift;
        protein_qvalue=$1
        ;;
    --psm_fdr)
        shift;
        psm_fdr=$1
        ;;
    --peptide_fdr)
        shift;
        peptide_fdr=$1
        ;;
    --protein_fdr)
        shift;
        protein_fdr=$1
        ;;
    --filter)
        shift;
        filter=$1
        ;;
    --filter_type)
        shift;
        filter_type=$1
        ;;
    --filter_fdr)
        shift;
        filter_fdr=$1
        ;;
    --summarize_Xmx)
        shift;
        summarize_Xmx=$1
        ;;
    --summary_file)
        shift;
        summary_file=$1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

# process required parameters
if [ -z "$params_xml_file" ]; then
    echo "Input params.xml file must be provided. (-params)"
    exit 1
elif [ ! -f "$params_xml_file" ]; then
    echo "Input params.xml file [$params_xml_file] must be a valid file. (-params)"
    exit 1
fi
if [ -z "$raw_mzTab_directory" ]; then
    echo "Input raw mzTab directory must be provided. (-raw_mzTab_directory)"
    exit 1
elif [ ! -d "$raw_mzTab_directory" ]; then
    echo "Input raw mzTab directory [$raw_mzTab_directory] must be a valid directory. (-raw_mzTab_directory)"
    exit 1
fi
if [ -z "$validated_mzTab_directory" ]; then
    echo "Output validated mzTab directory must be provided. (-validated_mzTab_directory)"
    exit 1
fi
if [ -z "$cleaned_mzTab_directory" ]; then
    echo "Output cleaned mzTab directory must be provided. (-cleaned_mzTab_directory)"
    exit 1
fi
if [ -z "$summary_file" ]; then
    echo "Output mzTab summary file must be provided. (-summary_file)"
    exit 1
fi

# process optional parameters
if [ -z "$validate_Xmx" ]; then
    validate_Xmx=$DEFAULT_VALIDATE_XMX
fi
if [ -z "$clean_Xmx" ]; then
    clean_Xmx=$DEFAULT_CLEAN_XMX
fi
if [ -z "$summarize_Xmx" ]; then
    summarize_Xmx=$DEFAULT_SUMMARIZE_XMX
fi

# ensure validated mzTab directory exists
if [ ! -d "$validated_mzTab_directory" ]; then
    mkdir -p "$validated_mzTab_directory"
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "validateMzTab directory mkdir command failed with exit code [$status]."
        exit $status
    fi
fi

# build extended validate mzTab parameter string
extended_parameters=""
if [ ! -z "$mzTab_path" ]; then
    extended_parameters="$extended_parameters -mztabPath '$mzTab_path'"
fi
if [ ! -z "$peak_directory" ]; then
    extended_parameters="$extended_parameters -peak '$peak_directory'"
fi
if [ ! -z "$peak_path" ]; then
    extended_parameters="$extended_parameters -peakPath '$peak_path'"
fi
if [ ! -z "$peak_collection" ]; then
    extended_parameters="$extended_parameters -peakCollection '$peak_collection'"
fi
if [ ! -z "$scans_directory" ]; then
    extended_parameters="$extended_parameters -scans '$scans_directory'"
fi
if [ ! -z "$result_directory" ]; then
    extended_parameters="$extended_parameters -result '$result_directory'"
fi
if [ ! -z "$dataset" ]; then
    extended_parameters="$extended_parameters -dataset '$dataset'"
fi
if [ ! -z "$validation_log" ]; then
    extended_parameters="$extended_parameters -log '$validation_log'"
fi
if [ ! -z "$invalid_threshold" ]; then
    extended_parameters="$extended_parameters -threshold '$invalid_threshold'"
fi

# validate mzTab
echo "----------"
command="java -Xmx$validate_Xmx -cp $MZTAB_UTILS_JAR edu.ucsd.mztab.ui.MzTabValidator -params '$params_xml_file' -mztab '$raw_mzTab_directory' -output '$validated_mzTab_directory'$extended_parameters"
echo "validateMzTab command: [$command]"
echo "----------"
eval $command
status=$?
if [ "$status" -ne 0 ]; then
    echo "validateMzTab command failed with exit code [$status]."
    exit $status
fi
echo ""

# ensure cleaned mzTab directory exists
if [ ! -d "$cleaned_mzTab_directory" ]; then
    mkdir -p "$cleaned_mzTab_directory"
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "cleanMzTab directory mkdir command failed with exit code [$status]."
        exit $status
    fi
fi

# build extended clean mzTab parameter string
extended_parameters=""
if [ ! -z "$mzTab_path" ]; then
    extended_parameters="$extended_parameters -mztabPath '$mzTab_path'"
fi
if [ ! -z "$peak_directory" ]; then
    extended_parameters="$extended_parameters -peak '$peak_directory'"
fi
if [ ! -z "$peak_path" ]; then
    extended_parameters="$extended_parameters -peakPath '$peak_path'"
fi
if [ ! -z "$peak_collection" ]; then
    extended_parameters="$extended_parameters -peakCollection '$peak_collection'"
fi
if [ ! -z "$dataset" ]; then
    extended_parameters="$extended_parameters -dataset '$dataset'"
fi
if [ ! -z "$pass_threshold" ]; then
    extended_parameters="$extended_parameters -passThreshold '$pass_threshold'"
fi
if [ ! -z "$decoy" ]; then
    extended_parameters="$extended_parameters -decoy '$decoy'"
fi
if [ ! -z "$decoy_pattern" ]; then
    extended_parameters="$extended_parameters -decoyPattern '$decoy_pattern'"
fi
if [ ! -z "$psm_qvalue" ]; then
    extended_parameters="$extended_parameters -psmQValue '$psm_qvalue'"
fi
if [ ! -z "$peptide_qvalue" ]; then
    extended_parameters="$extended_parameters -peptideQValue '$peptide_qvalue'"
fi
if [ ! -z "$protein_qvalue" ]; then
    extended_parameters="$extended_parameters -proteinQValue '$protein_qvalue'"
fi
if [ ! -z "$psm_fdr" ]; then
    extended_parameters="$extended_parameters -psmFDR '$psm_fdr'"
fi
if [ ! -z "$peptide_fdr" ]; then
    extended_parameters="$extended_parameters -peptideFDR '$peptide_fdr'"
fi
if [ ! -z "$protein_fdr" ]; then
    extended_parameters="$extended_parameters -proteinFDR '$protein_fdr'"
fi
if [ ! -z "$filter" ]; then
    extended_parameters="$extended_parameters -filter '$filter'"
fi
if [ ! -z "$filter_type" ]; then
    extended_parameters="$extended_parameters -filterType '$filter_type'"
fi
if [ ! -z "$filter_fdr" ]; then
    extended_parameters="$extended_parameters -filterFDR '$filter_fdr'"
fi

# clean mzTab
echo "----------"
command="java -Xmx$clean_Xmx -cp $MZTAB_UTILS_JAR edu.ucsd.mztab.ui.ProteoSAFeMzTabCleaner -params '$params_xml_file' -mztab '$validated_mzTab_directory' -output '$cleaned_mzTab_directory'$extended_parameters"
echo "cleanMzTab command: [$command]"
echo "----------"
eval $command
status=$?
if [ "$status" -ne 0 ]; then
    echo "cleanMzTab command failed with exit code [$status]."
    exit $status
fi
echo ""

# ensure summary file parent directory exists
summary_directory=$(dirname "$summary_file")
if [ ! -d "$summary_directory" ]; then
    mkdir -p "$summary_directory"
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "summarizeMzTab directory mkdir command failed with exit code [$status]."
        exit $status
    fi
fi

# build extended summarize mzTab parameter string
extended_parameters=""
if [ ! -z "$mzTab_path" ]; then
    extended_parameters="$extended_parameters -mztabPath '$mzTab_path'"
fi
if [ ! -z "$dataset" ]; then
    extended_parameters="$extended_parameters -dataset '$dataset'"
fi

# summarize mzTab
echo "----------"
command="java -Xmx$summarize_Xmx -cp $MZTAB_UTILS_JAR edu.ucsd.mztab.ui.MzTabCounter -params '$params_xml_file' -mztab '$cleaned_mzTab_directory' -output '$summary_file'$extended_parameters"
echo "summarizeMzTab command: [$command]"
echo "----------"
eval $command
status=$?
if [ "$status" -ne 0 ]; then
    echo "summarizeMzTab command failed with exit code [$status]."
    exit $status
fi
echo ""

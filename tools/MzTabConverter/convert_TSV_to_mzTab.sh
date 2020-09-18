#!/bin/bash

# set up script constants
MZTAB_UTILS_JAR=/data/beta-proteomics2/tools/MzTabUtils/2016.0517/MzTabUtils.jar
DEFAULT_CREATE_CONFIG_XMX="512m"
DEFAULT_CONVERT_XMX="2G"

# process and validate arguments
mod_patterns=()
fixed_mods=()
variable_mods=()
options=$(getopt -a -o "" -l config_Xmx:,tsv:,params:,config_directory:,header_line:,filename:,modified_sequence:,mod_pattern:,fixed_mod:,variable_mod:,fixed_mods_reported:,match_mass_precision:,match_mass_difference:,spectrum_id_type:,scan:,index:,index_numbering:,accession:,charge:,exp_mass_to_charge:,calc_mass_to_charge:,msgf_evalue:,msgf_spec_evalue:,msgf_qvalue:,msgf_pep_qvalue:,convert_Xmx:,raw_mzTab_directory:,skip: -- "$@")
eval set -- "$options"
while true; do
    case "$1" in
    --config_Xmx)
        shift;
        config_Xmx=$1
        ;;
    --tsv)
        shift;
        tsv_file=$1
        ;;
    --params)
        shift;
        params_xml_file=$1
        ;;
    --config_directory)
        shift;
        config_directory=$1
        ;;
    --header_line)
        shift;
        header_line=$1
        ;;
    --filename)
        shift;
        filename=$1
        ;;
    --modified_sequence)
        shift;
        modified_sequence=$1
        ;;
    --mod_pattern)
        shift;
        mod_patterns+=($1)
        ;;
    --fixed_mod)
        shift;
        fixed_mods+=($1)
        ;;
    --variable_mod)
        shift;
        variable_mods+=($1)
        ;;
    --fixed_mods_reported)
        shift;
        fixed_mods_reported=$1
        ;;
    --match_mass_precision)
        shift;
        match_mass_precision=$1
        ;;
    --match_mass_difference)
        shift;
        match_mass_difference=$1
        ;;
    --spectrum_id_type)
        shift;
        spectrum_id_type=$1
        ;;
    --scan)
        shift;
        scan=$1
        ;;
    --index)
        shift;
        index=$1
        ;;
    --index_numbering)
        shift;
        index_numbering=$1
        ;;
    --accession)
        shift;
        accession=$1
        ;;
    --charge)
        shift;
        charge=$1
        ;;
    --exp_mass_to_charge)
        shift;
        exp_mass_to_charge=$1
        ;;
    --calc_mass_to_charge)
        shift;
        calc_mass_to_charge=$1
        ;;
    --msgf_evalue)
        shift;
        msgf_evalue=$1
        ;;
    --msgf_spec_evalue)
        shift;
        msgf_spec_evalue=$1
        ;;
    --msgf_qvalue)
        shift;
        msgf_qvalue=$1
        ;;
    --msgf_pep_qvalue)
        shift;
        msgf_pep_qvalue=$1
        ;;
    --convert_Xmx)
        shift;
        convert_Xmx=$1
        ;;
    --raw_mzTab_directory)
        shift;
        raw_mzTab_directory=$1
        ;;
    --skip)
        shift;
        skip=$1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

# process required parameters
if [ -z "$tsv_file" ]; then
    echo "Input tab-delimited result file must be provided. (-tsv)"
    exit 1
elif [ ! -f "$tsv_file" ]; then
    echo "Input tab-delimited result file [$tsv_file] must be a valid file. (-tsv)"
    exit 1
fi
if [ -z "$params_xml_file" ]; then
    echo "Input params.xml file must be provided. (-params)"
    exit 1
elif [ ! -f "$params_xml_file" ]; then
    echo "Input params.xml file [$params_xml_file] must be a valid file. (-params)"
    exit 1
fi
if [ -z "$config_directory" ]; then
    echo "Output mzTab conversion parameter file directory must be provided. (-config_directory)"
    exit 1
fi
if [ -z "$header_line" ]; then
    echo "TSV file header line flag must be provided. (-header_line)"
    exit 1
fi
if [ -z "$filename" ]; then
    echo "TSV file filename column name or index must be provided. (-filename)"
    exit 1
fi
if [ -z "$modified_sequence" ]; then
    echo "TSV file modified peptide sequence column name or index must be provided. (-modified_sequence)"
    exit 1
fi
if [ "${#mod_patterns[@]}" -lt 1 ]; then
    echo "Please provide a modification pattern string. (-mod_pattern)"
    exit 1
fi
if [ -z "$raw_mzTab_directory" ]; then
    echo "Output raw mzTab directory must be provided. (-raw_mzTab_directory)"
    exit 1
fi

# process optional parameters
if [ -z "$config_Xmx" ]; then
    config_Xmx=$DEFAULT_CREATE_CONFIG_XMX
fi
if [ -z "$convert_Xmx" ]; then
    convert_Xmx=$DEFAULT_CONVERT_XMX
fi

# ensure conversion parameter file parent directory exists
if [ ! -d "$config_directory" ]; then
    mkdir -p "$config_directory"
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "createConvertConfig directory mkdir command failed with exit code [$status]."
        exit $status
    fi
fi

# set up output conversion parameter file
config_file_name=$(basename $tsv_file)
config_file_basename="${config_file_name%.*}"
config_file=$config_directory/$config_file_basename.properties

# build extended generate conversion parameter file parameter string
extended_parameters=""
for mod_pattern in "${mod_patterns[@]}"; do
    extended_parameters="$extended_parameters -mod_pattern '$mod_pattern'"
done
for fixed_mod in "${fixed_mods[@]}"; do
    extended_parameters="$extended_parameters -fixed_mod '$fixed_mod'"
done
for variable_mod in "${variable_mods[@]}"; do
    extended_parameters="$extended_parameters -variable_mod '$variable_mod'"
done
if [ ! -z "$fixed_mods_reported" ]; then
    extended_parameters="$extended_parameters -fixed_mods_reported '$fixed_mods_reported'"
fi
if [ ! -z "$match_mass_precision" ]; then
    extended_parameters="$extended_parameters -match_mass_precision '$match_mass_precision'"
fi
if [ ! -z "$match_mass_difference" ]; then
    extended_parameters="$extended_parameters -match_mass_difference '$match_mass_difference'"
fi
if [ ! -z "$spectrum_id_type" ]; then
    extended_parameters="$extended_parameters -spectrum_id_type '$spectrum_id_type'"
fi
if [ ! -z "$scan" ]; then
    extended_parameters="$extended_parameters -scan '$scan'"
fi
if [ ! -z "$index" ]; then
    extended_parameters="$extended_parameters -index '$index'"
fi
if [ ! -z "$index_numbering" ]; then
    extended_parameters="$extended_parameters -index_numbering '$index_numbering'"
fi
if [ ! -z "$accession" ]; then
    extended_parameters="$extended_parameters -accession '$accession'"
fi
if [ ! -z "$charge" ]; then
    extended_parameters="$extended_parameters -charge '$charge'"
fi
if [ ! -z "$exp_mass_to_charge" ]; then
    extended_parameters="$extended_parameters -exp_mass_to_charge '$exp_mass_to_charge'"
fi
if [ ! -z "$calc_mass_to_charge" ]; then
    extended_parameters="$extended_parameters -calc_mass_to_charge '$calc_mass_to_charge'"
fi
if [ ! -z "$msgf_evalue" ]; then
    extended_parameters="$extended_parameters -msgf_evalue '$msgf_evalue'"
fi
if [ ! -z "$msgf_spec_evalue" ]; then
    extended_parameters="$extended_parameters -msgf_spec_evalue '$msgf_spec_evalue'"
fi
if [ ! -z "$msgf_qvalue" ]; then
    extended_parameters="$extended_parameters -msgf_qvalue '$msgf_qvalue'"
fi
if [ ! -z "$msgf_pep_qvalue" ]; then
    extended_parameters="$extended_parameters -msgf_pep_qvalue '$msgf_pep_qvalue'"
fi

if [ "${skip:=0}" -ne 1 ]; then
  # generate conversion parameter file
  echo "----------"
  command="java -Xmx$config_Xmx -cp $MZTAB_UTILS_JAR edu.ucsd.mztab.TSVToMzTabParamGenerator -tsv '$tsv_file' -params '$params_xml_file' -output '$config_file' -header_line '$header_line' -filename '$filename' -modified_sequence '$modified_sequence'$extended_parameters"
  echo "createConvertConfig command: [$command]"
  echo "----------"
  eval $command
  status=$?
  if [ "$status" -ne 0 ]; then
      echo "createConvertConfig command failed with exit code [$status]."
      exit $status
  fi
  echo ""

  # ensure TSV to mzTab conversion directory exists
  if [ ! -d "$raw_mzTab_directory" ]; then
      mkdir -p "$raw_mzTab_directory"
      status=$?
      if [ "$status" -ne 0 ]; then
          echo "convertTSVToMzTab directory mkdir command failed with exit code [$status]."
          exit $status
      fi
  fi

  # convert TSV to mzTab
  echo "----------"
  command="java -Xmx$convert_Xmx -cp $MZTAB_UTILS_JAR edu.ucsd.mztab.TSVToMzTabConverter -tsv '$tsv_file' -params '$config_file' -mzTab '$raw_mzTab_directory'"
  echo "convertTSVToMzTab command: [$command]"
  echo "----------"
  eval $command
  status=$?
  if [ "$status" -ne 0 ]; then
      echo "convertTSVToMzTab command failed with exit code [$status]."
      exit $status
  fi
  echo ""
fi

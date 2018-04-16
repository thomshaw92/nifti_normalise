#!/bin/bash
#Normalises niifti volume between two PcTs
#Thomas Shaw
#thomasbasilshaw@gmail.com
# 15/4/18


# trap keyboard interrupt (control-c)
trap control_c SIGINT
function Usage {
    cat <<USAGE
Usage:
`basename $0` -i InputImage -o OutputImage <other options>

Niifti Normalise for normalising niifti images between two PcTs (set at 99.99 and 0.01)
You must have FSL on your path.

Compulsory arguments:
-o: OutputFile: in nii format (USE FULL PATH)
-i: InputImage: in nii format (USE FULL PATH)

Optional arguments:
-b: keep all intermediate files 0 = off 1 = on (default = 0)
-h: print this help screen

Arguments must be parsed in this order

Send issues and comments to thomasbasilshaw@gmail.com
USAGE
    exit 1
}

#initialise variables with no input
CLEANUP=0
nargs=$#
# Provide output for Help
if [[ "$1" == "-h" ]];
then
    echo "$USAGE" >&2 
fi

# read the command line options
while getopts "h:o:i:b:" OPT
do
    case $OPT in
	h)  #help
	    echo "$USAGE" >&2
	    exit 0
	    ;;
	i) #inputfile
	    INPUT=$OPTARG
	    if [[ ! -e $INPUT ]] ;
	    then echo "INPUT NOT FOUND"
		 exit 1
	    fi
	    ;;
	o) #outputfile
	    OUTPUT=$OPTARG
	    ;;
	b) #cleanup files
	    CLEANUP=$OPTARG
	    ;;
	\?) # getopts issues an error message
	    echo "$USAGE" >&2
	    exit 1
	    ;;
    esac
done
if [[ $nargs -lt 2 ]]
then
    Usage >&2
fi
subjName=$INPUT
cwd=`pwd`
mkdir $cwd/NiiNormTemp
NII_DIR="$cwd/NiiNormTemp"
cd ${NII_DIR}
cleanup()
{
    echo "\n*** Performing cleanup, please wait ***\n"
    rm -r $NII_DIR
}

# run if user hits control-c
control_c()
{
    echo -en "\n*** User pressed CTRL + C ***\n"
    cleanup
    exit 1
}

if [[ ${INPUT:0 -6} == "nii.gz" ]] ; then cp ${INPUT} ${NII_DIR}/input.nii.gz 
elif [[ ${INPUT:0 -3} == "nii" ]] ; then  gzip ${INPUT}
					  cp ${INPUT}.gz ${NII_DIR}/input.nii.gz
else  echo "INPUT not in .nii or .nii.gz format, exiting..."
      exit 1
fi
#Main Files
IN=$NII_DIR/input.nii.gz
NORM=$NII_DIR/input_norm.nii.gz
THRESH1=$NII_DIR/thresh1.nii.gz
THRESH2=$NII_DIR/thresh2.nii.gz
THRESH1NORM=$NII_DIR/thresh1norm.nii.gz
THRESH3=$NII_DIR/thresh3.nii.gz
#First normalise between 0-100 into norm1
echo "Normalising..."
fslstats ${IN} -R>>${IN}_minmax.txt
min=`cat ${IN}_minmax.txt | awk '{ print $1 }'`
max=`cat ${IN}_minmax.txt | awk '{ print $2 }'`
scaling=`echo "scale=6; 100.0 / ( ${max} - ${min} )" | bc`
fslmaths ${IN} -sub ${min} -mul ${scaling} ${NORM}
#Threshhold out top and bottom PcT 0.01%, prepare thresh2 for addition in later
fslmaths ${NORM} -uthrp 99.99 -thrp 0.01 ${THRESH1}
fslmaths ${NORM} -thrp 99.99 -bin -mul 100 ${THRESH2}
#Clamp back between 0 - 100 ( dont worry about subtracting 0 because threshhold)
min1="0"
max1=`fslstats ${THRESH1} -R | awk '{ print $2 }'`
scaling1=`echo "scale=6; 100.0 / ( ${max1} - ${min1} )" | bc`
fslmaths ${THRESH1} -mul ${scaling1} ${THRESH1NORM}
#Add thresh1norm to thresh2 into thresh3
fslmaths ${THRESH1NORM} -add ${THRESH2} ${THRESH3}
#Norm thresh3 into final
fslstats ${THRESH3} -R>>${THRESH3}_maxmin.txt
min2=`cat ${THRESH3}_maxmin.txt | awk '{ print $1 }'`
max2=`cat ${THRESH3}_maxmin.txt | awk '{ print $2 }'`
scaling2=`echo "scale=6; 100.0 / ( ${max2} - ${min2} )" | bc`
if [[ ${OUTPUT:0 -6} == "nii.gz" ]] ; then
    fslmaths ${THRESH3} -sub ${min2} -mul ${scaling2} ${OUTPUT} 
elif [[ ${OUTPUT:0 -3} == "nii" ]] ; then
    fslmaths ${THRESH3} -sub ${min2} -mul ${scaling2} ${OUTPUT}.gz
    gunzip ${OUTPUT}.gz
fi
if [[ $CLEANUP == 0 ]] ; then
    echo "Cleanup"
    rm ${NII_DIR}/*
    rm -d "$NII_DIR" ; fi
if [[ ${CLEANUP} == 1 ]] ; then
    echo "no cleanup"
    mv ${NII_DIR} ./niiNormalise_${subjName:0: -4} 
fi
echo "Done. Normalised file is named $OUTPUT"

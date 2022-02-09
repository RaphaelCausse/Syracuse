#!/bin/bash

# Script file : syracuse.bash
# MUNOZ Melvyn, CAUSSE Raphael
# CY TECH PREING 2 MI 2

function usage {
    echo -e "\e[1mUsage:\e[0m\n\t$0 [options]  [start] [end]\n"
    echo -e "\e[1mOptions:\e[0m"
    echo -e "\t\e[1m-s\e[0m\tDisplay the synthesis of current execution.\n"
    echo -e "\t\e[1m-c\e[0m\tClean the project directory. ! Warning ! All files will be deleted after confirmation.\n"
    echo -e "\t\e[1m-h\e[0m\tPrint this help message and exit.\n"
    echo -e "\e[1mInformations:\e[0m"
    echo -e "\t[start] and [end] must be strictly positive integer."
    exit 0
}
function clean {
    if [ ! -d Data ] || [ ! -d Images ] || [ ! -d Synthesis ]; then
        echo "Project directory is already clean !"
        exit 0   
    fi
    read -p "Do you want to delete all files in Data/ Images/ and Synthesis/ ? [Y/n] " -n 1 -r
    if [[ ${REPLY} =~ ^[Yy]$ ]]; then
        rm -rf Data/ Images/ Synthesis/
        echo -e "\nCleanup completed !"
        exit 0
    fi
}
function error_args {
    echo -e "\e[1m\e[31mError:\e[0m unvalid argument:"
    echo "Run « ./syracuse.bash -h » for more information."
    exit 1
}

GRN='\033[1;32m'
NC='\033[0m'

# Check options
arg_s=0
while getopts "sch" options; do
    case ${options} in 
        s)  arg_s=1
            shift ;;
        c)  clean ;;
        h)  usage ;;
        *)  error_args ;;
    esac
done
# Check for 2 valid arguments, 2 strictly positive integers
if [ $# -ne 2 ]; then 
    error_args
fi
if [[ $1 =~ ^[1-9]+[0-9]*$ ]] && [[ $2 =~ ^[1-9]+[0-9]*$ ]]; then
    # Create subdirectories to store data
    mkdir -p Data Images Synthesis
    # Compare dates of main.c and syracuse to compile or recompile it if necessary
    if [ "main.c" -nt "Data/syracuse" ]; then
        gcc -O3 main.c -o Data/syracuse
    fi
    # Display progress bar
    total=$(($2 - $1)); step=$((total / 10)); percent=0; bar=""; dot=40; count=0
    echo -e "Processing..."
    echo -ne "[........................................] ${percent}%\r"
    # Build data files with C executable 
    for i in $(seq $1 $2); do
        ./Data/syracuse ${i} Data/f${i}.dat
        # Collect data from data files and store them in temporary files
        head -n-3 Data/f${i}.dat | tail +2 >> sequence_data && echo >> sequence_data
        echo "${i} $(tail -3 Data/f${i}.dat | head -1 | cut -d'=' -f2)" >> altitude_max
        echo "${i} $(tail -2 Data/f${i}.dat | head -1 | cut -d'=' -f2)" >> flight_time
        echo "${i} $(tail -1 Data/f${i}.dat | cut -d'=' -f2)" >> altitude_time
        # Update progress bar
        ((count++))
        if [ ${count} -ge ${step} ]; then
            bar+="##"; ((dot -= 2)); ((percent += 5)); count=0
            echo -ne "[${GRN}${bar}${NC}"
            for i in $(seq ${dot} -1 1); do echo -ne "."; done
            echo -ne "] ${percent}%\r"
        fi
    done
    # Bonus: data synthesis
    sum=0
    synth_file="Synthesis/synthese-$1-$2.txt"
    # Build synthesis if it doesn't already exist
    if [ ! -f ${synth_file} ]; then
        list_files=("altitude_max" "flight_time" "altitude_time")
        echo -e "Syracuse Synthesis [$1;$2]\n" >> ${synth_file}
        for i in $(seq 0 2); do
            # Collect min and max of each file in list_files
            echo "${list_files[${i}]}:" >> ${synth_file}
            min_max=($(sort -k2n ${list_files[${i}]} | sed -n '1p;$p' | cut -d' ' -f2))
            echo -e "\tmin = ${min_max[0]}" >> ${synth_file}
            echo -e "\tmax = ${min_max[1]}" >> ${synth_file}
            # Calculate average of each file in list_files
            len=$(cat ${list_files[${i}]} | wc -l) && values=$(cat ${list_files[${i}]} | cut -d' ' -f2)
            for i in ${values[@]}; do ((sum += i)); done
            avg=$(echo "scale=2; ${sum}/${len}" | bc -l)
            echo -e "\tavg = ${avg}" >> ${synth_file}
            # Update progress bar
            bar+="####"; ((dot -= 4)); ((percent += 10))
            echo -ne "[${GRN}${bar}${NC}"
            for i in $(seq ${dot} -1 1); do echo -ne "."; done
            echo -ne "] ${percent}%\r"
        done
    else
        # Update progress bar
        bar+="############"; ((dot -= 12)); ((percent += 30))
        echo -ne "[${GRN}${bar}${NC}"
        for i in $(seq ${dot} -1 1); do echo -ne "."; done
        echo -ne "] ${percent}%\r"
    fi
    # Analyze data with gnuplot
    gnuplot -persist <<- EOFMarker
        set terminal jpeg size 1920,1080
        set output "Images/vols[$1;$2].jpeg"
        set title "Un en fonction de n pour tous les U0 dans [$1;$2]"
        set xlabel "n"
        set ylabel "Un"
        plot "sequence_data" w l lw 1 title "vols"
    reset
        set terminal jpeg size 1920,1080
        set output "Images/altitude[$1;$2].jpeg"
        set title "Altitude maximum atteinte en fonction de U0"
        set xlabel "U0"
        set ylabel "Altitude maximum"
        plot "altitude_max" w l lw 1 title "altitude"  
    reset
        set terminal jpeg size 1920,1080
        set output "Images/dureevol[$1;$2].jpeg"
        set title "Duree de vol en fonction de U0"
        set xlabel "U0"
        set ylabel "Nombres d'occurrences"
        plot "flight_time" w l lw 1 title "dureevol"
    reset
        set terminal jpeg size 1920,1080
        set output "Images/dureealtitude[$1;$2].jpeg"
        set title "Duree de vol en altitude en fonction de U0"
        set xlabel "U0"
        set ylabel "Nombres d'occurrences"
        plot "altitude_time" w l lw 1 title "dureealtitude"
EOFMarker
    # Remove temporary data files 
    rm Data/*.dat sequence_data altitude_max flight_time altitude_time
    # Update progress bar
    bar+="########"; percent=100
    echo -e "[${GRN}${bar}${NC}] ${percent}%\nTask completed !\n"
    # Display synthesis if option -s is given
    if [ ${arg_s} -eq 1 ]; then
        cat ${synth_file}
    fi
fi
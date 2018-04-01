#!/bin/bash

# >>> TODO <<<
# > function for every argument-taking option ?
# > multiple files/directories in manual mode
# > -L[p|n] compatible with daemon mode
# > -Mc option to use the color passed in argument as a wallpaper
# > -h help option

SD=$(dirname $(realpath $0)) # This script directory

source $SD/.wpm/cmd.sh # Load wallpaper get/set functions

CUSTOM_WPL=$SD/.wpm/custom.wpl # Default wallpaper list in custom mode
LAST_WPL=$SD/.wpm/last.wpl # Wallpaper list in last mode

mode=none
random=false
daemon=false
noopt=true # True if no mode(s)-specific options are given


if [ $# -eq 0 ]; then
    echo "Usage: wpm    -Mf         \"<wallpaper>...\"    [-R]    [-D [<delay>]]"
    echo "       wpm    -Md         \"<directory>...\"    [-R]    [-D [<delay>]]"
    echo "       wpm    -C[s|r]     [<wallpaper_list>]  [-R]    [-D [<delay>]]"
    echo "       wpm    -L[p|n|s    [<wallpaper_list>]] [-R]    [-D [<delay>]]"
    echo "       wpm    -I[f|d]"
    exit 0
fi


# Check if option $1 is used in one of the specified modes, quit if not
checkmode () {
    local option=$1
    shift 1
    if [[ ! $@ =~ $mode ]]; then
        local modeopts="-["
        for mode in $@; do
            modeopts=$modeopts$(echo $mode | head -c1 | sed "s/\(.\)/\U\1/")"|"
        done
        modeopts=${modeopts%|}"]"
        if [ $# -eq 1 ]; then
            modeopts=$(echo $modeopts | tr -d [])
        fi
        echo "Option -$option must be used with $modeopts option"
        exit $(printf "%d" "'$option")
    fi
}


##### Wallpaper list manipulation functions #####

# Get the line number of a wallpaper in a list
get_numline () {
    echo $(grep -n "$1" $2 | cut -d: -f1)
}
# Load a list
load_wpl () {
    wps=$(cat $1)
}
# Save a wallpaper in a list
save_wp () {
    if [ -z "$(grep "$1" $2)" ]; then
        echo "$1" >> $2
    fi
}
# Remove a wallpaper from a list
remove_wp () {
    local numline=$(get_numline "$1" $2)
    if [ "$numline" ]; then
        sed -i "${numline}d" $2
    else
        echo "Current wallpaper absent from the custom list"
    fi
}


##### Options parsing #####

# Get mode
getopts ":MCLI" opt
case $opt in
    M)
        mode=manual
        ;;
    C)
        mode=custom
        ;;
    L)
        mode=last
        ;;
    I)
        mode=info
        ;;
    ?)
        echo "You must choose a mode tu use wpm"
        exit 2
        ;;
esac

# Parse options
while getopts ":f:d:s:r:p:n:RD:" opt; do
    case $opt in
### Mode(s) dependant options (by convention lowercases) ###
    f|d|s|r|p|n)
        noopt=false
        case $opt in
    ### Manual mode ###
        f|d)
            checkmode $opt manual
            case $opt in
        # Load the wallpaper from a file
            f)  
                set_wp "$OPTARG"
                exit 0
                ;;
        # Load all the wallpapers from a directory
            d)
                dirs=("$OPTARG")
                ;;
            esac
            ;;
    ### Custom mode ###
        # Remove current wallpaper from list
        r)
            checkmode $opt custom
            remove_wp "$(get_wp)" $OPTARG
            exit 0
            ;;
    ### Last mode ###
        p|n)
            checkmode $opt last
            numline=$(get_numline "$(get_wp)" $LAST_WPL)
            nblines=$(wc -l $LAST_WPL | cut -d\  -f1)
            case $opt in
        # Load $OPTARGth previous wallpaper in last list
            p)
                l=$((-OPTARG))
                ;;
        # Load $OPTARGth next wallpaper in last list
            n) 
                l=$((OPTARG))
                ;;
            esac
            numline=$((numline + l - 1))
            if [ $numline -ge 0 ]; then
                numline=$((numline % nblines))
            elif [ $numline -lt 0 ]; then
                if [ $((-numline % nblines)) -eq 0 ]; then
                    numline=0
                else
                    numline=$((nblines - -numline % nblines))
                fi
            fi
            numline=$((numline + 1))
            set_wp "$(sed "${numline}q;d" $LAST_WPL)"
            exit 0
            ;;
    ### Multi mode ###
        s)
            checkmode $opt custom last
            case $mode in
        # Append current wallpaper to custom list
            custom)
                save_wp "$(get_wp)" $OPTARG
                ;;
        # Save last list in the file passed in argument
            last)
                cat $LAST_WPL > $OPTARG
                ;;
            esac
            exit 0
            ;;
        esac
        ;;
### Mode independant options (by convention uppercases) ###
    # Random selection in wallpaper list
    R)
        random=true
        ;;
    # Daemon mode : runs indefinitely, changing wallpaper within a delay given in argument
    D)
        daemon=true
        delay=$OPTARG
        ;;
### Missing argument handling ###
    :)
        case $OPTARG in
    ### Mode(s) dependant options ###
        f|d|s|r|p|n)
            noopt=false
            case $OPTARG in
        ### Custom mode ###
            # Use default custom list in custom mode
            r)  
                checkmode $OPTARG custom
                remove_wp "$(get_wp)" $CUSTOM_WPL
                exit 0
                ;;
        ### Last mode ###
            p|n)
                checkmode $OPTARG last
                numline=$(get_numline "$(get_wp)" $LAST_WPL)
                nblines=$(wc -l $LAST_WPL | cut -d\  -f1)
                case $OPTARG in
            # Load previous wallpaper in last list
                p)
                    numline=$((numline - 1))
                    if [ $numline -lt 1 ]; then
                        numline=$nblines
                    fi
                    ;;
            # Load next wallpaper in last list
                n) 
                    numline=$((numline + 1))
                    if [ $numline -gt $nblines ]; then
                        numline=1
                    fi
                    ;;
                esac
                set_wp "$(sed "${numline}q;d" $LAST_WPL)"
                exit 0
                ;;
        ### Multi mode ###
            f|d)
                checkmode $OPTARG manual info
                case $mode in
            # Argument needed in manual mode
                manual)
                    case $OPTARG in
                    f)
                        echo "Usage: wpm -Mf <wallpaper>..."
                        ;;
                    d)
                        echo "Usage: wpm -Md <directory>..."
                        ;;
                    esac
                    ;;
                info)
                    case $OPTARG in
            # Print current wallpaper path
                    f)
                        echo "$(get_wp)"
                        ;;
            # Print current wallpaper directory path
                    d)
                        echo "$(dirname "$(get_wp)")"
                        ;;
                    esac
                    ;;
                esac
                exit 0
                ;;
            s)
                checkmode $OPTARG custom last
                case $mode in
            # Use default custom list in custom mode
                    custom)
                        save_wp "$(get_wp)" $CUSTOM_WPL
                        ;;
            # Replace default custom list by last list 
                    last)
                        cat $LAST_WPL > $CUSTOM_WPL
                        ;;
                esac
                exit 0
                ;;
            esac
            ;;
    ### Mode independant options ###
        # Use a default delay of 6 minutes (360 seconds) in daemon mode
        D)
            daemon=true
            delay=360
            ;;
        esac
        ;;
### Invalid option ###
    ?)
        echo "Invalid option: -$OPTARG"
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1)) # Remove options and their arguments from argument list


##### Mode specific operations #####

case $mode in
    manual)
        # Quit if there are no additional options
        if [ $noopt = true ]; then
            echo "Usage: wpm -Mf <wallpaper>..."
            echo "       wpm -Md <directory>... [-R][-D [<delay>]]"
            exit 0
        fi
        ;;
    info)
        # Quit if there are no additional options
        if [ $noopt = true ]; then
            echo "Usage: wpm -I[f|d]"
            exit 0
        fi
        ;;
    custom)
        # Load the custom list passed in argument
        if [ -n "$1" ]; then
            if [ -f $1 ]; then
                load_wpl $1
            else
                echo "Wallpaper list must be a regular file"
                exit 3
            fi
        # Or load the default custom list if no argument
        else
            load_wpl $CUSTOM_WPL
        fi
        ;;
    last)
        # Load the last list
        load_wpl $LAST_WPL
        ;;
esac


##### One instance of wpm at a time #####

pids=$(ps -C wpm -o pid=)
if [ $(echo "$pids" | wc -l | cut -d\  -f1) -gt 1 ]; then
    while read -r pid; do
        if [ $pid != $$ ]; then
            kill $pid
        fi
    done <<< "$pids"
fi


##### Fill list of wallpapers #####

# Add wallpapers from the list of dirs
for dir in "${dirs[@]}"; do
    wps+=$(find "$dir" -type f)"\n"
done
wps=${wps%\\n} # Remove last \n

# Exit if there is one or no wallpaper in the list
wpsnb=$(echo "$wps" | wc -l)
if [ $wpsnb -le 1 ]; then
    if [ $wpsnb -eq 0 ]; then
        echo "No wallpaper found. Exiting..."
    fi
    exit 0
fi

# Write the list in the last list file for next instance
echo "$wps" > $LAST_WPL


##### Loop through list of wallpapers #####

# Infinite loop to read again the list in daemon mode
while [ 1 ]; do
    # Randomize list if -R option enabled
    if [ $random = true ]; then
        wps=$(echo "$wps" | shuf)
    fi
    # Read the list line by line
    while read -r wp; do
        if [ "$wp" != "$(get_wp)" ] || [ $random = false ]; then
            # Change wallpaper (finally!)
            set_wp "$wp"
            # Exit if in normal mode...
            if [ $daemon = false ]; then
                exit 0
            fi
            # ...or read the entire list in daemon mode
            sleep $delay
        fi
    done <<< "$wps"
done

#!/bin/bash

# >>> TODO <<<
# > multiple files/directories in manual mode
# > -Mc option to use the color passed in argument as a wallpaper
# > -h help option

SD=`dirname \`realpath $0\`` # This script directory

source $SD/.wpm/cmd.sh # Load wallpaper get/set functions

CUSTOM_WPL=$SD/.wpm/custom.wpl # Default wallpaper list in custom mode
LAST_WPL=$SD/.wpm/last.wpl # Wallpaper list in last mode

mode=none
random=false
daemon=false

if [ $# -eq 0 ]; then
    echo "Usage: wpm    -Mf         \"<wallpaper>...\"  [-R]    [-D [<delay>]]"
    echo "       wpm    -Md         \"<directory>...\"  [-R]    [-D [<delay>]]"
    echo "       wpm    -C[s|r]     [<wallpaper_list>]  [-R]    [-D [<delay>]]"
    echo "       wpm    -L[p|n|s    [<wallpaper_list>]] [-R]    [-D [<delay>]]"
    echo "       wpm    -I[f|d]"
    exit 0
fi

# Check if current parsed option is used in specified mode, quit if not
checkmode () {
    local option=$1
    shift 1
    if [[ ! $@ =~ $mode ]]; then
        local modeopts="-["
        for mode in $@; do
            modeopts=$modeopts`echo $mode | head -c1 | sed "s/\(.\)/\U\1/"`"|"
        done
        modeopts=${modeopts%?}"]"
        if [ $# -eq 1 ]; then
            modeopts=`echo $modeopts | tr -d []`
        fi
        echo "Option -$option must be used with $modeopts option"
        exit `printf "%d" "'$option"`
    fi
}

# Wallpaper list manipulation functions

# Get the line number of a wallpaper in a list
get_numline () {
    echo `grep -n "$1" $2 | cut -d: -f1`
}
# Load a list
load_wpl () {
    wps=`cat $1`
}
# Save a wallpaper in a list
save_wp () {
    if [ -z "`grep \"$1\" $2`" ]; then
        echo "$1" >> $2
    fi
}
# Remove a wallpaper from a list
remove_wp () {
    sed -i "`get_numline \"$1\" $2`d" $2
}

# Options parsing

while getopts ":MCLIf:d:s:r:pnRD:" opt; do
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
    # Manual mode
        f|d)
            checkmode $opt manual
            case $opt in
                f)  # Load the wallpaper from a file
                    set_wp "$OPTARG"
                    exit
                    ;;
                d)  # Load all the wallpapers from a directory
                    dirs=($OPTARG)
                    ;;
            esac
            ;;
    # Custom mode
        s|r)
            checkmode $opt custom
            case $opt in
                s)  # Append current wallpaper to list
                    save_wp "`get_wp`" $OPTARG
                    ;;
                r)  # Remove current wallpaper from list
                    remove_wp "`get_wp`" $OPTARG
                    ;;
            esac
            exit
            ;;
    # Last mode
        p|n|s)
            checkmode $opt last
            case $opt in
                p|n)
                    numline=`get_numline "\`get_wp\`" $LAST_WPL`
                    case $opt in
                        p)  # Load previous wallpaper in last list
                            numline=$((numline - 1))
                            if [ $numline -lt 1 ]; then
                                numline=`wc -l $LAST_WPL | cut -d\  -f1`
                                echo $numline
                            fi
                            ;;
                        n)  # Load next wallpaper in last list
                            numline=$((numline + 1))
                            if [ $numline -gt `wc -l $LAST_WPL | cut -d\  -f1` ]; then
                                numline=1
                            fi
                            ;;
                    esac
                    set_wp "`sed \"${numline}q;d\" $LAST_WPL`"
                    ;;
                s)
                    echo $LAST_WPL > $OPTARG
                    ;;
            esac
            exit
            ;;
    # Mode independant options
        R)  # Random selection in wallpaper list
            random=true
            ;;
        D)  # Daemon mode : runs indefinitely, changing wallpaper within a delay given in argument
            daemon=true
            DELAY=$OPTARG
            ;;
    # Missing argument handling
        :)
            case $OPTARG in
                # Use default custom list with -Cr
                r)  
                    checkmode $OPTARG custom
                    remove_wp "`get_wp`" $CUSTOM_WPL
                    exit
                    ;;
                # Multi mode options
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
                                f)  # Print current wallpaper path
                                    echo "`get_wp`"
                                    ;;
                                d)  # Print current wallpaper directory path
                                    echo "`dirname \"\`get_wp\`\"`"
                                    ;;
                            esac
                            ;;
                    esac
                    exit 0
                    ;;
                s)
                    checkmode $OPTARG custom last
                    case $mode in
                        # Use default custom list with -Cs
                        custom)
                            save_wp "`get_wp`" $CUSTOM_WPL
                            ;;
                        # Replace default custom list by last list
                        last)
                            echo "Usage: wpm -Ls <filepath>"
                            exit 4
                            ;;
                    esac
                    exit
                    ;;
                # Use a default delay of 6 minutes in daemon mode
                D)
                    daemon=true
                    DELAY=600
                    ;;
            esac
            ;;
    # Invalid option
        ?)
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1)) # Remove options and their arguments from argument list

# Quit if no mode option was given
if [ $mode = none ]; then
    echo "You must choose a mode to use wpm"
    exit 2
fi

# Mode specific operations
if [ $mode = manual ]; then
    if [ -z "`echo $dirs`" ]; then
        echo "Usage: wpm -Mf <wallpaper>..."
        echo "       wpm -Md <directory>... [-R][-D [<delay>]]"
        exit 0
    fi
else
    if [ $mode = custom ]; then
        if [ -n "$1" ]; then
            if [ -f $1 ]; then
                load_wpl $1
            else
                echo "Wallpaper list must be a regular file"
                exit 3
            fi
        else
            load_wpl $CUSTOM_WPL
        fi
    else
        if [ $mode = last ]; then
            load_wpl $LAST_WPL
        fi
    fi
fi

# One instance of wpm at a time
pids=`ps -C wpm -o pid=`
if [ `echo "$pids" | wc -l | cut -d\  -f1` -gt 1 ]; then
    while read -r pid; do
        if [ $pid != $$ ]; then
            kill $pid
        fi
    done <<< "$pids"
fi

# Fill list of wallpapers
for dir in $dirs; do
    wps+=`find $dir -type f`"\n"
done
wps=`echo "$wps" | sed "s/^\n$//g"`
wpsnb=`echo "$wps" | wc -l | cut -d\  -f1`
if [ $wpsnb -le 1 ]; then
    if [ $wpsnb -eq 0 ]; then
        echo "No wallpaper found. Exiting..."
    fi
    exit 0
fi
echo "$wps" > $LAST_WPL

# Loop through list of wallpapers
while [ 1 ]; do
    if [ $random = true ]; then
        wps=`echo "$wps" | shuf`
    fi
    while read -r wp; do
        if [ "$wp" != "`get_wp`" ] || [ $random = false ]; then
            set_wp "$wp"
            if [ $daemon = false ]; then
                exit 0
            fi
            sleep $DELAY
        fi
    done <<< "$wps"
done

# Get current wallpaper
get_wp () { 
    echo $(tail -n1 ~/.fehbg | cut -d\' -f2)
}
# Set current wallpaper
set_wp () { 
    feh --bg-fill "$1"
}

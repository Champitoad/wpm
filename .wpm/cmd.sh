# Get current wallpaper
get_wp () { 
    echo `gsettings get org.gnome.desktop.background picture-uri` | tr -d \'
}
# Set current wallpaper
set_wp () { 
    gsettings set org.gnome.desktop.background picture-uri "$1"
}

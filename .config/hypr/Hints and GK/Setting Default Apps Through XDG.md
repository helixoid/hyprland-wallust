
First Install xdg-utils package

# Set Default Browser #
xdg-settings set default-web-browser <app.desktop>

# .desktop files location
/usr/share/applications/

# Get File Types #
xdg-mime query filetype <Tab> <Select your file>

# Get Default App for That Filetype #
xdg-mime query default <filetype/extention>

# Set Another App to Default for That Filetype #
xdg-mime default <app.desktop> <filetype/extention>

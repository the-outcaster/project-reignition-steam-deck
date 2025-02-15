#!/bin/bash

clear
echo -e "Project Reignition Steam Deck Builder - script by The Outcaster"
title="Project Reignition Steam Deck Builder"

# Removes unhelpful GTK warnings
zen_nospam() {
  zenity 2> >(grep -v 'Gtk' >&2) "$@"
}

# zenity functions
error() {
	e=$1
	zen_nospam --error --title="$title" --width=500 --height=100 --text "$1"
}

info() {
	i=$1
	zen_nospam --info --title "$title" --width 400 --height 75 --text "$1"
}

progress_bar() {
	t=$1
	zen_nospam --title "$title" --text "$1" --progress --auto-close --auto-kill --pulsate --width=300 --height=100

	if [ "$?" != 0 ]; then
		echo -e "\nUser canceled.\n"
	fi
}

question() {
	q=$1
	zen_nospam --question --title="$title" --width=300 height=200 --text="$1"
}

# menus
main_menu() {
	zen_nospam --width 700 --height 350 --list --radiolist --multiple --title "$title"\
	--column ""\
	--column "Option"\
	--column="Description"\
	FALSE Download "Compile Project Reignition from source (may be buggy!)"\
	FALSE Pre-Compiled "Download the latest pre-compiled build"\
	FALSE Changelog "See changelog (your web browser will open)"\
	FALSE Shortcut "Create a desktop and Application shortcut for Project Reignition"\
	TRUE Exit "Exit this script"
}

# Check if GitHub is reachable
if ! curl -Is https://github.com | head -1 | grep 200 > /dev/null
then
    echo "GitHub appears to be unreachable, you may not be connected to the Internet."
    exit 1
fi

cd $HOME
mkdir -p Applications
cd Applications

# Main menu
while true; do
Choice=$(main_menu)
	if [ $? -eq 1 ] || [ "$Choice" == "Exit" ]; then
		echo Goodbye!
		exit

	elif [ "$Choice" == "Download" ]; then

		# check if Godot Flatpak exists, if not install
		if ! [ -d $HOME/.local/share/flatpak/app/org.godotengine.GodotSharp ]; then
			echo -e "\nInstalling Godot..."
			sleep 1
			flatpak install --user org.godotengine.GodotSharp -y
		else
			echo -e "\nGodot is installed, skipping"
			sleep 1
		fi

		# get godot version so we can make the proper dir name
		version=$(flatpak run org.godotengine.GodotSharp -q --version)
		godot_version="${version%*.flathub*}"
		echo -e "\nGodot version is $godot_version"
		sleep 1

		# check to see if we have the Linux export template
		if ! [ -f $HOME/.var/app/org.godotengine.GodotSharp/data/godot/export_templates/$godot_version/linux_release.x86_64 ]; then
			mkdir -p $HOME/.var/app/org.godotengine.GodotSharp/
			mkdir -p $HOME/.var/app/org.godotengine.GodotSharp/data/
			mkdir -p $HOME/.var/app/org.godotengine.GodotSharp/data/godot/
			mkdir -p $HOME/.var/app/org.godotengine.GodotSharp/data/godot/export_templates/
			mkdir -p $HOME/.var/app/org.godotengine.GodotSharp/data/godot/export_templates/$godot_version/

			echo -e "\nDownloading export templates..."
			sleep 1
			DOWNLOAD_URL=$(curl -s https://api.github.com/repos/godotengine/godot/releases/latest \
					| grep "browser_download_url" \
					| grep mono_export_templates \
					| cut -d '"' -f 4)
			curl -L "$DOWNLOAD_URL" -o $HOME/Downloads/export_templates.tpz

			echo -e "\nExtracting export templates..."
			sleep 1

			unzip -j -o $HOME/Downloads/export_templates.tpz -d $HOME/.var/app/org.godotengine.GodotSharp/data/godot/export_templates/$godot_version/
			rm $HOME/Downloads/export_templates.tpz
		else
			echo -e "\nExport templates found, skipping"
			sleep 1
		fi

		# check to see if repo already exists
		if ! [ -d $HOME/Applications/project-reignition/.git ]; then
			echo -e "\nCloning repo..."
			sleep 1
			git clone https://github.com/Kuma-Boo/project-reignition.git

			echo -e "\nDownloading export presets..."
			sleep 1
			wget https://github.com/the-outcaster/project-reignition-steam-deck/raw/main/export_presets.cfg
			mv export_presets.cfg $HOME/Applications/project-reignition/Project/
		else
			echo -e "\nRepo already exists, checking for any new commits..."
			sleep 1
			cd $HOME/Applications/project-reignition
			git pull
		fi

		info "Godot will temporarily open to import assets. Ignore any errors."
		flatpak run org.godotengine.GodotSharp $HOME/Applications/project-reignition/Project/project.godot --import

		echo -e "\nExporting..."
		sleep 1
		mkdir -p $HOME/Applications/project-reignition/build/
		flatpak run org.godotengine.GodotSharp --headless $HOME/Applications/project-reignition/Project/project.godot --export-release "Linux/X11" $HOME/Applications/project-reignition/build/project-reignition.x86_64

		info "Project Reignition downloaded/updated!"

	elif [ "$Choice" == "Pre-Compiled" ]; then
		echo -e "\nDownloading archive..."
		sleep 1
		DOWNLOAD_URL=$(curl -s https://api.github.com/repos/the-outcaster/project-reignition-steam-deck/releases/latest \
				| grep "browser_download_url" \
				| grep linux \
				| cut -d '"' -f 4)
		curl -L "$DOWNLOAD_URL" -o $HOME/Downloads/project-reignition.zip

		echo -e "\nExtracting..."
		sleep 1
		mkdir -p $HOME/Applications/project-reignition-linux/
		unzip -o $HOME/Downloads/project-reignition.zip -d $HOME/Applications/project-reignition-linux/

		echo -e "\nRenaming executables..."
		sleep 1
		cd $HOME/Applications/project-reignition-linux/
		mv Sonic\ and\ the\ Secret\ Rings\ Remake.pck project-reignition.pck
		mv Sonic\ and\ the\ Secret\ Rings\ Remake project-reignition.x86_64

		echo -e "\nRemoving zip file..."
		rm $HOME/Downloads/project-reignition.zip

		if ( question "Would you like to download the video files? (Download size is ~700 MB)"); then
		yes |
			echo -e "\nDownloading video archive..."
			sleep 1
			DOWNLOAD_URL=$(curl -s https://api.github.com/repos/the-outcaster/project-reignition-steam-deck/releases/latest \
					| grep "browser_download_url" \
					| grep video \
					| cut -d '"' -f 4)
			curl -L "$DOWNLOAD_URL" -o $HOME/Downloads/project-reignition-videos.zip

			echo -e "\nExtracting..."
			sleep 1
			unzip -o $HOME/Downloads/project-reignition-videos.zip -d $HOME/Applications/project-reignition-linux/

			echo -e "\nCleaning up..."
			sleep 1
			rm $HOME/Downloads/project-reignition-videos.zip
		else
			echo -e "\nVideo download skipped"
			sleep 1
		fi

		info "Project Reignition downloaded to $HOME/Applications/project-reignition-linux/"

	elif [ "$Choice" == "Changelog" ]; then
		xdg-open https://github.com/Kuma-Boo/project-reignition/releases

	elif [ "$Choice" == "Shortcut" ]; then
		echo -e "\nFetching icon..."
		sleep 1
		wget https://cdn2.steamgriddb.com/grid/dfb0f2c6bbb1cc9ae19e65fa4049d1fb.jpg
		mv dfb0f2c6bbb1cc9ae19e65fa4049d1fb.jpg icon.jpg
		mv icon.jpg $HOME/Applications/project-reignition-linux/

		echo -e "\nFetching desktop file..."
		sleep 1
		wget https://github.com/the-outcaster/project-reignition-steam-deck/raw/main/project-reignition.desktop

		echo -e "Copying shortcut to desktop..."
		sleep 1
		cp project-reignition.desktop $HOME/Desktop/

		echo -e "Copying shortcut to Applications menu..."
		sleep 1
		cp project-reignition.desktop $HOME/.local/share/applications/

		rm project-reignition.desktop

		info "Shortcut added!"
	fi
done

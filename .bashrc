# ~/.bashrc: executed by bash(1) for non-login shells.
# See /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# Make 'less' more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# Colored prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Enable color support of ls and add  shandy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable programmable completion features (you don't need to enable
# this if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# PATH modifications
# Android tools
export PATH=${PATH}:${HOME}/Computer/android-sdk-linux/tools:${HOME}/Computer/android-sdk-linux/platform-tools
# RVM
export PATH=${PATH}:${HOME}/.rvm/bin
# Heroku toolbelt
export PATH=${PATH}:/usr/local/heroku/bin

# Load RVM
source $HOME/.rvm/scripts/rvm

# Aliases
# Show an alert for long running commands.  Use like so: "sleep 10; alert"
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
# Easy extract
# Try dtrx if atool doesn't work
alias extract="atool -x -D"
# Run a Ruby script and drop into irb when finished rather than terminating
alias rirb="irb -I./ -r"
# Navigation
alias docs="cd ~/Documents"
alias school="cd ~/Documents/school"

# Functions

# List Brother devices
brother-list()
{
    brsaneconfig3 -q
}

# Add Brother device
brother-add()
{
    brsaneconfig3 -r $1
    brsaneconfig3 -a name="$1" model=$1 ip=$2
}

# Remove Brother device
brother-remove()
{
    brsaneconfig3 -r $1
}

# Confirm, yes or no
confirm-yn()
{
    read yn
    case $yn in
        [Yy]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Push current config files to repo
backupconfig()
{
    # Pull latest changes
    pullconfig
    echo

    # Continue?
    backupDir="/home/riley/Computer/backup/config"
    origDir=`pwd`
    cd $backupDir
    echo "Continue with backup? (y/N)"
    confirm-yn
    if [[ $? -ne 0 ]]
    then
        cd $origDir
        return 0
    fi

    # Update shared files
    # Iterate over each line in the file rather than each chunk separated by whitespace
    # NOTE: Index file must end with blank line!
    while read index
    do
        # Overwrite the files in this directory
        # Delete any files in the target (this) directory that don't exist in the source
        # For example, remove files for any Sublime plugins that have been uninstalled
        rsync --exclude-from .gitignore -rupEShi --delete --delete-excluded "${index}" $backupDir
    done < "index-common"

    # Determine which computer this is
    thisComputer=`hostname`
    dashCharLoc=`echo $thisComputer | xargs -I {} expr index {} '-'`
    hostDir=${thisComputer:$dashCharLoc}

    # Add any files specific to this host
    if [[ -f "index-${hostDir}" ]]
    then
        # Create a directory for this host if it doesn't exist
        if [[ ! -d "$hostDir" ]]
        then
            echo "Creating directory '${hostDir}' for this host"
            mkdir $hostDir
        fi
        # Copy the host-specific files to the new directory
        while read index
        do
            rsync -rupEShi --delete "$index" $hostDir
        done < "index-${hostDir}"
    fi

    # List the contents of the directory
    echo
    echo "The following will be backed up:"
    tree -a --noreport --dirsfirst -L 2 -I .git $backupDir
    echo

    # Continue?
    echo "Continue? (y/N)"
    confirm-yn
    if [[ $? -ne 0 ]]
    then
        cd $origDir
        return 0
    fi

    # Add/update files
    echo
    git add .
    git add -A
    git status
    echo
    echo "Commit these changes? (y/N)"
    confirm-yn
    if [[ $? -ne 0 ]]
    then
        cd $origDir
        return 0
    fi

    # Commit
    echo
    echo "Commit message (single line, no surrounding quotes):"
    read commitMsg
    echo
    git commit -m "$commitMsg" | head -n 2

    # Push
    echo
    echo "Pushing..."
    git push; alert

    # Return to original directory
    echo "Done."
    cd $origDir
}

# Pull latest config files from repo
# Ask before overwriting files currently on the system
pullconfig()
{
    restoreDir="/home/riley/Computer/backup/config"
    origDir=`pwd`
    cd $restoreDir

    # Pull latest changes
    echo "Pulling latest changes..."
    changes=$(git pull | tee /dev/tty)
    if [[ "$changes" == "Already up-to-date." ]]
    then
        cd $origDir
        return 0
    fi
    echo

    # Continue? This is so that changes can be pulled but not applied
    echo "Apply changes? (y/N)"
    confirm-yn
    if [[ $? -ne 0 ]]
    then
        cd $origDir
        return 0
    fi

    # Determine which computer this is
    thisComputer=`hostname`
    dashCharLoc=`hostname | xargs -I {} expr index {} '-'`
    hostDir=${thisComputer:$dashCharLoc}

    # Update shared files
    while read index
    do
        # Get just the name of the file/directory
        name=`echo "$index" | awk -F "/" '{ print $NF }'`
        # Check if it is a directory
        # If so, delete files not present in the source
        if [[ -d "$name" ]]
        then
            rsync -rupEShi --delete "${name}" ${index%/*}
        # This is not done for files because all other files in the target directory would be deleted
        else
            rsync -rupEShi "${name}" ${index%/*}
        fi
    done < "index-common"

    # Files specific to this machine (such as system files) should be updated manually
    echo
    echo "NOTE:"
    echo -en "Files specific to this machine must be manually updated"
    echo " (see file index-${thisComputer} and ${thisComputer} directory)"

    echo "Done."
    cd $origDir
}

# Unload and reload Realtek wifi module
reload-wifi()
{
    echo "Unloading module rtl8192se..."
    sudo rmmod rtl8192se
    sleep 5
    echo "Reloading module rtl8192se..."
    sudo modprobe rtl8192se
    echo "Done"
}

# Turn screen off (no lock)
screen-off()
{
    xset dpms force off
}

# Lock and turn off screen
lock()
{
    gnome-screensaver-command -l
    screen-off
}

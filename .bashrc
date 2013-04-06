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

# PATH
# Android tools
export PATH=${PATH}:~/Computer/android-sdk-linux/tools:~/Computer/android-sdk-linux/platform-tools
# RVM
export PATH=${PATH}:${HOME}/.rvm/bin

# Load RVM
source $HOME/.rvm/scripts/rvm

# Aliases
# Show an alert for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
# Connect to MTP device
alias mtp-connect="mtpfs -o allow_other /media/mtp"
alias mtp-disconnect="fusermount -u /media/mtp"
# tar.gz
alias untargz="tar -zxvf"
alias targz="tar -zcvf"
# Easy extract
alias extract="atool -x" # Try ="dtrx" if this doesn't work
# Navigation
alias home="cd ~"
alias docs="cd ~/Documents"
alias school="cd ~/Documents/school"
alias webapps="cd ~/Documents/school/csci446/"
alias db="cd ~/Documents/school/csci403/"
alias os="cd ~/Documents/school/csci442/"
# SSH to toilers.mines.edu in the background
alias toilers-connect="ssh -f -N -L 7777:toilers.mines.edu:22 rimoses@imagine.mines.edu"

# Functions
# Kill the SSH connection to toilers.mines.edu
toilers-disconnect()
{
    pid=`ps aux | grep -F 'ssh -f -N -L 7777:toilers' | grep -v -F 'grep' | awk '{ print $2 }'`
    kill $pid 2>/dev/null
    if [[ $? -ne 0 ]]
    then
        echo "Not connected to Toilers"
    else
        echo "Disconnected"
    fi
}
# Update config files
backupconfig()
{
    backupDir="/home/riley/Computer/backup/config"
    origDir=`pwd`
    cd $backupDir
    # Pull latest changes
    echo "Pulling latest changes..."
    git pull
    echo
    echo "Continue? (y/N)"
    read yn
    case $yn in
        [Yy]*)
            ;;
        *)
            cd $origDir
            return 1
            ;;
    esac
    # Update shared files
    for index in `cat index-common`
    do
        # Overwrite the ones in this directory
        # Delete any files in the target directory that don't exist in the source
        # For example, remove files for any Sublime plugins that have been uninstalled
        rsync --filter='merge rsync_ignore' -rupEShi --delete $index $backupDir
    done
    # Check if there are any files specific to this host
    thisComputer=`hostname`
    dashLoc=`echo $thisComputer | xargs -I {} expr index {} '-'`
    hostDir=${thisComputer:$dashLoc}
    if [[ -f "index-${hostDir}" ]]
    then
        # Create a directory for this host if it doesn't exist
        if [[ ! -d "$hostDir" ]]
        then
            echo "Creating directory '${hostDir}' for this host"
            mkdir $hostDir
        fi
        # Copy the host-specific files to the new directory
        for index in `cat index-${hostDir}`
        do
            rsync -rupEShi --delete $index $hostDir
        done
    fi
    # List the contents of the directory
    echo
    echo "The following will be backed up:"
    tree -a --noreport --dirsfirst -L 2 -I .git $backupDir
    echo
    echo "Continue? (y/N)"
    read yn
    case $yn in
        [Yy]*)
            ;;
        *)
            cd $origDir
            return 1
            ;;
    esac
    # Add/update files
    echo
    git add .
    git add -A
    git status
    echo
    echo "Commit? (y/N)"
    read yn
    case $yn in
        [Yy]*)
            ;;
        *)
            cd $origDir
            return 1
            ;;
    esac
    # Commit
    echo
    echo "Commit message (single line, no surrounding quotes):"
    read commitMsg
    echo
    git commit -m "$commitMsg" | head -n 2
    # Push
    echo
    echo "Pushing..."
    git push
    # Return to original directory
    echo "Done."
    cd $origDir
}
pullconfig()
{
    restoreDir="/home/riley/Computer/backup/config"
    origDir=`pwd`
    cd $restoreDir
    # Pull latest changes
    echo "Pulling latest changes..."
    git pull
    echo
    echo "Apply changes? (y/N)"
    read yn
    case $yn in
        [Yy]*)
            ;;
        *)
            cd $origDir
            return 1
            ;;
    esac
    thisComputer=`hostname`
    dashLoc=`hostname | xargs -I {} expr index {} '-'`
    hostDir=${thisComputer:$dashLoc}
    # Update shared files
    for index in `cat index-common`
    do
        file=`echo $index | awk -F "/" '{ print $NF }'`
        rsync -rupEShi $file ${index%/*}
    done
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
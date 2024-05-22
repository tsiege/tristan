
# gdate for macOS
# REF: https://apple.stackexchange.com/questions/135742/time-in-milliseconds-since-epoch-in-the-terminal
# if [[ "$OSTYPE" == "darwin"* ]]; then
#     {
#         gdate
#     } || {
#         echo "\n$fg_bold[yellow]passsion.zsh-theme depends on cmd [gdate] to get current time in milliseconds$reset_color"
#         echo "$fg_bold[yellow][gdate] is not installed by default in macOS$reset_color"
#         echo "$fg_bold[yellow]to get [gdate] by running:$reset_color"
#         echo "$fg_bold[green]brew install coreutils;$reset_color";
#         echo "$fg_bold[yellow]\nREF: https://github.com/ChesterYue/ohmyzsh-theme-passion#macos\n$reset_color"
#     }
# fi

color_cyan="%{$fg_no_bold[cyan]%}";  # color in PROMPT need format in %{XXX%} which is not same with echo
color_reset="%{$reset_color%}";
reset_font="%{$fg_no_bold[white]%}";

# time
function real_time() {
    local time="[$(date +%H:%M:%S)]";
    echo "${color_cyan}${time}${color_reset}";
}
TIME_CACHE=""
function update_time() {
    TIME_CACHE=$(real_time);
}
update_time
# login_info
function login_info() {
    local ip
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        # Linux
        ip="$(ifconfig | grep ^eth1 -A 1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)";
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        ip="$(ifconfig | grep ^en1 -A 4 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)";
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
    elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
    elif [[ "$OSTYPE" == "win32" ]]; then
        # I'm not sure this can happen.
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        # ...
    else
        # Unknown.
    fi
    echo "${color_cyan}[%n@${ip}]${color_reset}";
}


# directory
function directory() {
    # REF: https://stackoverflow.com/questions/25944006/bash-current-working-directory-with-replacing-path-to-home-folder
    local directory="${PWD/#$HOME/~}";
    echo "${color_cyan}[${directory}]${color_reset}";
}
DIRECTORY=""
function update_directory() {
    DIRECTORY=$(directory);
}
update_directory

# git
function git_dirty_status() {
    [[ $(git status 2> /dev/null | tail -n1) == "nothing to commit, working tree clean" ]] && echo "🌟"
    [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit, working tree clean" ]] && echo "🔥"
}
function git_branch_name() {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/"
}
function git_status() {
    if [ -d ".git" ]; then
        echo "$fg_no_bold[blue]git($fg_no_bold[red]$(git_branch_name) $(git_dirty_status)$fg_no_bold[blue])"
    else
        echo ""
    fi
}
function update_git_status() {
    GIT_STATUS=$(git_status);
}
update_git_status

# command
function update_command_status() {
    COMMAND_RESULT=$1;
    export COMMAND_RESULT=$COMMAND_RESULT
    if $COMMAND_RESULT;
    then
        COMMAND_STATUS="%{$fg_bold[red]%}❱%{$fg_bold[yellow]%}❱%{$fg_bold[green]%}❱${reset_font}${color_reset}";
    else
        COMMAND_STATUS="%{$fg_bold[red]%}❱❱❱${reset_font}${color_reset}";
    fi
}
update_command_status true;

function command_status() {
    echo "${COMMAND_STATUS}"
}


# output command execute after
# output_command_execute_after() {
#     if [ "$COMMAND_TIME_BEIGIN" = "-20200325" ] || [ "$COMMAND_TIME_BEIGIN" = "" ];
#     then
#         return 1;
#     fi

#     # cmd
#     local cmd="${$(fc -l | tail -1)#*  }";
#     local color_cmd="";
#     if $1;
#     then
#         color_cmd="$fg_no_bold[green]";
#     else
#         color_cmd="$fg_bold[red]";
#     fi
#     local color_reset="$reset_color";
#     cmd="${color_cmd}${cmd}${color_reset}"

#     # time
#     local time="[$(date +%H:%M:%S)]"
#     local color_time="$fg_no_bold[cyan]";
#     time="${color_time}${time}${color_reset}";

#     # cost
#     # local time_end="$(current_time_millis)";
#     # local cost=$(bc -l <<<"${time_end}-${COMMAND_TIME_BEIGIN}");
#     COMMAND_TIME_BEIGIN="-20200325"
#     local length_cost=${#cost};
#     if [ "$length_cost" = "4" ];
#     then
#         cost="0${cost}"
#     fi
#     cost="[cost ${cost}s]"
#     local color_cost="$fg_no_bold[cyan]";
#     cost="${color_cost}${cost}${color_reset}";

#     echo -e "${time} ${cost} ${cmd}";
#     echo -e "";
# }


# command run before execute
# REF: http://zsh.sourceforge.net/Doc/Release/Functions.html
# preexec() {
# }

# command run after execute and before printing a new prompt
# REF: http://zsh.sourceforge.net/Doc/Release/Functions.html
precmd() {
    update_command_status;
    update_directory;
    update_git_status;
    update_time;
    update_prompt;
}


# set option
setopt PROMPT_SUBST;


# # timer
# #REF: https://stackoverflow.com/questions/26526175/zsh-menu-completion-causes-problems-after-zle-reset-prompt
# TMOUT=1;
# TRAPALRM() {
#     # $(git_prompt_info) cost too much time which will raise stutters when inputting. so we need to disable it in this occurence.
#     # if [ "$WIDGET" != "expand-or-complete" ] && [ "$WIDGET" != "self-insert" ] && [ "$WIDGET" != "backward-delete-char" ]; then
#     # black list will not enum it completely. even some pipe broken will appear.
#     # so we just put a white list here.
#     if [ "$WIDGET" = "" ] || [ "$WIDGET" = "accept-line" ] ; then
#         zle reset-prompt;
#     fi
# }


# prompt
headline_output() {
  echo -e "$TIME_CACHE $DIRECTORY $GIT_STATUS\n⏣ ⌬ $COMMAND_STATUS "
}
function update_prompt() {
    PROMPT="$(headline_output)";
}
update_prompt


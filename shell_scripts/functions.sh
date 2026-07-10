# Prompt Functions
#============================
function git_in_repo {
  git rev-parse --is-inside-work-tree &>/dev/null
}

function git_branch_name {
  git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

function git_dirty_status {
  if [[ -n $(git status --porcelain -uno 2>/dev/null) ]]; then
    echo "✗"
  else
    echo "✓"
  fi
}

function git_worktree_tag {
  local gitdir commondir
  gitdir=$(git rev-parse --absolute-git-dir 2>/dev/null) || return
  commondir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return
  [[ $gitdir != "$commondir" ]] && echo "WT: "
}

function print_branch_name_and_status {
  git_in_repo || return
  echo "($(git_worktree_tag)$(git_branch_name) $(git_dirty_status))"
}

function prompt {
  local RED="\[\033[0;31m\]"
  local CHAR="⏣ ⌬ "

  export PS1="\[\e]2;\u@\h\a[\t\[\e[0m\]] \[\e[32m\]\W\[\e[0m\]$RED \$(print_branch_name_and_status)\n\[\e[0;31m\]$CHAR \[\e[0m\]"
         PS2='> '
         PS4='+ '
}

# Helpful Functions
# =====================
function desktop {
  cd /Users/$USER/Desktop/$@
}

# A function to easily grep for a matching process
# USE: psg postgres
function psg {
  FIRST=`echo $1 | sed -e 's/^\(.\).*/\1/'`
  REST=`echo $1 | sed -e 's/^.\(.*\)/\1/'`
  ps aux | grep "[$FIRST]$REST"
}

# A function to extract correctly any archive based on extension
# USE: extract imazip.zip
#      extract imatar.tar
function extract () {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)  tar xjf $1    ;;
      *.tar.gz)   tar xzf $1    ;;
      *.bz2)      bunzip2 $1    ;;
      *.rar)      rar x $1      ;;
      *.gz)       gunzip $1     ;;
      *.tar)      tar xf $1     ;;
      *.tbz2)     tar xjf $1    ;;
      *.tgz)      tar xzf $1    ;;
      *.zip)      unzip $1      ;;
      *.Z)        uncompress $1 ;;
      *)          echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
      echo "'$1' is not a valid file"
  fi
}

function nom () {
  if [[ -f ./package.json ]]; then
    rm -rf ./node_modules/
    npm cache clean
    npm install
  else
    echo "no package.json present"
  fi
}

# AWS MFA / Temp credential helpers
function clear_sts_creds () {
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

function refresh_sts_creds () {
  # check to see if MFA_SERIAL is set
  if [ "$MFA_SERIAL" = "" ] ; then
    echo "MFA_SERIAL not set"
    return 2
  fi

  # check to see if credentials for today exist
  # override with force if necessary
  # if they do source them and exit
  TMP_CRED_FILE_PATH="/tmp/sts-creds-`date +%m-%d-%Y`.sh"
  if [ "$1" != "--force" ] && [ "$1" != "-f" ] && [ -e "/tmp/sts-creds-`date +%m-%d-%Y`.sh" ] ; then
    echo "using existing credentials, to override run \"refresh_sts_creds --force\""
    source $TMP_CRED_FILE_PATH
    return 0
  fi

  clear_sts_creds # You can't use tokens to get tokens, so start clean

  echo -n "MFA Code: "
  read MFA_TOKEN

  # trim white space
  MFA_TOKEN="$(echo -e "${MFA_TOKEN}" | tr -d '[:space:]')"

  # get credientials from AWS that last one day
  CREDS=$(aws sts get-session-token --duration-seconds 86400 --serial-number $MFA_SERIAL --token-code $MFA_TOKEN \
            --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]')

  unset MFA_TOKEN
  # set credientials for window
  if [ $? -eq 0 ] ; then
    AWS_ACCESS_KEY_ID=$(echo "$CREDS" | awk '{print $1}')
    AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | awk '{print $2}')
    AWS_SESSION_TOKEN=$(echo "$CREDS" | awk '{print $3}')
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  # store credentials in /tmp for other windows to access
    printf "export AWS_ACCESS_KEY_ID=\"${AWS_ACCESS_KEY_ID}\"
export AWS_SECRET_ACCESS_KEY=\"${AWS_SECRET_ACCESS_KEY}\"
export AWS_SESSION_TOKEN=\"${AWS_SESSION_TOKEN}\"
" > $TMP_CRED_FILE_PATH
  fi
  unset CREDS

  return 0
}

#Git functions
function gcom () {
  git show-ref --verify --quiet refs/heads/main && git co main || git co master
}

function git_remove_merged_branches() {
  local protected_branches="^(main|master|dev|develop|development|staging|prod|production)$"
  local current_branch default_branch pr_number
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  default_branch=$(git show-ref --verify --quiet refs/heads/main && echo main || echo master)

  for branch in $(git branch --format='%(refname:short)'); do
    # Skip protected branches and the checked-out branch
    if echo "$branch" | grep -qE "$protected_branches" || [ "$branch" = "$current_branch" ]; then
      continue
    fi

    # Merged via a real merge commit — no API call needed
    if git merge-base --is-ancestor "$branch" "$default_branch"; then
      git branch -D "$branch"
      continue
    fi

    # Squash/rebase merges leave no ancestry; ask GitHub for a merged PR
    if ! pr_number=$(gh pr list --state merged --head "$branch" --json number --jq '.[0].number' 2>&1); then
      echo "skipping $branch: gh failed: $pr_number" >&2
      continue
    fi
    if [ -n "$pr_number" ]; then
      git branch -D "$branch"
    fi
  done
}

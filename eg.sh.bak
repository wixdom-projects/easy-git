#!/bin/bash
export http_proxy=''
export https_proxy=$http_proxy

DATE=`date +%Y%m%d%H%M%S`
MYDEV=dev/user
DEV=develop
REMOTE=origin
TEMP=$MYDEV-temp

# merge $1 to $2
function gitMerge {
    local sourceNotExist
    if [[ $1 = $TEMP ]]; then
        git show-ref --verify --quiet refs/heads/$1
        if [[ $? -eq 0 ]]; then
            git checkout $1 --quiet
            sourceNotExist=$?
        else
            sourceNotExist=1
        fi
    else
        git show-ref --verify --quiet refs/remotes/$REMOTE/$1
        if [[ $? -eq 0 ]]; then
            git checkout $1 --quiet
            if [[ $? -ne 0 ]]; then exit; fi
            if [[ $(git rev-parse @) != $(git rev-parse $REMOTE/$1)
                && $(git rev-parse $REMOTE/$1) != $(git merge-base @ $REMOTE/$1) ]]; then
                git pull --quiet
                if [[ $? -ne 0 ]]; then exit; fi
                git submodule update --init --quiet
                if [[ $? -ne 0 ]]; then exit; fi
            fi
            sourceNotExist=$?
        else
            sourceNotExist=1
        fi
    fi
    git show-ref --verify --quiet refs/remotes/$REMOTE/$2
    if [[ $? -ne 0 ]]; then
        git checkout -b $2 --quiet
        if [[ $? -ne 0 ]]; then exit; fi
        git push --set-upstream $REMOTE $2 --quiet
        if [[ $? -ne 0 ]]; then exit; fi
    else
        git checkout $2 --quiet
        if [[ $? -ne 0 ]]; then exit; fi
        if [[ $(git rev-parse @) != $(git rev-parse $REMOTE/$2)
            && $(git rev-parse $REMOTE/$2) != $(git merge-base @ $REMOTE/$2) ]]; then
            git pull --quiet
            if [[ $? -ne 0 ]]; then exit; fi
            git submodule update --init --quiet
            if [[ $? -ne 0 ]]; then exit; fi
        fi
        if [[ $sourceNotExist -eq 0 ]]; then
            git merge --message "merge at $DATE by $MYDEV" $1 --quiet
            if [[ $? -ne 0 ]]; then exit; fi
            if [[ $3 = "--push=no" ]]; then return; fi
            git push --quiet
            if [[ $? -ne 0 ]]; then exit; fi
        fi
    fi
}

function iterateSubmodules {
    local submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')
    for submodule in $submodules
    do
        cd $submodule
        if [[ $? -ne 0 ]]; then
            exit
            # need to remove submodule
        else
            eval $1
            cd ..
        fi
    done
}

function gitCommit {
    iterateSubmodules "gitCommit"
    git add --all
    diff=$(git diff HEAD)
    if [[ -z $diff ]]; then return; fi
    if [[ $1 != "--fetch==no" ]]; then
        git fetch --recurse-submodules=no $REMOTE --quiet
        if [[ $? -ne 0 ]]; then exit; fi
    fi
    git checkout -B $TEMP --quiet
    if [[ $? -ne 0 ]]; then exit; fi
    git add --all
    git commit --all --message "Update at $DATE by $MYDEV" --quiet
    if [[ $? -ne 0 ]]; then exit; fi
    return
}

function gitMergePush {
    iterateSubmodules "gitMergePush"
    gitCommit --fetch=no
    gitMerge $TEMP $MYDEV --push=no
    if [[ $? -ne 0 ]]; then exit; fi
    gitMerge $MYDEV $DEV
    if [[ $? -ne 0 ]]; then exit; fi
    gitMerge $DEV $MYDEV
    if [[ $? -ne 0 ]]; then exit; fi
    git show-ref --verify --quiet refs/heads/$TEMP
    if [[ $? -ne 0 ]]; then return; fi
    git branch -D $TEMP --quiet
}

function gitPullMerge {
    gitMerge $DEV $MYDEV
    git submodule update --init --quiet
    iterateSubmodules "gitPullMerge"
}

git fetch --recurse-submodules=no $REMOTE --quiet
if [[ $? -ne 0 ]]; then exit; fi
git add --all
diff=$(git diff HEAD)
if [[ -z $diff ]]; then
    gitPullMerge
else
    gitCommit
    gitMergePush
fi

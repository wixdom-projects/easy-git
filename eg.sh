#!/bin/bash
export http_proxy=''
export https_proxy=$http_proxy

DATE=`date +%Y%m%d%H%M%S`
MYDEV=dev/test
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
        git show-ref --verify --quiet refs/remotes/origin/$1
        if [[ $? -eq 0 ]]; then
            git checkout $1 --quiet
            git pull --quiet
            sourceNotExist=$?
        else
            sourceNotExist=1
        fi
    fi
    git show-ref --verify --quiet refs/remotes/origin/$2
    if [[ $? -ne 0 ]]; then
        git checkout -b $2 --quiet
        if [[ $? -ne 0 ]]; then exit; fi
        git push --set-upstream origin $2 --quiet
        if [[ $? -ne 0 ]]; then exit; fi
    else
        git checkout $2 --quiet
        if [[ $? -ne 0 ]]; then exit; fi
        git pull --quiet
        if [[ $? -ne 0 ]]; then exit; fi
        if [[ $sourceNotExist -eq 0 ]]; then
            git merge --message "merge at $DATE by $MYDEV" $1 --quiet
            if [[ $? -ne 0 ]]; then exit; fi
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
        eval $1
        cd ..
    done
}

function gitCommit {
    iterateSubmodules "gitCommit"
    diff=$(git diff HEAD)
    if [[ -z $diff ]]; then return; fi
    git fetch --recurse-submodules=no $REMOTE --quiet
    if [[ $? -ne 0 ]]; then exit; fi
    git checkout -B $TEMP --quiet
    if [[ $? -ne 0 ]]; then exit; fi
    git commit --all --message "Update at $DATE by $MYDEV" --quiet
    if [[ $? -ne 0 ]]; then exit; fi
    return
}

function gitMergePush {
    iterateSubmodules "gitMergePush"
    gitCommit
    gitMerge $TEMP $MYDEV
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
diff=$(git diff HEAD)
if [[ -z $diff ]]; then
    gitPullMerge
else
    gitCommit
    gitMergePush
fi
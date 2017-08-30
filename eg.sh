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
    if [[ $1 = $TEMP ]]; then
        git show-ref --verify --quiet refs/heads/$1
        if [[ $? -eq 0 ]]; then
            git checkout $1 --quiet
        fi
    else
        git show-ref --verify --quiet refs/remotes/origin/$1
        if [[ $? -eq 0 ]]; then
            git checkout $1 --quiet
            git pull --quiet
        fi
    fi
    local sourceNotExist=$?

    git show-ref --verify --quiet refs/remotes/origin/$2
    if [[ $? -ne 0 ]]; then
        git checkout -b $2 --quiet
        git push --set-upstream origin $2 --quiet
        if [[ $? -ne 0 ]]; then return 1; fi
    else
        git checkout $2 --quiet
        git pull --quiet
        if [[ sourceNotExist -eq 0 ]]; then
            git merge --message "merge at $DATE by $MYDEV" $1 --quiet
            if [[ $? -ne 0 ]]; then return 1; fi
            git push --quiet
            if [[ $? -ne 0 ]]; then return 1; fi
        fi
    fi
    return 0
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

function gitCommitPush {
    iterateSubmodules "gitCommitPush"
    #sync remote branches
    git fetch --recurse-submodules=no $REMOTE --quiet
    if [[ $? -ne 0 ]]; then exit; fi
    diff=$(git diff HEAD)
    if [[ -z $diff ]]; then return; fi
    git checkout -B $TEMP --quiet
    git commit --all --message "Update at $DATE by $MYDEV" --quiet
    if [[ $? -ne 0 ]]; then exit; fi
    gitMerge $TEMP $MYDEV
    if [[ $? -ne 0 ]]; then exit; fi
    gitMerge $MYDEV $DEV
    if [[ $? -ne 0 ]]; then exit; fi
    gitMerge $DEV $MYDEV
    git branch -D $TEMP --quiet
}

cd /Users/hnery/test-temp/test-c

git fetch --recurse-submodules=no $REMOTE --quiet
if [[ $? -ne 0 ]]; then exit; fi
diff=$(git diff HEAD)
if [[ -z $diff ]]; then
    gitMerge $DEV $MYDEV
    git submodule update --init --recursive --quiet
else
    gitCommitPush
fi

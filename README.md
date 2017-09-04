# easy-git
use git with just one command(eg)

support submodules

## procedures below

if working tree is clean
* pull `develop` branch from remote
* merge `develop` branch to `dev/{user}` branch, exit if conflict exist
* initialize all submodules

else
* commit current working tree to a `dev/{user}-temp` branch if working tree is different from the head

end if

* merge `dev/{user}-temp` branch to `dev/{user}` branch, exit if conflict exist
* merge `dev/{user}` branch to `develop` branch
* merge `develop` branch to `dev/{user}` branch
* delete `dev/{user}-temp` branch

## installation
just copy eg.sh to `{user home}\bin`

## usage
execute eg at the git repository path
restapiurl="root url/rest/api/1.0/projects/UC/repos"
lockrestapiurl="root url/rest/branch-permissions/2.0/projects/UC/repos"

varlist1 ()
{
newbranchname="sprint-20-15"
frombranchName="sprint-20-14"
tobranchName="master"
}

varlist2 ()
{
newbranchname="sprint-20-15-$arg2"
frombranchName="sprint-20-14-$arg2"
tobranchName="integrated-$arg2"
}


reponame=$1
arg2=$2
if [[ test-repo-by-venu == $reponame ]]
then
varlist2
elif [[ svc-invoice-storage == $reponame ]]
then
varlist2
else
varlist1
fi

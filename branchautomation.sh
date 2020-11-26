#!/bin/bash

CreatePullRequest()
{
#define pull request creation from sprint banch to master branch

echo "Pull request is being created..................!"

HTTPstatus1=`curl -H "Authorization: Bearer ${authtoken}" -o -sL -w "%{http_code}" -H "Content-Type: application/json" ${restapiurl}/${planRepositoryname}/pull-requests -X POST --data '{"title":"merging to master branch","description":"merging to master","fromRef":{"id":"'"refs/heads/${frombranchName}"'","repository":{"slug":"'"${planRepositoryname}"'","name":null,"project":{"key":"UC"}}},"toRef":{"id":"'"refs/heads/${tobranchName}"'","repository":{"slug":"'"${planRepositoryname}"'","name":null,"project":{"key":"UC"}}}}'`

        if [ "${HTTPstatus1}" == "201" ]
		then
			echo "Pull Request is sucessfully created for ${planRepositoryname}.................................................!"
			GetPullRequest
			ApprovePullRequest
			LockBranch
			NewBranchName
			DefaultBranch
		elif [ "${HTTPstatus1}" == "409" ]
		then
			echo "${frombranchName} is already uptodate with master branch, no pull request required for ${planRepositoryname} repository................................!"
			LockBranch
			NewBranchName
			DefaultBranch
		else
			echo "${planRepositoryname} REST API has errors and cannot be executed. please do this task from Bitbucket UI"
		fi
}

GetPullRequest()
{
echo "Fetching pull request ID ..................!"
curl -H "Authorization: Bearer ${authtoken}" ${restapiurl}/${planRepositoryname}/pull-requests >file
#PullRequestID=`cat file | jq '.values' | head -n 3 | tail -n 1 | tr -d " \t\n\r" | cut -b 6,7`
#Modified by Suresh
PullRequestID=`cat file | jq '.values' | head -n 3 | tail -n 1 | tr -d " \t\n\r" | cut -d : -f 2 | cut -d , -f 1`
echo "PullRequestID= ${PullRequestID}................................................!"
}


ApprovePullRequest()
{
#Pull request approve REST API for approve the request

echo "Pull request is being approved ..................!"

HTTPstatus2=`curl -H "Content-Type:application/json" -o -sL -w "%{http_code}" -H "Accept:application/json" -H "Authorization: Bearer ${authtoken}" -X POST ${restapiurl}/${planRepositoryname}/pull-requests/${PullRequestID}/merge?version=0`
		status=`echo $?`
        if [ "${HTTPstatus2}" == "200" ]
		then
			echo "Pull request is sucessfully approved for ${planRepositoryname}................................................!"
		else
			echo "Pull request could not be approved for ${planRepositoryname}. check the Below HTTPS respose code for more information "
			echo  HTTPS RESPONSE CODE $HTTPstatus2
		fi

}

LockBranch()
{
#Lock sprint current sprint branch
echo "Sprint Branch is being locked ..................!"

HTTPstatus3=`curl -H "Authorization: Bearer ${authtoken}" -o -sL -w "%{http_code}" -H "Content-Type: application/json" ${lockrestapiurl}/${planRepositoryname}/restrictions -X POST --data '{"type":"read-only","matcher":{"id":"'"refs/heads/${frombranchName}"'","displayId":"'"${frombranchName}"'","type":{"id":"BRANCH","name":"null"},"active":true}}'`


        if [ "${HTTPstatus3}" == "200" ]
		then
			echo "${frombranchName} is sucessfully locked ${planRepositoryname}"
		elif [ "${HTTPstatus1}" == "409" ]
		then
			echo "sprint branch is already locked for ${planRepositoryname}..................................!"
		else
			echo "${planRepositoryname} REST API errors and cannot be executed. please do this task from Bitbucket UI"
		fi
}

NewBranchName()
{		
#new sprint branch name from argument

if [ -z "${newbranchname}" ]
then
	echo "newbranchname input value is empty.. please provide name of the branch.........!"
	exit 2
else
	echo "new branch name is ${newbranchname}...."
fi

#define next sprint branch creation

echo "${newbranchname} is being created.......................!"

HTTPstatus4=`curl -H "Authorization: Bearer ${authtoken}" -o -sL -w "%{http_code}" -H "Content-Type:application/json" ${restapiurl}/${planRepositoryname}/branches -X POST --data '{"name": "'"${newbranchname}"'","startPoint": "'"refs/heads/$tobranchName"'"}'`
		status=`echo $?`
        if [ "${HTTPstatus4}" == "200" ]
		then
			echo "${newbranchname} new sprint branch is sucessfully created for ${planRepositoryname}.................................!"
            DefaultBranch
		elif [ "${HTTPstatus4}" == "409" ]
		then
			echo "${newbranchname} is already exist for ${planRepositoryname}............................................!"
			echo "please verify branch name updated or not in the variablesdecleration file.................................!"
		else
			echo "new sprint branch could not be created for ${planRepositoryname}..................!"
		fi
}

DefaultBranch()
{		

#define updating new branch as default

echo "${newbranchname} is being updating as default to clone.......................!"

HTTPstatus5=`curl -H "Authorization: Bearer ${authtoken}" -o -sL -w "%{http_code}" -H "Content-Type:application/json" ${restapiurl}/${planRepositoryname}/branches/default -X PUT --data '{"id": "'"refs/heads/${newbranchname}"'"}'`
		status=`echo $?`
        if [ "${HTTPstatus5}" == "204" ]
		then
			echo "${newbranchname} new sprint branch is sucessfully updated as a default branch.................................!"
		else
			echo "new sprint branch could not be updated as default branch for ${planRepositoryname}..................!"
			echo "please updated the default branch for ${planRepositoryname} from Bitbucket UI..................!"
		fi
}

MyArray=("test-repo-by-venu" "svc-invoice-storage" );

Totalrepositories=`cat -n repositorynames.sh | tail -n 1 | cut -f1`
echo total number of repositories mentioned in the repositorynames file is $Totalrepositories

		while IFS="" read -r p || [ -n "$p" ]
		do
		  planRepositoryname=`printf '%s\n' "$p"`
		
			FINDME=$planRepositoryname
			FOUND=`echo ${MyArray[*]} | grep $FINDME`
			if [ "${FOUND}" != "" ]; 
			then
			  echo Array contains: $FINDME
			  endword=(sit at)
				for u in "${endword[@]}"
				do
                    source variablesdecleration.sh $planRepositoryname $u
                    echo $u
                    echo $newbranchname
                    echo $tobranchName
                    
					LockBranch
					NewBranchName
					DefaultBranch
				done 
			else
			  source variablesdecleration.sh $planRepositoryname
			  CreatePullRequest
			fi
		  
		done < repositorynames.sh
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"     
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!------------PLEASE VERIFY EACH MICRO SERVICES NAME IN THE ABOVE LOGS CAREFULLY--------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!------------TO AVOID THE AUTOMATION ERRORS-------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

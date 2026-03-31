#!/bin/bash

export FRAMEWORK_ROOT_DIR=$(pwd)

# check requirements
echo -e "Task:\tChecking Dependencies"
$FRAMEWORK_ROOT_DIR/bin/check-requirements.sh $FRAMEWORK_ROOT_DIR

if [ $? -eq 0 ]; then
	echo -e "Result:\tDone!"
else
	echo -e "Result:\tFailed!"
	exit 1
fi

echo ""

# check infra components
INFRA_PROXY=$(grep -E '^proxy=' $FRAMEWORK_ROOT_DIR/data/infra | cut -d '=' -f 2)
echo -e "Task:\tChecking Infra Proxy"

if [[ -z $INFRA_PROXY || ! -d $FRAMEWORK_ROOT_DIR/infra/proxy/$INFRA_PROXY ]]; then
	echo "[error] infra proxy missing: $INFRA_PROXY"
	echo -e "Result:\tFailed!"
	exit 1
else
	echo -e "Result:\tDone!"
fi

echo ""

# check projects
echo -e "Task:\tChecking Projects"
INVALID_PROJECTS_COUNT=0
VALID_PROJECTS_TO_ADD=()
VALID_PROJECTS_TO_RUN=()
while read -r PROJECT_ENTRY; do
	DOMAIN=$(echo $PROJECT_ENTRY | cut -d ':' -f 1)
	PROJECT_NAME=$(echo $PROJECT_ENTRY | cut -d ':' -f 2)
	USER_NAME=$(echo $PROJECT_ENTRY | cut -d ':' -f 3)
	GROUP_NAME=$(echo $PROJECT_ENTRY | cut -d ':' -f 4)
	
	# domain file
	DOMAIN_FILE_EXISTS=0
	PROJECT_DIR_EXISTS=0
	USER_NAME_EXISTS=0
	GROUP_NAME_EXISTS=0
	PROJECT_WWW_EXISTS=0	
	
	# domain
	if [[ ! -z "$DOMAIN" && -f $FRAMEWORK_ROOT_DIR/infra/proxy/$INFRA_PROXY/$INFRA_PROXY/conf.d/$DOMAIN.conf ]]; then
		DOMAIN_FILE_EXISTS=1
	fi

	# dir		
	if [[ ! -z "$PROJECT_NAME" && -d $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME  ]]; then
		PROJECT_DIR_EXISTS=1	
	fi

	# user
	if [[ ! -z "$USER_NAME" && $(getent passwd $USER_NAME) ]]; then
		USER_NAME_EXISTS=1
	fi	

	# group
	if [[ ! -z "$GROUP_NAME" && $(getent group $GROUP_NAME) ]]; then
		GROUP_NAME_EXISTS=1
	fi	

	# www		
	if sudo [ -d /var/www/$PROJECT_NAME ]; then
		PROJECT_WWW_EXISTS=1	
	fi

	if [[ "$DOMAIN_FILE_EXISTS" == "1" && "$PROJECT_DIR_EXISTS" == "1" && "$USER_NAME_EXISTS" == "1" && "$GROUP_NAME_EXISTS" == "1" && "$PROJECT_WWW_EXISTS" == "1" ]]; then
		VALID_PROJECTS_TO_RUN+=("$PROJECT_NAME")
	elif [[ "$DOMAIN_FILE_EXISTS" == "0" && "$PROJECT_DIR_EXISTS" == "0" && "$USER_NAME_EXISTS" == "0" && "$GROUP_NAME_EXISTS" == "0" && "$PROJECT_WWW_EXISTS" == "0" ]]; then
		VALID_PROJECTS_TO_ADD+=("$PROJECT_NAME")
	else
		INVALID_PROJECTS_COUNT=$(( $INVALID_PROJECTS_COUNT + 1 ))
	fi

	# --- testing
	#echo 'DOMAIN' "$DOMAIN"
	#echo 'DOMAIN_FILE_EXISTS' "$DOMAIN_FILE_EXISTS"
	#echo 'PROJECT_DIR_EXISTS' "$PROJECT_DIR_EXISTS"
	#echo 'USER_NAME_EXISTS' "$USER_NAME_EXISTS"
	#echo 'GROUP_NAME_EXISTS' "$GROUP_NAME_EXISTS"
	#echo 'WWW_EXISTS' "$PROJECT_WWW_EXISTS"
	#echo
	#echo "add: ${VALID_PROJECTS_TO_ADD[@]}"
	#echo "run: ${VALID_PROJECTS_TO_RUN[@]}"

done < $FRAMEWORK_ROOT_DIR/data/project

echo -e "- Addable: ${#VALID_PROJECTS_TO_ADD[@]}"
echo -e "- Runnable: ${#VALID_PROJECTS_TO_RUN[@]}"
echo -e "- Invalid: ${INVALID_PROJECTS_COUNT}"

echo -e "Result:\tDone!"

echo ""

# run projects
echo -e "Task:\tRunning Projects"

if [[ ${#VALID_PROJECTS_TO_RUN[@]} -gt 0 ]]; then
	for PROJECT_NAME in "${VALID_PROJECTS_TO_RUN[@]}"; do
		if $(docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml up -d); then
			echo "- Project up: $PROJECT_NAME"
		else
			echo "- Project down: $PROJECT_NAME"
		fi
	done
else
	echo -e "- Runnable Projects: ${#VALID_PROJECTS_TO_RUN[@]}"
fi
	
echo -e "Result:\tDone!"
 
echo ""

# add projects
echo -e "Task:\tAdding Projects"

if [[ ${#VALID_PROJECTS_TO_ADD[@]} -gt 0 ]]; then
	echo -e "- Addable Projects: ${#VALID_PROJECTS_TO_ADD[@]}"

	for PROJECT_NAME in "${VALID_PROJECTS_TO_ADD[@]}"; do
		echo "- Adding: 'domain: $DOMAIN' 'project:$PROJECT_NAME'"
		$FRAMEWORK_ROOT_DIR/project.sh add $DOMAIN
	done

else
	echo -e "- Addable Projects: ${#VALID_PROJECTS_TO_ADD[@]}"
fi
	
echo -e "Result:\tDone!"
 
echo ""

# run proxy
echo -e "Task:\tRunning Proxy"

docker compose -f $FRAMEWORK_ROOT_DIR/infra/proxy/nginx/docker-compose.yml up -d
if [[ $? -eq 0 ]]; then
	echo "[done] proxy server is up"
else
	echo "[error] proxy server failed to run"
fi

echo -e "Result:\tDone!"

echo ""

#!/bin/bash

if [ -z "$FRAMEWORK_ROOT_DIR" ];then
	export FRAMEWORK_ROOT_DIR=$(pwd)
fi

PARAM_ACTION=$1
PARAM_DOMAIN=$2

VALID_ACTIIONS=('add' 'rm' 'up' 'down' 'restart')
IS_ACTION_VALID=0

# action
if [[ -z $PARAM_ACTION ]]; then
	echo -e "[error] add-project.sh: action argument empty '$PARAM_ACTION'"
	exit 1
fi

for VALID_ACTION in "${VALID_ACTIIONS[@]}"; do
	if [[ "$VALID_ACTION" == "$PARAM_ACTION" ]]; then
		IS_ACTION_VALID=1
		break
	fi
done

if [[ "$IS_ACTION_VALID" != "1" ]]; then
	echo -e "[error] add-project.sh: action argument invalid '$PARAM_ACTION'"
        exit 1	
fi

# domain
if [[ -z "$PARAM_DOMAIN" ]]; then
        echo -e "[error] add-project.sh: domain argument empty '$PARAM_DOMAIN'"
        exit 1
fi

# run project
#if [[ "$PARAM_ACTION" == "run" ]]; then
#        $FRAMEWORK_ROOT_DIR/bin/project-run.sh $PARAM_DOMAIN
#fi

# add project
if [[ "$PARAM_ACTION" == "add" ]]; then
	$FRAMEWORK_ROOT_DIR/bin/project-add.sh $PARAM_DOMAIN
fi

# project down
if [[ "$PARAM_ACTION" == "down" ]]; then
	
	# all projects
	if [[ "$PARAM_DOMAIN" == "all" ]]; then
		# get all projects
		ALL_PRJOECT_NAMES=$(cat $FRAMEWORK_ROOT_DIR/data/project | cut -d ':' -f 2)
		# take each one down
		for PROJECT_NAME in $ALL_PRJOECT_NAMES; do
			if [[ ! $(docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml down) ]]; then
				echo -e "[done]: Project '$PROJECT_NAME' down"
			fi
		done
		exit
	fi

	# get project name
	PROJECT_NAME=$(grep -E "^$PARAM_DOMAIN:" $FRAMEWORK_ROOT_DIR/data/project | cut -d ':' -f 2)
	if [[ -z "$PROJECT_NAME" ]]; then
		echo -e "[error]: project name invalid in ./data/project '$PROJECT_NAME'"
        	exit 1
	fi
	# take it down
	docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml down
	if [[ $? -eq 0 ]]; then
		echo -e "[done]: Project '$PROJECT_NAME' down"
	else
		echo -e "[error]: Project '$PROJECT_NAME' not down"
		exit 1
	fi
fi

# project up
if [[ "$PARAM_ACTION" == "up" ]]; then
        # all projects
        if [[ "$PARAM_DOMAIN" == "all" ]]; then
                # get all projects
                ALL_PRJOECT_NAMES=$(cat $FRAMEWORK_ROOT_DIR/data/project | cut -d ':' -f 2)
                # take each one up
                for PROJECT_NAME in $ALL_PRJOECT_NAMES; do
                        if [[ ! $(docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml up -d) ]]; then
                                echo -e "[done]: Project '$PROJECT_NAME' up"
                        fi
                done
		exit 0
        fi

	# get project name
        PROJECT_NAME=$(grep -E "^$PARAM_DOMAIN:" $FRAMEWORK_ROOT_DIR/data/project | cut -d ':' -f 2)
        if [[ -z "$PROJECT_NAME" ]]; then
                echo -e "[error]: project name invalid in ./data/project '$PROJECT_NAME'"
                exit 1
        fi
        # take it up
        docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml up -d
        if [[ $? -eq 0 ]]; then
                echo -e "[done]: Project '$PROJECT_NAME' up"
        else
                echo -e "[error]: Project '$PROJECT_NAME' not up"
                exit 1
        fi
fi


# project restart
if [[ "$PARAM_ACTION" == "restart" ]]; then
	# all projects
        if [[ "$PARAM_DOMAIN" == "all" ]]; then
                # get all projects
                ALL_PRJOECT_NAMES=$(cat $FRAMEWORK_ROOT_DIR/data/project | cut -d ':' -f 2)
                # take each one up
                for PROJECT_NAME in $ALL_PRJOECT_NAMES; do
                        if [[ ! $(docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml restart) ]]; then
                                echo -e "[done]: Project '$PROJECT_NAME' restarted"
                        fi
                done
                exit 0
        fi

        # get project name
        PROJECT_NAME=$(grep -E "^$PARAM_DOMAIN:" $FRAMEWORK_ROOT_DIR/data/project | cut -d ':' -f 2)
        if [[ -z "$PROJECT_NAME" ]]; then
                echo -e "[error]: project name invalid in ./data/project '$PROJECT_NAME'"
                exit 1
        fi
	
	# container's up?
	if [[ ! $(docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml ps | grep -E "$PROJECT_NAME") ]]; then
		echo -e "[error]: Project '$PROJECT_NAME' is not up to restart"
		exit 1
	fi
        
	# restart
        docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml restart
        if [[ $? -eq 0 ]]; then
                echo -e "[done]: Project '$PROJECT_NAME' restarted"
        else
                echo -e "[error]: Project '$PROJECT_NAME' not restarted"
                exit 1
        fi
fi

# project remove
if [[ "$PARAM_ACTION" == "rm" ]]; then
        # get project name
        PROJECT_NAME=$(grep -E "^$PARAM_DOMAIN:" $FRAMEWORK_ROOT_DIR/data/project | cut -d ':' -f 2)
        if [[ -z "$PROJECT_NAME" ]]; then
                echo -e "[error]: project name invalid in ./data/project '$PROJECT_NAME'"
                exit 1
        fi

        # project down
	if docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml down; then
                echo -e "[done]: Project '$PROJECT_NAME' is down"
	fi

	# rm $DOMAIN.conf
	if rm -f $FRAMEWORK_ROOT_DIR/infra/proxy/nginx/nginx/conf.d/$PARAM_DOMAIN.conf; then
		echo -e "[done]: Domain file removed: '$FRAMEWORK_ROOT_DIR/infra/proxy/nginx/nginx/conf.d/$PARAM_DOMAIN.conf'"
	else
		echo -e "[error]: Domain file not removed: '$FRAMEWORK_ROOT_DIR/infra/proxy/nginx/nginx/conf.d/$PARAM_DOMAIN.conf'"
	fi

	# rm ./project/$PROJECT_NAME
	if rm -fr $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/; then
		echo -e "[done]: Project dir removed: '$FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/'"
	else
		echo -e "[error]: Project dir not removed: '$FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/'"
	fi

	# rm project entry
	if sed -i "/^$PARAM_DOMAIN:/d" $FRAMEWORK_ROOT_DIR/data/project; then
		echo -e "[done]: Project entry removed from: '$FRAMEWORK_ROOT_DIR/data/project'"
	else
		echo -e "[error]: Project entry not removed from: '$FRAMEWORK_ROOT_DIR/data/project'"
	fi

	# restart proxy 
	if docker exec global-proxy-nginx -s reload; then
		echo -e "[done]: Proxy Nginx reloaded"
	else
		echo -e "[error]: Proxy Nginx not reloaded"
	fi

	# security
	echo -e "[notice]: The following tasks could be done only manually"
	echo -e "- Project dir '/var/www/$PROJECT_NAME' not removed"
	echo -e "- Project 'user' and 'group' not removed"

fi


#!/bin/bash

if [ -z "$FRAMEWORK_ROOT_DIR" ];then
        export FRAMEWORK_ROOT_DIR=$(pwd)
fi

PARAM_ACTION=$1
PARAM_MODULE=$2

VALID_ACTIIONS=('up' 'down' 'restart')
IS_ACTION_VALID=0

VALID_MODULES=('proxy')
IS_MODULE_VALID=0

# action
if [[ -z $PARAM_ACTION ]]; then
        echo -e "[error] action argument missing '$PARAM_ACTION'"
        exit 1
fi

for VALID_ACTION in "${VALID_ACTIIONS[@]}"; do
        if [[ "$VALID_ACTION" == "$PARAM_ACTION" ]]; then
                IS_ACTION_VALID=1
                break
        fi
done

if [[ "$IS_ACTION_VALID" != "1" ]]; then
        echo -e "[error] action argument invalid '$PARAM_ACTION'"
        exit 1  
fi

# module
if [[ -z "$PARAM_MODULE" ]]; then
        echo -e "[error] module argument missing '$PARAM_DOMAIN'"
        exit 1
fi

for VALID_MODULE in "${VALID_MODULES[@]}"; do
        if [[ "$VALID_MODULE" == "$PARAM_MODULE" ]]; then
                IS_MODULE_VALID=1
                break
        fi
done

if [[ "$IS_MODULE_VALID" != "1" ]]; then
        echo -e "[error] module argument invalid '$PARAM_MODULE'"
        exit 1
fi

# --- test
#echo "IS_ACTION_VALID: $IS_ACTION_VALID; IS_MODULE_VALID: $IS_MODULE_VALID"

PROXY_NAME=$(cat $FRAMEWORK_ROOT_DIR/data/infra | grep -E "^proxy=" | cut -d '=' -f 2)

# up
if [[ "$PARAM_ACTION" == "up" ]]; then
	if [[ "$PARAM_MODULE" == "proxy" ]]; then
		docker compose -f $FRAMEWORK_ROOT_DIR/infra/$PARAM_MODULE/$PROXY_NAME/docker-compose.yml up -d
		if [[ $? -eq 0 ]]; then
			echo -e "[done] Infra Module $PARAM_MODULE '$PROXY_NAME' up"
		fi
	fi
fi

# down
if [[ "$PARAM_ACTION" == "down" ]]; then
	if [[ "$PARAM_MODULE" == "proxy" ]]; then
		docker compose -f $FRAMEWORK_ROOT_DIR/infra/$PARAM_MODULE/$PROXY_NAME/docker-compose.yml down
		if [[ $? -eq 0 ]]; then
			echo -e "[done] Infra Module $PARAM_MODULE '$PROXY_NAME' down"
		fi
	fi
fi

# restart
if [[ "$PARAM_ACTION" == "restart" ]]; then
	if [[ "$PARAM_MODULE" == "proxy" ]]; then
		# up?
		if ! docker compose -f $FRAMEWORK_ROOT_DIR/infra/$PARAM_MODULE/$PROXY_NAME/docker-compose.yml ps | grep -E "global-proxy-nginx"; then
                	echo -e "[error]: Infra Module $PARAM_MODULE '$PROXY_NAME' is not up to restart"
                	exit 1
        	fi

		docker compose -f $FRAMEWORK_ROOT_DIR/infra/$PARAM_MODULE/$PROXY_NAME/docker-compose.yml restart
		if [[ $? -eq 0 ]]; then
			echo -e "[done] Infra Module $PARAM_MODULE '$PROXY_NAME' restarted"
		fi
	fi
fi


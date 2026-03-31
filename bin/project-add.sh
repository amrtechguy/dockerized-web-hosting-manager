#!/bin/bash

DOMAIN=$1

# generate project id
if [[ ! -f "$FRAMEWORK_ROOT_DIR/data/project_id" ||  -z "$FRAMEWORK_ROOT_DIR/data/project_id" ]];
then
        echo "[error] file missing or empty: $FRAMEWORK_ROOT_DIR/data/project_id"
        exit 1
fi

PROJECT_ID=$(cat $FRAMEWORK_ROOT_DIR/data/project_id)
PROJECT_ID=$(( $PROJECT_ID + 1 ))
PROJECT_NAME="site-$PROJECT_ID"

if [[ "$PROJECT_ID" -lt "1100" ]];
then
        echo "[error] invalid value: $FRAMEWORK_ROOT_DIR/data/project_id"
        exit 1
fi

# generate user id
if [[ ! -f "$FRAMEWORK_ROOT_DIR/data/user_id" || -z "$FRAMEWORK_ROOT_DIR/data/user_id" ]];
then
        echo "[error] file missing or empty: $FRAMEWORK_ROOT_DIR/data/user_id"
        exit 1
fi

USER_ID=$(cat $FRAMEWORK_ROOT_DIR/data/user_id)
USER_ID=$(( $USER_ID + 1 ))
USER_NAME="u$USER_ID"

if [[ "$USER_ID" -lt "1100" ]];
then
        echo "[error] invalid value: $FRAMEWORK_ROOT_DIR/data/user_id"
        exit 1
fi

# generate group id
if [[ ! -f "$FRAMEWORK_ROOT_DIR/data/group_id" || -z "$FRAMEWORK_ROOT_DIR/data/group_id" ]];
then
        echo "[error] file missing or empty: $FRAMEWORK_ROOT_DIR/data/group_id"
	exit 1
fi

GROUP_ID=$(cat $FRAMEWORK_ROOT_DIR/data/group_id)
GROUP_ID=$(( $GROUP_ID + 1 ))
GROUP_NAME="g$GROUP_ID"

# check duplicates
DOMAIN_FILE_EXISTS=0
PROJECT_DIR_EXISTS=0
USER_NAME_EXISTS=0
GROUP_NAME_EXISTS=0
PROJECT_WWW_EXISTS=0

if [[ ! -z $DOMAIN && -f $FRAMEWORK_ROOT_DIR/infra/proxy/nginx/nginx/conf.d/$DOMAIN.conf ]]; then
        DOMAIN_FILE_EXISTS=1
fi

# dir
if [[ ! -z $PROJECT_NAME && -d $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME  ]]; then
        PROJECT_DIR_EXISTS=1
fi

# user
if [[ ! -z $USER_NAME && $(getent passwd $USER_NAME > /dev/null 2>&1) ]]; then
        USER_NAME_EXISTS=1
fi

# group
if [[ ! -z $GROUP_NAME && $(getent group $GROUP_NAME > /dev/null 2>&1) ]]; then
        GROUP_NAME_EXISTS=1
fi

# www
if sudo [ -d /var/www/$PROJECT_NAME ]; then
        PROJECT_WWW_EXISTS=1
fi

if [[ "$DOMAIN_FILE_EXISTS" == "1" || "$PROJECT_DIR_EXISTS" == "1" || "$USER_NAME_EXISTS" == "1" || "$GROUP_NAME_EXISTS" == "1" || "$PROJECT_WWW_EXISTS" == "1" ]]; then
        echo "[error] Project exists: $PROJECT_NAME"
	echo -e "\t[DOMAIN_FILE_EXISTS] exists: $DOMAIN_FILE_EXISTS"
	echo -e "\t[PROJECT_DIR_EXISTS] exists: $PROJECT_DIR_EXISTS"
	echo -e "\t[USER_NAME_EXISTS] exists: $USER_NAME_EXISTS"
	echo -e "\t[GROUP_NAME_EXISTS] exists: $GROUP_NAME_EXISTS"
	echo -e "\t[PROJECT_WWW_EXISTS] exists: $PROJECT_WWW_EXISTS"
	exit 1
fi

# add group to host
if $(sudo groupadd -g $GROUP_ID $GROUP_NAME);
then
        echo "[done] group added: $GROUP_NAME"
        echo $GROUP_ID > "$FRAMEWORK_ROOT_DIR/data/group_id"
else
        echo "[error] group not added: $GROUP_NAME"
        exit 1
fi

# add user to host
if $(sudo useradd -u $USER_ID -g $GROUP_ID -s /usr/sbin/nologin $USER_NAME);
then
        echo [done] user added: $USER_NAME
        echo $USER_ID > "$FRAMEWORK_ROOT_DIR/data/user_id"
else
        echo "[error] user not added: $USER_NAME"
        exit 1
fi

# add group 'www-data' to the new user
if $(sudo usermod -aG www-data $USER_NAME);
then
        echo "[done] user modified: added group 'www-data' to user '$USER_NAME'"
else
        echo "[error] user not modified: failed to add group 'www-data' to user '$USER_NAME'"
        exit 1
fi

# create project dir
if $(mkdir $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME);
then
        echo "[done] project dir created: $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME"
else
        echo "[error] project dir not created: $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME"
        exit 1
fi

# copy template files to project dir
if $(cp -r $FRAMEWORK_ROOT_DIR/template/project/. $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME);
then
        echo "[done] project files copied: $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME"
else
        echo "[error] project files not copied: $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME failed"
        exit 1
fi

# replace project's .env placeholders
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/.env
sed -i "s/{{USER_ID}}/$USER_ID/g" $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/.env
sed -i "s/{{USER_NAME}}/$USER_NAME/g" $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/.env
sed -i "s/{{GROUP_ID}}/$GROUP_ID/g" $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/.env
sed -i "s/{{GROUP_NAME}}/$GROUP_NAME/g" $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/.env

sed -i "s/{{USER_NAME}}/$USER_NAME/g" $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/php-fpm/php-fpm.d/www.conf
sed -i "s/{{GROUP_NAME}}/$GROUP_NAME/g" $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/php-fpm/php-fpm.d/www.conf

echo "[done] site parameters replaced: $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME"

# replace project nginx.conf placeholders
sed -i "s/{{USER_NAME}}/$USER_NAME/g" $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/nginx/nginx.conf
sed -i "s/{{GROUP_NAME}}/$GROUP_NAME/g" $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/nginx/nginx.conf

# create project dir under /var/www
sudo install -d -o $USER_NAME -g $GROUP_NAME -m 2750 /var/www/$PROJECT_NAME
sudo install -d -o $USER_NAME -g $GROUP_NAME -m 2750 /var/www/$PROJECT_NAME/html
sudo -u $USER_NAME cp ./template/www/html/index.php /var/www/$PROJECT_NAME/html
echo "[done] site dir add: /var/www/$PROJECT_NAME"

# store current $PROJECT_ID
echo $PROJECT_ID > $FRAMEWORK_ROOT_DIR/data/project_id
echo "[done] project_id updated: new value '$PROJECT_ID'"

# add a project entry
echo "$DOMAIN:$PROJECT_NAME:$USER_NAME:$GROUP_NAME" >> $FRAMEWORK_ROOT_DIR/data/project
if [ $? -eq 0 ];
then
        echo "[done] project entry added: '$DOMAIN:$PROJECT_NAME:$USER_NAME:$GROUP_NAME'"
else
        echo "[error] project entry not added: '$DOMAIN:$PROJECT_NAME:$USER_NAME:$GROUP_NAME'"
fi

# run project
docker compose -f $FRAMEWORK_ROOT_DIR/project/$PROJECT_NAME/docker-compose.yml up -d > /dev/null 2>&1
if [ $? -eq 0 ];
then
        echo "[done] $PROJECT_NAME: up"
else
        echo "[error] $PROJECT_NAME: failed to run"
fi

# add site conf
HOST_NAME="$PROJECT_NAME-nginx"
cp $FRAMEWORK_ROOT_DIR/template/infra/proxy/nginx/nginx/conf.d/.domain.conf $FRAMEWORK_ROOT_DIR/infra/proxy/nginx/nginx/conf.d/$DOMAIN.conf
sed -i "s/{{DOMAIN}}/$DOMAIN/g" $FRAMEWORK_ROOT_DIR/infra/proxy/nginx/nginx/conf.d/$DOMAIN.conf
sed -i "s/{{HOST_NAME}}/$HOST_NAME/g" $FRAMEWORK_ROOT_DIR/infra/proxy/nginx/nginx/conf.d/$DOMAIN.conf
echo "[done] site conf add and update: $FRAMEWORK_ROOT_DIR/infra/proxy/nginx/nginx/conf.d/$DOMAIN.conf"

# test proxy
docker exec global-proxy-nginx nginx -t
if [[ $? -eq 0 ]]; then
        # ok
        echo "[done] proxy config tested: clean"

        docker exec global-proxy-nginx nginx -s reload
        if [[ $? -eq 0 ]]; then
                echo "[done] proxy reloaded"
        else
                echo "[error] proxy failed to reload"
        fi      
else
        # typos
        echo "[error] proxy config tested: error"
        echo "[notice] fix proxy config errors first, then reload it"
fi


#!/bin/bash
set -e
#export PGPASSWORD=''

usage(){
cat << EOF
usage: $0 options

OPTIONS:
   -a      Database address
EOF
}

DB_HOST=""
while getopts "a:" OPTION; do
    case $OPTION in
        a)
            DB_HOST=$OPTARG;
            ;;
    esac
done

if [[ -z ${DB_HOST} ]]; then 
  usage
  exit 1
fi

authorization(){
  psql -h ${DB_HOST} -U postgres -qAt -c "\l"
  echo -e "\n"
  read -p "请输入你要授权的数据库：" DATABASE
  psql -h ${DB_HOST} -U postgres -qAt -c "\dn"
  echo -e "\n"
  read -p "请输入你要授权数据库的 schema: " SCHEMA
  read -p "1、授予该库所有权限; 2、授予改库只读权限：" AUTH_NUM
  case ${AUTH_NUM} in
    1)
      psql -h ${DB_HOST} -U postgres -qAt -c "GRANT USAGE ON SCHEMA ${SCHEMA} TO ${USER_NAME};" ${DATABASE}
      psql -h ${DB_HOST} -U postgres -qAt -c "GRANT SELECT, UPDATE, INSERT, DELETE ON ALL TABLES IN SCHEMA ${SCHEMA} TO ${USER_NAME};" ${DATABASE}
      psql -h ${DB_HOST} -U postgres -qAt -c "GRANT SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA ${SCHEMA} TO ${USER_NAME};" ${DATABASE}
      psql -h ${DB_HOST} -U postgres -qAt -c "ALTER DEFAULT PRIVILEGES IN SCHEMA ${SCHEMA} GRANT SELECT, UPDATE, INSERT, DELETE ON TABLES TO ${USER_NAME};" ${DATABASE}
      psql -h ${DB_HOST} -U postgres -qAt -c "ALTER DEFAULT PRIVILEGES IN SCHEMA ${SCHEMA} GRANT SELECT, UPDATE on SEQUENCES to ${USER_NAME};" ${DATABASE}
      ;;
    2)
      psql -h ${DB_HOST} -U postgres -qAt -c "grant usage on schema ${SCHEMA} to ${USER_NAME};" ${DATABASE}
      psql -h ${DB_HOST} -U postgres -qAt -c "grant select on all tables in schema ${SCHEMA} to ${USER_NAME};" ${DATABASE}
      psql -h ${DB_HOST} -U postgres -qAt -c "alter default privileges in schema ${SCHEMA} grant select on tables to ${USER_NAME};" ${DATABASE}
      ;;
    *)
      echo "请选择正确的数字！"
      ;;
  esac
}

read -p "1、创建用户并授权; 2、给已有用户授权：" INPUT_NUM

case $INPUT_NUM in
  1)
    read -p "请输入用户名: " USER_NAME
    read -p "请输入用户密码: " USER_PASS

    psql -h ${DB_HOST} -U postgres -qAt -c "create user ${USER_NAME} with password '${USER_PASS}'"
    authorization
    ;;

  2)
    psql -h ${DB_HOST} -U postgres -qAt -c "\du" | awk -F '|' '{print $1}'
    echo -e "\n"
    read -p "请输入你想授权的用户名: " USER_NAME
    authorization
    ;;
  *)
    echo "请选择正确的数字！"
    ;;
esac

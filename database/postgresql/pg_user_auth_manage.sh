#!/bin/bash
set -e

usage(){
cat << EOF
usage: $0 OPTIONS

OPTIONS:
   -a      Database address
   -p	   Root user password
EOF
}

DB_HOST=""
DB_PASS=""
while getopts "a:p:" OPTION; do
    case $OPTION in
        a)
            DB_HOST=$OPTARG;
            ;;
        p)
            DB_PASS=$OPTARG;
            ;;
    esac
done

if [[ -z ${DB_HOST} ]] || [[ -z ${DB_PASS} ]] ; then 
  usage
  exit 1
fi

export PGPASSWORD="${DB_PASS}"

authorization(){
  psql -h ${DB_HOST} -U postgres -qAt -c "\l" | grep "|"  | grep -v "rdsadmin" | awk -F '|' '{print $1}'
  echo -e "\n"
  read -p "请输入你要授权的数据库：" DATABASE
  psql -h ${DB_HOST} -U postgres -qAt -c "\dn" ${DATABASE} | awk -F '|' '{print $1}'
  echo -e "\n"
  read -p "请输入你要授权数据库的 schema 以空格区分多个 schema: " SCHEMAS
  echo -e "\n"
  read -p "1、授予该库所有权限; 2、授予改库只读权限：" AUTH_NUM
  case ${AUTH_NUM} in
    1)
      for SCHEMA in ${SCHEMAS};
	do
          psql -h ${DB_HOST} -U postgres -qAt -c "GRANT CONNECT ON DATABASE ${DATABASE} TO ${USER_NAME};"
          psql -h ${DB_HOST} -U postgres -qAt -c "GRANT USAGE ON SCHEMA \"${SCHEMA}\" TO ${USER_NAME};" ${DATABASE}
          psql -h ${DB_HOST} -U postgres -qAt -c "GRANT SELECT, UPDATE, INSERT, DELETE ON ALL TABLES IN SCHEMA \"${SCHEMA}\" TO ${USER_NAME};" ${DATABASE}
          psql -h ${DB_HOST} -U postgres -qAt -c "GRANT SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA \"${SCHEMA}\" TO ${USER_NAME};" ${DATABASE}
          psql -h ${DB_HOST} -U postgres -qAt -c "ALTER DEFAULT PRIVILEGES IN SCHEMA \"${SCHEMA}\" GRANT SELECT, UPDATE, INSERT, DELETE ON TABLES TO ${USER_NAME};" ${DATABASE}
          psql -h ${DB_HOST} -U postgres -qAt -c "ALTER DEFAULT PRIVILEGES IN SCHEMA \"${SCHEMA}\" GRANT SELECT, UPDATE on SEQUENCES to ${USER_NAME};" ${DATABASE}
	done
      echo "授权成功！"
      ;;
    2)
      for SCHEMA in ${SCHEMAS};
        do
          psql -h ${DB_HOST} -U postgres -qAt -c "GRANT CONNECT ON DATABASE ${DATABASE} TO ${USER_NAME};"
          psql -h ${DB_HOST} -U postgres -qAt -c "grant usage on schema \"${SCHEMA}\" to ${USER_NAME};" ${DATABASE}
          psql -h ${DB_HOST} -U postgres -qAt -c "grant select on all tables in schema \"${SCHEMA}\" to ${USER_NAME};" ${DATABASE}
          psql -h ${DB_HOST} -U postgres -qAt -c "alter default privileges in schema \"${SCHEMA}\" grant select on tables to ${USER_NAME};" ${DATABASE}
	done
      echo "授权成功！"
      ;;
    *)
      echo "请选择正确的数字！"
      ;;
  esac
}

delete_user(){
  #ALL_DATABASES=`psql -h ${DB_HOST} -U postgres -qAt -c "\l" | grep "|"  | grep -v "rdsadmin" | awk -F '|' '{print $1}'`
  psql -h ${DB_HOST} -U postgres -qAt -c "\l" | grep "|"  | grep -v "rdsadmin" | awk -F '|' '{print $1}'
  echo -e "\n"
  read -p "请输入数据库名称以空格分隔：" ALL_DATABASES
  for DATABASE in ${ALL_DATABASES};
    do
      echo "正在执行的数据库 ${DATABASE}"
      psql -h ${DB_HOST} -U postgres -qAt -c "REVOKE CONNECT ON DATABASE ${DATABASE} FROM ${USER_NAME};"
      ALL_SCHEMAS=`psql -h ${DB_HOST} -U postgres -qAt -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name != 'information_schema' AND schema_name != 'pg_toast' AND schema_name != 'pg_catalog';" ${DATABASE} | egrep -v "pg_toast_temp|pg_temp"`
	for SCHEMA in ${ALL_SCHEMAS};
	  do
	    echo "正在执行的 schema \"${SCHEMA}\""
            psql -h ${DB_HOST} -U postgres -qAt -c "REVOKE USAGE ON SCHEMA \"${SCHEMA}\" FROM ${USER_NAME};" ${DATABASE}
            psql -h ${DB_HOST} -U postgres -qAt -c "REVOKE SELECT, UPDATE, INSERT, DELETE ON ALL TABLES IN SCHEMA \"${SCHEMA}\" FROM ${USER_NAME};" ${DATABASE}
            psql -h ${DB_HOST} -U postgres -qAt -c "REVOKE SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA \"${SCHEMA}\" FROM ${USER_NAME};" ${DATABASE}
            psql -h ${DB_HOST} -U postgres -qAt -c "ALTER DEFAULT PRIVILEGES IN SCHEMA \"${SCHEMA}\" REVOKE SELECT, UPDATE, INSERT, DELETE ON TABLES FROM ${USER_NAME};" ${DATABASE}
            psql -h ${DB_HOST} -U postgres -qAt -c "ALTER DEFAULT PRIVILEGES IN SCHEMA \"${SCHEMA}\" REVOKE SELECT, UPDATE ON SEQUENCES FROM ${USER_NAME};" ${DATABASE}
	  done
    done
  psql -h ${DB_HOST} -U postgres -qAt -c "DROP USER IF EXISTS ${USER_NAME}"
  echo "删除用户 ${USER_NAME} 成功！"
}

echo -e "1、创建用户并授权"
echo -e "2、给已有用户授权"
echo -e "3、删除用户"
read -p "请选择：" INPUT_NUM
echo -e "\n"

case $INPUT_NUM in
  1)
    read -p "请输入用户名: " USER_NAME
    read -p "请输入用户密码: " USER_PASS

    psql -h ${DB_HOST} -U postgres -qAt -c "create user ${USER_NAME} with password '${USER_PASS}'"
    authorization
    ;;

  2)
    psql -h ${DB_HOST} -U postgres -qAt -c "\du" | grep -v "Password" | awk -F '|' '{print $1}' 
    echo -e "\n"
    read -p "请输入你想授权的用户名: " USER_NAME
    authorization
    ;;
  3)
    psql -h ${DB_HOST} -U postgres -qAt -c "\du" | grep -v "Password" | awk -F '|' '{print $1}'
    echo -e "\n"
    read -p "请输入你想删除的用户名: " USER_NAME
    delete_user 
    ;;
  *)
    echo "请选择正确的数字！"
    ;;
esac

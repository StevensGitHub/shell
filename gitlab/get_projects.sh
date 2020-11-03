#!/bin/bash
ftl_group_id=1511956
esendeo_group_id=6780156

# 遍历根群组ID
for group_id in $ftl_group_id $esendeo_group_id
  do
    # 过滤出项目git地址进行下载
    for ssh_url_to_repo in `curl --header "PRIVATE-TOKEN: zzMTyTxFKkR9Ax6ifrxR" "https://gitlab.com/api/v4/groups/${group_id}/projects" -s | jq | grep ssh_url_to_repo | awk '{print $2}' | awk -F '"' '{print $2}'`
      do
        git clone $ssh_url_to_repo
      done
    # 获取群组下子群组ID并下载项目
    for subgroups_id in `curl --header "PRIVATE-TOKEN: zzMTyTxFKkR9Ax6ifrxR" "https://gitlab.com/api/v4/groups/${group_id}/subgroups" -s | jq | grep \"id | awk '{print $2}' | awk -F ',' '{print $1}'`
      do
	for subgroups_ssh_url_to_repo in `curl --header "PRIVATE-TOKEN: zzMTyTxFKkR9Ax6ifrxR" "https://gitlab.com/api/v4/groups/${subgroups_id}/projects" -s | jq | grep ssh_url_to_repo | awk '{print $2}' | awk -F '"' '{print $2}'`
	  do
	    git clone $subgroups_ssh_url_to_repo
	  done
	# 获取子项目下项目
	for sub_subgroups_id in `curl --header "PRIVATE-TOKEN: zzMTyTxFKkR9Ax6ifrxR" "https://gitlab.com/api/v4/groups/${subgroups_id}/subgroups" -s | jq | grep \"id | awk '{print $2}' | awk -F ',' '{print $1}'`
	  do
            for sub_subgroups_ssh_url_to_repo in `curl --header "PRIVATE-TOKEN: zzMTyTxFKkR9Ax6ifrxR" "https://gitlab.com/api/v4/groups/${sub_subgroups_id}/projects" -s | jq | grep ssh_url_to_repo | awk '{print $2}' | awk -F '"' '{print $2}'`
              do
                git clone $sub_subgroups_ssh_url_to_repo
              done
	  done
      done
  done

#!/bin/sh
starttime=`date '+%s'`
echo -e "\033[35m[`date '+%F %T'`] MakeCard Starting... \033[0m"
if [[ $1 ]];
then
	echo "[`date '+%F %T'`] 开始制作头文件..."
	source /home/pboss/makecard/card_data.sh
	cutmessages $1
	if [[ $name ]];
	then
		formats
                if [[ ${SyncInfo} =~ "SyncInfo" ]];
                then
			if [[ $end == 18 ]];
			then
				#====获取ICCID和IMSI====
				echo "[`date '+%F %T'`] 开始获取IMSI和ICCID..."
				sshh $1 > ${dirpath}result1.txt
#> /dev/null 2>&1
				#scpp ${datapath} ${dirpath} > /dev/null 2>&1
#> /dev/null 2>&1
				echo "[`date '+%F %T'`] 开始制作卡数据文件..."
				makecarddatas
				if [[ -f ${dirpath}${name} ]];
				then
					echo "[`date '+%F %T'`] 开始加密..."
					encryption
					if [[ -f ${dirpath}${namesave} ]];
					then
						echo "[`date '+%F %T'`] 开始上传..."
						scppp ${dirpath} ${namesave} ${keyname} > /dev/null 2>&1 
#> /dev/null 2>&1
						echo -e "\033[35m[`date '+%F %T'`] 判断卡数据是否成功上传至107主机... \033[0m"
						shhpd $1 > ${dirpath}result2.txt
						if [[ -s ${dirpath}result2.txt ]]
						then	
							echo $namesave
							echo $keyname
							echo -e "\033[32m                    卡数据上传成功！！ \033[0m"
							echo "[`date '+%F %T'`] 发送反馈报文..."
							feedback
						else 
							echo -e "\033[31m Fail:              卡数据上传失败 \033[0m"
						fi
					else
						echo -e "\033[31m Fail:加密失败 \033[0m"
					fi
				else
					echo -e "\033[31m Fail:未生成有效卡数据 \033[0m"
				fi
			else
				echo -e "\033[31m Fail:制卡申请报文不正确，请检查报文! \033[0m"
			fi
		else
			echo -e "\033[31m Fail:未截取到有效报文 \033[0m"
		fi
	else
		echo -e "\033[31m Fail:未找到日志路径 \033[0m"
	fi
else
	echo -e "\033[31m Fail:无效流水 \033[0m"
fi
echo -e "\033[35m[`date '+%F %T'`] MakeCard Finished... \033[0m"
endtime=`date '+%s'`
usetime=`expr $((10#${endtime})) - $((10#${starttime}))`
echo -e "\033[33m           用时：`expr $((10#${usetime})) / 3600`时`expr $((10#${usetime})) / 60 % 60`分`expr $((10#${usetime})) % 60`秒 \033[0m"

#删除5天前的卡数据文件
Timedd=`date -d "6 days ago" "+%Y%m%d"`

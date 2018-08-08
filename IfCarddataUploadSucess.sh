#!/bin/sh
#echo 增加卡数据是否成功上传的判断！！
IfData=`ls /home/pboss/file/pboss/cardinfo/|grep $1`
if [[ -n $IfData ]]
then
	echo $IfData
fi

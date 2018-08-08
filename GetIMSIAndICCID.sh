#!/bin/bash
#=====================截取ICCID=================
getIMSI(){
	echo "`date '+%F %T'` 获取IMSI和ICCID..."
	seq=$1
	len=`expr length $seq`
	if [[ $((10#${len})) -eq 32 ]];
	then
	#Provision=${seq:0:3}
	#取流水上的时间
	Time_Year=${seq:12:4}
	Time_Moon=${seq:16:2}
	Time_Day=${seq:18:2}
	Time_Hour=${seq:20:2}
	seq_time=${seq:12:10}
	#取系统当前时间
	now_time=`date +%Y%m%d%H`
	year=`date +%Y`
	moon=`date +%m`
	day=`date +%d`
	hour=`date +%H`
	dirpathtime=/home/pboss/makecard/${Time_Year}${Time_Moon}${Time_Day}
	dirpath=/home/pboss/makecard/${Time_Year}${Time_Moon}${Time_Day}/$seq/
	datapath=/home/pboss/makecard/${Time_Year}${Time_Moon}${Time_Day}/$seq/data/
	path_now=/work/pboss3_web/logs/pboss-web/pboss-resource-web/
	nowname="/work/pboss3_web/logs/pboss-web/pboss-resource-web/pboss-resource-web.log"
	#按系统当前时间
	path_his=/work/logs/$year/$moon/$day/main/pboss-resource-web/
	#按流水上的时间
	path_befor=/work/logs/$Time_Year/$Time_Moon/$Time_Day/main/pboss-resource-web/
	if [ ! -d "${dirpathtime}" ];
	then
        mkdir ${dirpathtime}
	fi
	if [ ! -d "${dirpath}" ];
	then
        mkdir ${dirpath}
	fi
	if [ ! -d "${datapath}" ];
	then
        mkdir ${datapath}
	fi

	#-n 获取行号
	grep -n '<QueryOprNum>'$seq'</QueryOprNum>' ${path_now}* > ${dirpath}greplog.txt
	zgrep -n '<QueryOprNum>'$seq'</QueryOprNum>' ${path_his}* >> ${dirpath}greplog.txt
	zgrep -n '<QueryOprNum>'$seq'</QueryOprNum>' ${path_befor}* >> ${dirpath}greplog.txt
	pathlognametwo=`awk -F: '{print $1}' ${dirpath}greplog.txt|sed -n "1p"`
	midleline=`awk -F: '{print $2}' ${dirpath}greplog.txt|sed -n "1p"`   
	#获取报文所在的行号
	iccidendline=`expr $((10#${midleline})) + 14`
	imsiendline=`expr $((10#${midleline})) + 18`
	#截取右边开始第一个.之后的字符串b=${a#*log.}或b=${a:0-2:2}
	pathlognamezero=${pathlognametwo:0-2:2}
	if [[ ${pathlognamezero} == "gz" ]];
	then	
		#截取从右边开始第一个.之前的字符串b=${a%.*}
		pathlognamethree=${pathlognametwo%.*}
		gunzip -c ${pathlognametwo} > ${pathlognamethree}
		sed -n "$((10#${iccidendline})),$((10#${imsiendline}))p" ${pathlognamethree} > ${dirpath}last.txt
	else
		sed -n "$((10#${iccidendline})),$((10#${imsiendline}))p" ${pathlognametwo} > ${dirpath}last.txt
	fi
	ICCID=`awk -F '</|>' '{if(NR==1) {print ($2)}}' ${dirpath}last.txt`
	IMSI=`awk -F '</|>' '{if(NR==5) {print ($2)}}' ${dirpath}last.txt`
	#echo $ICCID > ${datapath}data.txt
	#echo $IMSI >> ${datapath}data.txt
	echo ${ICCID}
	echo ${IMSI}
	else
        echo 'Fail：流水长度不正确'
		echo 'len:'$len
	fi
	rm -rf ${dirpath}last.txt
	rm -rf ${dirpath}greplog.txt
	#echo $ICCID
	#删除变量
	unset pathlognametwo
	unset pathlognamethree
}
getIMSI $1
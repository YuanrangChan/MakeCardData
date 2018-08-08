#!/bin/bash
#获取申请报文日志路径
cutmessages()
{
	seq=$1
	len=`expr length $seq`
	if [[ $((10#${len})) -eq 32 ]];
	then
		Provision=${seq:0:3}
		Time_Year=${seq:12:4}
		Time_Moon=${seq:16:2}
		Time_Day=${seq:18:2}
		Time_Hour=${seq:20:2}
		seq_time=${seq:12:10}
		now_time=`date +%Y%m%d%H`
		year=`date +%Y`
		moon=`date +%m`
		day=`date +%d`
		hour=`date +%H`
		if [[ ${Provision} == "240" ]];
		then
        		provision1='240'
		else
        		provision1='000'
		fi
		path30001=/work/interface/interface-service/logs/3${provision1}1/
		path30002=/work/interface/interface-service/logs/3${provision1}2/
		string30001=`grep $seq ${path30001}pboss-boss.log`
		string30002=`grep $seq ${path30002}pboss-boss.log`
		dirpathtime=/home/pboss/makecard/${Time_Year}${Time_Moon}${Time_Day}
		dirpath=/home/pboss/makecard/${Time_Year}${Time_Moon}${Time_Day}/$seq/
		datapath=/home/pboss/makecard/${Time_Year}${Time_Moon}${Time_Day}/$seq/data/
		if [ ! -d "${dirpathtime}" ];
		then
        		mkdir ${dirpathtime}
		fi
		if [ ! -d "${dirpath}" ];
		then
        		mkdir ${dirpath}
		fi
		if [[ $((10#${seq_time})) -eq $((10#${now_time})) ]];
		then
        		if [[ ${string30001} =~ "InterBOSS" || ${string30001} =~ "QueryOprNum" ]];
        		then
                		Path=${path30001}
        		else
                		Path=${path30002}
        		fi
        		logname='pboss-boss.log'
			name=${Path}${logname}
		else
        		if [[ ${Provision} == "240" ]];
        		then
                		provision='240'
        		else
                		provision='comm'
        		fi
        		Path=/work/logs/$Time_Year/$Time_Moon/$Time_Day/main/interface-service-${provision}/
        		cd $Path
        		zgrep $seq pboss-boss* > ${dirpath}greplog.txt
        		first_line=`sed -n "1,2p" ${dirpath}greplog.txt`
        		if [[ ${first_line} =~ "InterBOSS" || ${first_line} =~ "QueryOprNum" ]];
        		then
                		end_num=`sed -n "1p" ${dirpath}greplog.txt|awk -F_ '{print $2}'`
        		else
                		if [[ ${Provision} == "240" ]];
                		then
                        		end_num='32402'
                		else
                        		end_num='30002'
                		fi
        		fi
        		lognameunzip='pboss-boss.'${Time_Year}${Time_Moon}${Time_Day}${Time_Hour}'_'${end_num}'_0.log'
        		logname='pboss-boss.'${Time_Year}${Time_Moon}${Time_Day}${Time_Hour}'_'${end_num}'_0.log.gz'
        		name=${Path}${logname}
		fi
	else
        	echo -e "\033[31m $0 Fail：流水长度不正确 \033[0m"
	fi
}


#格式化获取到的报文
#==变量值从cutmessage.sh中获取==
formats(){
	if [[ $name ]]
	then
		if [[ $logname == 'pboss-boss.log' ]];
		then
        		grep -n "<QueryOprNum>$seq" ${name}|sed -n "1p" > ${dirpath}message1.xml
		else
			if [[ -f ${Path}${lognameunzip} ]];
			then 
				grep -n "<QueryOprNum>$seq" ${Path}${lognameunzip}|sed -n "1p" > ${dirpath}message1.xml
			else
        			zgrep -n "<QueryOprNum>$seq" ${name}|sed -n "1p" > ${dirpath}message1.xml
			fi
		fi
		if [[ ! -s ${dirpath}message1.xml ]];
		then
        		echo -e "\033[31m $0 Fail：流水错误或流水中的时间填写错误 \033[0m"
		else
			filesize=`ls -l ${dirpath}message1.xml|awk '{print $5}'`
			#大于等于
			if [[ ${filesize} -gt 100 ]];
			then
        			cd ${dirpath}
        			awk -F':' '{print $5}' message1.xml > ${dirpath}message.xml
  				sed -i "s/<?xml version='1.0' encoding='UTF-8'?>//g;s/<?xml version=\"1.0\" encoding=\"UTF-8\"?>//g;s/<InterBOSS><SvcCont><!\[CDATA\[//g;s/\]\]><\/SvcCont><\/InterBOSS>//g" message.xml
        			xmllint -format ${dirpath}message.xml > ${dirpath}messagerule.xml
			else
				messagemidleline=`awk -F: '{print $1}' ${dirpath}message1.xml|sed -n "1p"`
                		messagebeginline=`expr $((10#${messagemidleline})) - 4`
                		messageendline=`expr $((10#${messagemidleline})) + 13`
				if [[ $logname == 'pboss-boss.log' ]];
				then
					sed -n "$((10#${messagebeginline})),$((10#${messageendline}))p" ${name} > ${dirpath}messagerule.xml
				else
		        		if [ ! -f "${Path}${lognameunzip}" ];
		        		then
               					gunzip -c  ${name} > ${Path}${lognameunzip}
        				fi
					sed -n "$((10#${messagebeginline})),$((10#${messageendline}))p" ${Path}${lognameunzip} > ${dirpath}messagerule.xml
				fi
			fi
			#增加判断报文是否正确
			end=`awk 'END{print NR}' ${dirpath}messagerule.xml`
			#设置一个参数以便判断是否去获取ICCID
			SyncInfo=`awk '{if (NR == 2) {print $0}}' ${dirpath}messagerule.xml`
		fi
	fi
}

#注意sh脚本中启用expect时，转义符是三个\
#但在expect脚本中转义符是一个\

#获取ICCID和IMSI
sshhT(){
        /usr/bin/expect <<-EOF
	set seq [lindex $argv 0]
	spawn ssh 192.168.119.132 "./cutmessageT.sh $seq" 
	set timeout -1
	expect "*assword*"
	set timeout -1
	send "P_BOSS\\\$2017\r"
	interact
	EOF
}


#改
sshh(){
	/usr/bin/expect <<-EOF
	set seq [lindex $argv 0]
	spawn ssh 192.168.119.132 "./cutmessageT.sh $seq"
	set timeout -1
	expect {
		"*assword*" {send "P_BOSS\\\$2017\r"; exp_continue }
	}
	#expect eof
	EOF
}


#将获取到的IMSI下载到本机
#获取第一个参数值并赋值个seq
scppT(){
        /usr/bin/expect <<-EOF
	set datapath [lindex $argv 0]
	set dirpath [lindex $argv 1]
	spawn scp pboss@192.168.119.132:${datapath}data.txt ${dirpath}
	#永不超时
	set timeout -1
	expect "*assword*"
	send "P_BOSS\\\$2017\r"
	set timeout -1
	interact
	EOF
}

#改
scpp(){
	/usr/bin/expect <<-EOF
	set datapath [lindex $argv 0]
	set dirpath [lindex $argv 1]
	spawn scp pboss@192.168.119.132:${datapath}data.txt ${dirpath}
	set timeout -1
	expect {
	"*assword*" {send "P_BOSS\\\$2017\r"; exp_continue }
	}
	#退出expect
	#expect eof
	EOF
}





#制作卡数据文件
makecarddatas(){
	if [[ -s ${dirpath}result1.txt ]];
	then
		#ICCID=`sed -n "1p" ${dirpath}data.txt`
		#IMSI=`sed -n "2p" ${dirpath}data.txt`
		ICCID=`sed -n "5p" ${dirpath}result1.txt`
		IMSI=`sed -n "6p" ${dirpath}result1.txt`
	fi
	if [[ $ICCID ]];
	then
#		echo "[`date '+%F %T'`] 成功获取IMSI和ICCID!!!"
#		echo "[`date '+%F %T'`] 开始制作卡数据文件..."
		if [[ -s ${dirpath}messagerule.xml ]];
		then
			k=`awk -F '</|>' '{if(NR==4) {printf ($2)}}' ${dirpath}messagerule.xml`
			a=`awk -F '</|>' '{if(NR==5) {printf ($2)}}' ${dirpath}messagerule.xml`
			b=`awk -F '</|>' '{if(NR==6) {printf ($2)}}' ${dirpath}messagerule.xml`
			c=`awk -F '</|>' '{if(NR==7) {printf ($2)}}' ${dirpath}messagerule.xml`
			d=`awk -F '</|>' '{if(NR==8) {printf ($2)}}' ${dirpath}messagerule.xml`
			e=`awk -F '</|>' '{if(NR==9) {printf ($2)}}' ${dirpath}messagerule.xml`
			f=`awk -F '</|>' '{if(NR==10) {printf ($2)}}' ${dirpath}messagerule.xml`
			g=`awk -F '</|>' '{if(NR==11) {printf ($2)}}' ${dirpath}messagerule.xml`
			h=`awk -F '</|>' '{if(NR==12) {printf ($2)}}' ${dirpath}messagerule.xml`
			i=`awk -F '</|>' '{if(NR==14) {printf ($2)}}' ${dirpath}messagerule.xml`
			j=`awk -F '</|>' '{if(NR==15) {printf ($2)}}' ${dirpath}messagerule.xml`
			number=`expr $((10#$j)) + 1`
			art=`expr $((10#$j)) - 1`
			time=${a:12:14}
			name=MW_USimMS_${a}_${b}_${c}_${h}_${time}.dat
			namesave=USimMS_${a}_${b}_${c}_${h}_${time}.dat
			keyname=KeyData_${a}_${b}_${c}_${h}_${time}.IDX
			Pathture=/home/pboss/file/pboss/cardinfo/
			echo -e $seq'|'$b'|'$c'|'$d'|'$e'|'$f'|'$g'|'$i'|'$j'|2~'$number'\r' > ${dirpath}$name
			CardMfrs=`echo ${b}|sed 's/[0-9]//g'`
			if [[ ${CardMfrs} == "" ]];
			then
				echo "卡商代码为数字:${b}"
				headICCID=${ICCID:0:7}
				tailICCID=${ICCID:7:13}
        			tailICCID1=${tailICCID:0:1}
        			tailtailICCID=${tailICCID:1:12}
				#echo $tailtailICCID $tailICCID1 $tailICCID $headICCID
			else
				echo "卡商代码为字母:${CardMfrs}"
        			headICCID=${ICCID:0:13}
        			tailICCID=${ICCID:13:7}
				tailICCID1=${tailICCID:0:1}
				tailtailICCID=${tailICCID:1:6}
			fi
			if [[ $((10#${tailICCID1})) == 0 ]];
			then
				chtailICCID1=`expr $((10#${tailICCID1})) + 1`
				tailICCID=${chtailICCID1}${tailtailICCID}
			fi
                	echo -e "此单申请的卡数据总数:$j"
                	echo '开始ICCID为:'$ICCID
#               	echo "结束ICCID为:${lastICCID}"
                	echo '开始IMSI为:'$IMSI
#                	echo "结束IMSI为:${lastIMSI}"
			dddd=$((10#$tailICCID))		
			lasttailICCID=`expr $dddd + $art`
			headIMSI=${IMSI:0:7}
			tailIMSI=${IMSI:7:8}
			lastIMSI=`expr $tailIMSI + $art`
                	y=$((10#${tailICCID}))
                	x=$((10#${tailIMSI}))
			ddd="#"
                	while [[ $y -le $((10#$lasttailICCID)) && $x -le $((10#$lastIMSI)) ]];
                	do
                    		last=${x:7:1}
				if [[ $((10#${tailICCID1})) == 0 ]];
				then
					if [[ ${CardMfrs} != "" ]];
					then
						z=${y:1:6}
       					else
                                		z=${y:1:12}
					fi
                                	u=${tailICCID1}${z}
                                	lasttailtailICCID=`expr ${tailtailICCID} + $art`
                                	echo -e ${headIMSI}${x}'|'${headICCID}${u}'|0C3B713EAF0CD3BC63BA5ABC6C9475EF|679A21DDBB73C82E593B2B17B1000000|11111111|22222222|0123|4567|1A2B3C4D|'${last}'|13800100569''\r' >> ${dirpath}$name
                                	lastICCID=${headICCID}${tailICCID1}${lasttailtailICCID}
				else
					echo -e ${headIMSI}${x}'|'${headICCID}${y}'|0C3B713EAF0CD3BC63BA5ABC6C9475EF|679A21DDBB73C82E593B2B17B1000000|11111111|22222222|0123|4567|1A2B3C4D|'${last}'|13800100569''\r' >> ${dirpath}$name
					lastICCID=${headICCID}${lasttailICCID}
				fi
				#增加一个生成进度条
				filelastline_num=`awk "END {print NR}" ${dirpath}$name`
				jj=`expr ${filelastline_num} - 1`
				#awk实现浮点计算
				progress=`awk -v x=$jj -v y=$j 'BEGIN{printf "%.2f\n",x/y*100}'`
				#实现单行显示进度百分比\b覆盖
				echo -en "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b[`date '+%F %T'`] 卡数据文件生成:======  [${progress}%]"
				x=`expr $((10#${x})) + 1`
                        	y=`expr $((10#${y})) + 1`
	         	done
			#创建一个显示此单主要信息的文件
			maininfo="号段${i}-条数${j}-卡商${b}-IMSI${IMSI}-ICCID${ICCID}"
			touch ${dirpath}${maininfo}
			#创建一个卡数据头文件，以便omakecard使用ps：20180629已解决非当日获取不到ICCID的问题，故header.txt已不再需要
			echo "$seq $b $c $d $e $f $g $h $i $j $IMSI $ICCID" > ${dirpath}header.txt
#			echo -e "\n此单申请的卡数据总数:$j"
#			echo '开始ICCID为:'$ICCID
			echo -e "\n结束ICCID为:${lastICCID}"
#			echo '开始IMSI为:'$IMSI
			echo "结束IMSI为:${headIMSI}${lastIMSI}"
			#密匙索引文件
			echo -e '001|002''\r' > ${dirpath}${keyname}
#			echo "[`date '+%F %T'`] 卡数据文件制作完成!!!"
		else
			echo -e "\033[31m $0 Fail:没有截取到有效报文 \033[0m"
		fi
	fi


	#创建一个参数以便判断是否上传卡数据文件
	if [[ -f ${dirpath}$name ]];
	then
		scpssh=0
	fi
	#删除多余文件
	if [[ -f ${dirpath}data.txt ]];
	then
		rm ${dirpath}data.txt
	fi
	if [[ -f ${dirpath}message1.xml ]];
	then
        	rm ${dirpath}message1.xml
	fi
	if [[ -f ${dirpath}message.xml ]];
	then
        	rm ${dirpath}message.xml
	fi
	if [[ -f ${dirpath}greplog.txt ]];
	then
        	rm ${dirpath}greplog.txt
	fi
}


#加密卡数据文件
encryption(){
	if [[ ${IMSI} ]];
	then
	#echo "[`date '+%F %T'`] 开始加密..."
	#       1       E4B044E830559B337AD15F2151A05AE8
	#       2       5686853BF6640F967AD15F2151A05AE8
	#       3       06F0E04B8CD98AEA7AD15F2151A05AE8
	#       4       06F0E04B8CD98AEA7AD15F2151A05AE8
	#       0       B9A8C2FDA2378AA4A8EA9D028064FB3B
	    cd /home/pboss/file/des-tools/
	    java -jar EncryptCardFile.jar E4B044E830559B337AD15F2151A05AE8 B9A8C2FDA2378AA4A8EA9D028064FB3B ${dirpath}$name ${dirpath}${namesave} > /dev/null 2>&1
	fi
}


#上传卡数据文件
#获取三个位置参数值并赋值
scpppT(){
	/usr/bin/expect <<-EOF
	set datapath [lindex $argv 0]
	set namesave [lindex $argv 1]
	set keyname [lindex $argv 2]
	set timeout -1
	spawn scp ${datapath}${namesave} ${datapath}${keyname} pboss@192.168.106.107:/home/pboss/file/pboss/cardinfo/
	#永不超时
	set timeout -1
	expect "*assword*"
	send "P_BOSS\\\$2017\r"
	expect eof
	EOF
}
#改
scppp(){
	/usr/bin/expect <<-EOF
	set datapath [lindex $argv 0]
	set namesave [lindex $argv 1]
	set keyname [lindex $argv 2]
	set timeout -1
	spawn scp ${dirpath}${namesave} ${dirpath}${keyname} pboss@192.168.106.107:/home/pboss/file/pboss/cardinfo/
	#永不超时
	set timeout -1
	expect {
	"*assword*" {send "P_BOSS\\\$2017\r"; exp_continue }
	}
	#expect eof
	EOF
}


#增加一个判断卡数据文件是否成功上传至107主机
shhpd(){
	/usr/bin/expect <<-EOF
	set seq [lindex $argv 0]
	spawn ssh 192.168.106.107 "./IfCarddataUploadSucess.sh $seq"
	set timeout -1
	expect {
		"*assword*" {send "P_BOSS\\\$2017\r"; exp_continue }
	}
	EOF
}
#开始反馈
feedback(){
	if [[ $IMSI ]];
	then
		sed "s/1111111111/$k/g;s/2222222222/$a/g;s/3333333333/$namesave/g;s/4444444444/$keyname/g" /home/pboss/makecard/feedbackmodle.xml > ${dirpath}feedback.xml
		curl -v -X POST -H "content-Type:text/xml" -d @${dirpath}feedback.xml http://192.168.000.000:0000/interface4cdcs/services/PBOSSCardApplyResultNotice 2&>1 > ${dirpath}l
		RspCode=`grep 0000 ${dirpath}l`
		if [[ ${RspCode} != "" ]];
		then
			echo "[`date '+%F %T'`] 反馈成功!!!"
			rm -rf ${dirpathtime}
		fi
	fi
}


#增加一个发送报文的请求
sendmessages(){
	sed "s/$1/106481111/g;s/$2/999999/g" /home/pboss/makecard/messagesmodle.xml > ${dirpath}SendMessagesRule.xml
	curl -v -X POST -H "content-Type:text/xml" -d @${dirpath}SendMessagesRule.xml 
}



#cutmessages $1
#formats
#sshh $seq 
#> /dev/null 2>&1
#scpp ${datapath} ${dirpath} 
#> /dev/null 2>&1
#makecarddatas
#encryption
#scppp ${dirpath} ${namesave} ${keyname} 
#> /dev/null 2>&1
#feedback

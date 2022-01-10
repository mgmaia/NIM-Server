#!/bin/ksh
#########################################################
#
# Script execution image of the servers in the NIM Server
# Author: Mauricio Maia
# Organization: IBM
# Create Date: Apr 03, 2012
# Modify Date: Oct 26, 2012
#
#########################################################

export DIR_LOG=/usr/scripts
export LOG_SCRIPT=${DIR_LOG}/script_images_nim.log
export LOG_BKP_DB=${DIR_LOG}/db_nim_server.log
export DT_DB=`date +%d%m%Y`
export DT_VER=`date +%a" "%b" "%d`
export MAIL=mmaia@br.ibm.com


SND_MAIL()
{

echo "Sr(s),

Este e-mail esta sendo enviado com a intencao de informar o status dos backups dos servidores client no NIM Server.

Favor verificar os backups que possam ter ocorrido com problemas.


---------------------------------------------------------------
Status dos backups image dos clients

`cat ${LOG_SCRIPT}`


---------------------------------------------------------------
Status do Backup do DB do NIM Server

`cat ${LOG_BKP_DB}`


---------------------------------------------------------------
Att," > letter.txt

mail -s "$(echo "Backup NIM - ${DT_VER}\nFrom: mmaia@br.ibm.com\n")" mmaia@br.ibm.com < letter.txt
}



echo "`date +%c` --- Inicio dos Backups Images dos Servidores configurados no NIM Server" > ${LOG_SCRIPT}




### This step performs backup of the NIM Server DB

echo "`date +%c` --- Inicio do Backup DB NIM Server - U344" > ${LOG_BKP_DB}

/usr/lpp/bos.sysmgt/nim/methods/m_backup_db /export/images/bkp_db_nim/nimdb.backup_${DT_DB} >> ${LOG_BKP_DB}

if [ $? -ne 0 ]
then
                echo >> ${LOG_BKP_DB}
                echo "$(basename $0): Error in backing up NIM Database" >> ${LOG_BKP_DB}
                echo >> ${LOG_BKP_DB}
fi

echo "`date +%c` --- Termino do Backup DB NIM Server - U344" >> ${LOG_BKP_DB}





### of the "for" below check the hostnames configured the NIM Server for execution of the backup images 
###
#for SERVER in `lsnim -t standalone | grep machines | awk '{print $1}'`


# Modify the line below if you want to run the script manually and configure the servers to be executed
for SERVER in u423 u424

do
	export SERVER
	export ARQ_MKSYSB=/export/images/${SERVER}.mksysb
	export LOG_SERVER=/usr/scripts/${SERVER}.log

	echo "`date +%c` --- Inicio do Image do Servidor ${SERVER}" > ${LOG_SERVER}

# Remove old mksysb
	if [ -f ${ARQ_MKSYSB} ];
	then
		MK=`lsnim -t mksysb | grep resources | grep ${SERVER} | awk '{ print $1}'`;
		if [ "${MK}" = mksysb_${SERVER} ];
		then
			# Removing the old image to a new run.
			/usr/sbin/nim -o remove -a rm_image=yes mksysb_${SERVER};
		else
			/usr/bin/rm ${ARQ_MKSYSB};
		fi
	else
		MK=`lsnim -t mksysb | grep resources | grep ${SERVER} | awk '{ print $1}'`;
                if [ "${MK}" = mksysb_${SERVER} ];
                then
                        # Removing the old image to a new run.
                        /usr/sbin/nim -o remove mksysb_${SERVER};
		fi
	fi

# Create new mksysb
	nim -o define -t mksysb -F -a server=master -a mk_image=yes -a source=${SERVER} -a mksysb_flags=i -a location=${ARQ_MKSYSB} mksysb_${SERVER} 2>>${LOG_SERVER} 1>>${LOG_SERVER};


# Check mksysb backup status whether it is successful or not

	if [ -f ${ARQ_MKSYSB} ];
	then
		VER_OK=`lsmksysb -l -f ${ARQ_MKSYSB} | grep "${DT_VER}" | wc -l`;
		if [ ${VER_OK} -eq 1 ];
		then
			echo "${SERVER} --> Realizado backup Image com sucesso" >> ${LOG_SCRIPT};
		else
			echo "${SERVER} --> Backup Image NAO foi executado, favor verificar a log ${LOG_SERVER}" >> ${LOG_SCRIPT};
		fi
	else
		echo "${SERVER} --> Backup Image NAO foi executado, favor verificar a log ${LOG_SERVER}" >> ${LOG_SCRIPT};
	fi

	echo "`date +%c` --- Termino do Image do Servidor ${SERVER}" >> ${LOG_SERVER}

done

echo "`date +%c` --- Termino dos Backups Images dos Servidores configurados no NIM Server " >> ${LOG_SCRIPT}

# Send mail to user verify
SND_MAIL

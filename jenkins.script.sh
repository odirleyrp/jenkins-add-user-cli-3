#!/bin/bash
#Script para adicionar usuarios do Jenkins nos Jobs.
#Criado por Odirley Pereira.
#06/03/2020
#odirleyrp@gmail.com
#Criado um Job no Jenkins no qual utilizamos para obter dados de duas variaveis. 
#são elas $USER_JENKINS e $GRUPOR_JENKINS 

### Validar se diretorio tmp existe, caso contrário, será criado " ##3#

if [ -e "tmp/" ]
then
echo " o diretorio $JOB_NAME/tmp/  existe, apagando os arquivos dentro do diretorio"
rm -rf tmp/*
else
echo " o diretorio $JOB_NAME/tmp/ será criado."
mkdir tmp/
fi

#########################################


# Inserindo o valor das variáveis nos respectivos arquivos
echo $USER_JENKINS > tmp/user.txt
echo $GRUPO_JENKINS > tmp/grupo.txt

# Desclarando variaveis 
USER1=tmp/user.txt
GRUPO1=tmp/grupo.txt
 $(cat $ARQ2 )

# Informar os usuários e Grupos coletado nas variáveis

for  PROJ in  $(cat $USER1); do
		echo " usuario definido é  $PROJ"
done

for  PROJ1 in  $(cat $GRUPO1); do
		echo " O grupo  definido é  $PROJ1"
done

############ declaracao de novas variaveis   ###########

DIR1=tmp
L_USER=${USER1}
L_GRUPO=${GRUPO1}
L_JOBS=$DIR1/jobs.txt

# Limpa o arquivo da variavel L_JOBS
echo > $L_JOBS

# Coleta os jobs dos  Grupos listados na variavel L_GRUPO e envia  o nome de todos os jos para o  arquivo definido na variavel L_JOBS. Utiliza o grep para coletar apenas os nomes 
for GRUPO in $(cat $L_GRUPO); do
echo "Listando o grupo  $GRUPO"

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin get-view $GRUPO |grep string  |cut -d '>' -f 2 |cut  -d '<' -f 1 >> $L_JOBS

done

#retirar duplicidade de nomes e envia para um novo arquivo
cat $L_JOBS |sort |uniq > $DIR1/lista-limpa.txt

ARQ1=$DIR1/lista-limpa.txt
ARQ2=$DIR1/lista-projetos.txt
#grep prd  $ARQ1  > $DIR1/prod.txt
#PROD=$DIR1/prod.txt

#Acessa o arquivo gerado acima, e baixa o job  jogando os dados para um xml correspondente ao nome.
for ARQUIVO in `cat $L_JOBS`
do
    echo "Baixando o xml do job ${ARQUIVO} " 
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin get-job ${ARQUIVO} > $DIR1/${ARQUIVO}.xml
 #   sleep 2
done

## Ate aqui OK###############

#Arquivo da variavel $ARQ1 mais abaixo será retirado toda a menção a 'prd',  essa copia será utilizada para realizar o upload ao jenkins dos novos xml.
cp $ARQ1 $ARQ2


#Verificar se o usuario existe, se não ele adiciona no arquivo .xml .

for ARQUIVO  in `cat $ARQ1` 
do for USER in $(cat $L_USER); do
        if      cat $DIR1/${ARQUIVO}.xml |grep $USER > /dev/null
        then
               echo "Usuario  $USER exixte no job ${ARQUIVO}.xml "

######Verifica se o  projeto é prod pelo nome, se sim, insere as permissões e em seguida deleta da lista o nome desse projeto. 
 elif  echo $ARQUIVO |egrep -q 'prd' ; then

	echo "Inserindo o usuario $USER no job de PROD  $ARQUIVO  "
#	sleep 2


#then
		sed -i "/\/hudson.security.AuthorizationMatrixProperty/i <permission>com.cloudbees.plugins.credentials.CredentialsProvider.View:$USER</permission>'" $DIR1/${ARQUIVO}.xml
		sed -i "/\/hudson.security.AuthorizationMatrixProperty/i <permission>hudson.model.Item.Read:$USER</permission>'" $DIR1/${ARQUIVO}.xml
		sed -i "/\/hudson.security.AuthorizationMatrixProperty/i <permission>hudson.model.Item.Workspace:$USER</permission>'" $DIR1/${ARQUIVO}.xml
#		java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin update-job  ${ARQUIVO}  < $DIR1/${ARQUIVO}.xml

		sleep 2
	
		sed -i "/${ARQUIVO}/d" $ARQ1
#######################################################
### Insere nos demais projetos " HML - ACEITE - DEV) as permissões abaixo


        else
              echo "Inserindo o usuario $USER  no job ${ARQUIVO}.xml "
		sed -i "/\/hudson.security.AuthorizationMatrixProperty/i <permission>com.cloudbees.plugins.credentials.CredentialsProvider.View:$USER</permission>'" $DIR1/${ARQUIVO}.xml
		sed -i "/\/hudson.security.AuthorizationMatrixProperty/i <permission>hudson.model.Item.Read:$USER</permission>'" $DIR1/${ARQUIVO}.xml
		sed -i "/\/hudson.security.AuthorizationMatrixProperty/i <permission>hudson.model.Item.Workspace:$USER</permission>'" $DIR1/${ARQUIVO}.xml
		sed -i "/\/hudson.security.AuthorizationMatrixProperty/i <permission>hudson.model.Item.Build:$USER</permission>'" $DIR1/${ARQUIVO}.xml
		sed -i "/\/hudson.security.AuthorizationMatrixProperty/i <permission>hudson.model.Item.Cancel:$USER</permission>'" $DIR1/${ARQUIVO}.xml
#		java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin update-job  ${ARQUIVO}  < $DIR1/${ARQUIVO}.xml

       fi
done
done

#Realiza o UPLOAD dos .xml para o Jenkins, após todas as alterações.

for  PROJ in $(cat $ARQ2 ); do
#if echo $VAR1 |egrep -q "$GRUPO"; then
#		echo " $VAR1"
echo "realizando o uplodad de  $PROJ para o Jenkins"
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin update-job  ${PROJ}  < $DIR1/${PROJ}.xml
done
		

# BKP do diretorio gerado
#tar cf /tmp/$CHAMADO.tar.gz $DIR1

#Remover arquivos gerados.


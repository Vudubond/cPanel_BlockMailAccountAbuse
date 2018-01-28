#!/bin/bash

### Lista os dominios locais e exporta para um arquivo para usar em uma filtragem futura
whmapi1 listaccts  | grep domain | awk -F ":" '{print $2}' | sed "s/ /@/g" > /tmp/domainslocal

### Regra explicada cada parte entre | em uma linha
## Lista mensagens enviadas na última 1 hora
## Filtra apenas as linhas que contenham um e-mail válido
## Filtramos apenas o conteúdo dos e-mails que estão na 4 coluna
## Resumindo 3 comandos: Organiza de forma crescente, contabiliza os repetidos e reorganiza crescente
## Filtramos os remetentes com mais de 100 mensagens
## Resumindo 2 comandos: Ignoramos a quantidade e os caracteres "<" e ">" para usarmos apenas os e-mails
## Comparamos se os remetentes contem o dominios existentes no servidor (a lista que obtivemos no comando anterior)
exiqgrep -y 3600 | egrep "<*@.+>" | awk '{print $4}' | sort | uniq -c | sort -n | egrep "1[0-9]{1,2} <" | awk -F "<" '{print $2}' | awk -F ">" '{print $1}' | grep -f /tmp/domainslocal > /tmp/suspenderconta

### As regras a seguir pegam as contas que identificamos anteriormente e suspendem o login e envio de novas mensagens
## Ler o arquivo gerado anteriormente, gera um comando de API do WHM para obter o Usuario, seguido de executar o comando de suspensao de login e bloquear a fila
cat /tmp/suspenderconta | awk -F "@" '{print "whmapi1 listaccts search="$2" searchtype=domain | grep user" }' | sh | awk -F ": " '{print $2}' | xargs -I '{}' echo "uapi --user={} Email suspend_login email=`cat cat /tmp/suspenderconta`" | sh
cat /tmp/suspenderconta | awk -F "@" '{print "whmapi1 listaccts search="$2" searchtype=domain | grep user" }' | sh | awk -F ": " '{print $2}' | xargs -I '{}' echo "uapi --user={} Email hold_outgoing email=`cat cat /tmp/suspenderconta`" | sh
## Ler o arquivo gerado anteriormente e suspender o envio de mensagens pelo usuario, isso impede que um usuario ja logado continue a enviar mensagens
cat /tmp/suspenderconta | xargs -I '{}' whmapi1 suspend_outgoing_email user={}

### Reiniciamos o exim para termos certeza que a conta foi bloqueada
/scripts/restartsrv_exim

### Removemos o arquivo para não voltar a suspender o cliente após resolver a problema
rm -rf /tmp/suspenderconta

### Envia e-mail para um email alertando o bloqueio
echo "Bloqueamos o usuario por ter enviado mais de 100 mensagens na ultima hora para destinos que negaram a recepcao." | mail -s "Usuario `cat /tmp/suspenderconta` bloqueado em `hostname` por envio de SPAM" <email>;




#!/bin/bash
### searchspammer <TIME BEFORE in hour>

notify="YOUR_MAIL"

# Processa o Log em x horas
awk '($0 >= from)' from="$(LC_ALL=C date +'%Y-%m-%d %H:%M:%S' -d -${1}hour)" /var/log/exim_mainlog  | egrep "dovecot_[login|plain]" | egrep -v "failed|suspended|google" | sed "s/P=esmtps*a//g" | sed "s/X=.* CV=no//g" | sed "s/ (//g" | awk '{print $8 " " $7}' | awk -F":" '{print $2}' > /tmp/exim_login_

# Contar e imprimir quantidade de linhas de log
linen=`cat /tmp/exim_login_ | wc -l`
echo $linen 

# Processa o Log para obter logins e IPs
sort -n /tmp/exim_login_ | uniq -c | sort -n > /tmp/list_login_ip

## Imprime lista de account e quantidade de IPs que acessaram acima de 1000 logins
echo -e "\r\n---------   Lista de account que efetuaram logins de mais IPs    ---------"
echo -e "\tqtde \t login"
cat /tmp/list_login_ip | egrep "[0-9]{4,9} " > /tmp/top_logins
cat /tmp/top_logins

echo -e "\r\n\r\n ----------------------------------"

## Ler o export de logins suspeitos
for line in `cat /tmp/top_logins`; do
    # Pega apenas as contas
    if [[ $line =~ .*@.*  ]]; then
	### Envia e-mail para um email alertando o bloqueio
        echo "Bloqueamos o usuario "$line" por ter enviado cerca de "$linen" mensagens na ultima $1 hora(s) para destinos que negaram a recepcao." | mail -s "Usuario "$line" bloqueado em "`hostname`" por envio de SPAM" $notify
        # Suspende o login
        echo ${line} | awk -F "@" '{print "whmapi1 listaccts search="$2" searchtype=domain | grep user" }' | sh | awk -F ": " '{print $2}' | xargs -I '{}' echo "uapi --user={} Email suspend_login email="${line} | sh > /dev/null
        echo ${line} | awk -F "@" '{print "whmapi1 listaccts search="$2" searchtype=domain | grep user" }' | sh | awk -F ": " '{print $2}' | xargs -I '{}' echo "uapi --user={} Email hold_outgoing email="${line} | sh > /dev/null
        echo -e "\r\n -----------------------------\r\n Conta $line Suspensa"
    fi
done

## Remover arquivos
rm /tmp/exim_login_
rm /tmp/list_login_ip
rm /tmp/top_logins

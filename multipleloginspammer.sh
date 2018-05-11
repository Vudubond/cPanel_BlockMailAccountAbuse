#!/bin/bash
### searchspammer <horas de log>

notify="YOUR_MAIL"

# Processa o Log em x horas
awk '($0 >= from)' from="$(LC_ALL=C date +'%Y-%m-%d %H:%M:%S' -d -${1}hour)" /var/log/exim_mainlog  | egrep "dovecot_[login|plain]" | egrep -v "failed|suspended|google" | sed "s/P=esmtps*a//g" | sed "s/X=.* CV=no//g" | sed "s/ (//g" | awk '{print $8 " " $7}' | awk -F":" '{print $2}' > /tmp/exim_login_

# Contar e imprimir quantidade de linhas de log
linen=`cat /tmp/exim_login_ | wc -l`
echo $linen 

# Processa o Log para obter logins e IPs
sort -n /tmp/exim_login_ | uniq -c | sort -n > /tmp/list_login_ip
# Processa a saida anterior para contabilizar de quantos IPs uma conta foi acessada
awk '{print $2}' /tmp/list_login_ip | sort -n | uniq -c | sort -n | egrep -v "[1-5] " > /tmp/list_multlogin

## Imprime lista de account e quantidade de IPs que acessaram
echo -e "\r\n---------   Lista de account que efetuaram logins de mais IPs    ---------"
echo -e "\tqtde \t login"
cat /tmp/list_multlogin

## Processa a lista e exibe a conta e a quantidade de login por IP
echo -e "\r\n-------   Origem de logins    -------"
echo -e "\tqtde \t login \t [IP]"
cat /tmp/list_multlogin | awk '{print $2}' > /tmp/multlogin2
cat /tmp/list_login_ip | grep -f /tmp/multlogin2

echo -e "\r\n\r\n ----------------------------------"

## Ler o export de logins suspeitos
for line in `cat /tmp/multlogin2`; do
    # Pega apenas as contas
    if [[ $line =~ .*@.*  ]]; then
        ### Envia e-mail para um email alertando o bloqueio
	    echo "Bloqueamos o usuario "$line" por ter realizado login em mais de 5 endereços IPs na ultima $1 hora(s), isso foi considerada uma atividade suspeita." | mail -s "Usuario "$line" bloqueado em "`hostname`" por envio de SPAM" $notify
        # Suspende o login
        echo ${line} | awk -F "@" '{print "whmapi1 listaccts search="$2" searchtype=domain | grep user" }' | sh | awk -F ": " '{print $2}' | xargs -I '{}' echo "uapi --user={} Email suspend_login email="${line} | sh > /dev/null
        echo ${line} | awk -F "@" '{print "whmapi1 listaccts search="$2" searchtype=domain | grep user" }' | sh | awk -F ": " '{print $2}' | xargs -I '{}' echo "uapi --user={} Email hold_outgoing email="${line} | sh > /dev/null
        echo -e "\r\n -----------------------------\r\n Conta $line Suspensa"
    fi
done


## Remover arquivos
rm /tmp/exim_login_
rm /tmp/list_login_ip
rm /tmp/list_multlogin
rm /tmp/multlogin2

# cPanel_BlockMailAccountAbuse

Tests for a function that will identify SPAMMERS and block the abused account.

Just an outline of an idea, not tested.
--------------------------------------------------------------------

Testes para uma função que irá identificar um SPAMMER que esteja abusando de uma conta e bloquea-lo automáticamente.

Ainda estou testando o conceito da ideia. Os grandes eventos de SPAM diminuiram o que tem dificultado testes e ideias.


O objetivo será identificar uma conta que tenha enviado uma grande quantidade de mensagens e evitar que uma conta cPanel seja abusada.

Como tive uma redução dos eventos grandes de SPAM, e pelo risco de bloquear usuários legitimos, uma ideia alternativa que poderá ser implementada é a identificação de uma conta que recebeu login de múltiplos IPs e bloquea-la, pois esse não é um comportamento comum. Podemos cruzar essa ideia com a de volumetria acima para que só sejam contadas as contas que tenham multiplos IPs de login.


O Script massivespammer.sh <hour> irá buscar no log as linhas que representem logins de um usuário, se nesse tempo X uma conta tiver realizado mais de 100 logins será suspensa usando as API do cPanel/WHM e em seguida irá disparar um e-mail notificando.
  
O Script blockspammer.sh é apenas um teste preliminar, que será descartado no futuro.

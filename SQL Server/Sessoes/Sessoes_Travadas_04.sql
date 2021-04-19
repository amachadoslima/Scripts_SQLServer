USE master 
GO
BEGIN

	set nocount on
	set quoted_identifier off

	if(object_id(N'tempdb..#tmpLock') is not null)
		drop table #tmpLock

	create table #tmpLock
	(
		spid smallint,
		[dbid] smallint,
		[objid] int,
		indid smallint,
		tipo nchar(4),
		kit nchar(32),
		modo nvarchar(8),
		[status] nvarchar(5)
	)
	
	insert into #tmpLock
		exec sp_lock;
	
	select 
			spid,
			db_name([dbid]) as [db_name],
			object_name([objid], [dbid]) as obj_name,
			indid,
			case tipo
				when 'RID' then 'RID = Bloqueio em uma �nica linha na tabela identificada por um identificador de linha (RID).'
				when 'KEY' then 'KEY = Bloqueio dentro de um �ndice que protege um intervalo de chaves em transa��es serializ�veis.'
				when 'PAG' then 'PAG = Bloqueio em uma p�gina de dados ou de �ndice.'
				when 'EXT' then 'EXT = Bloqueio em uma extens�o.'
				when 'TAB' then 'TAB = Bloqueio em uma tabela inteira, inclusive todos os dados e �ndices.'
				when 'DB' then 'DB = Bloqueio em um banco de dados.'
				when 'FIL' then 'FIL = Bloqueio em um arquivo de banco de dados.'
				when 'APP' then 'APP = Bloqueio em um recurso de aplicativo especificado.'
				when 'MD' then 'MD = Bloqueio em metadados ou informa��es do cat�logo.'
				when 'HBT' then 'HBT = Lock em um heap ou �rvore B (HoBT). Essas informa��es est�o incompletas no SQL Server.'
				when 'AU' then 'AU = Bloqueio em uma unidade de aloca��o. Essas informa��es est�o incompletas no SQL Server.'
			end as tipo,
			rtrim(ltrim(kit)) as kit,
			modo,
			[status]
		from #tmpLock
		where spid <> @@spid
			and object_name([objid], [dbid]) is not null
		order by spid
	
	if(object_id(N'tempdb..#tmpLock') is not null)
		drop table #tmpLock

END

/*
O estado de solicita��o do bloqueio:
CNVRT: O bloqueio est� sendo convertido de outro modo, mas a convers�o est� bloqueada por outro processo que mant�m um bloqueio com um modo conflitante.
GRANT: O bloqueio foi obtido.
WAIT: O bloqueio est� bloqueado por outro processo que mant�m um bloqueio com um modo conflitante.


O modo de bloqueio solicitado. Pode ser:
NULL = Nenhum acesso concedido ao recurso. Funciona como espa�o reservado.
Sch-S = Estabilidade do esquema. Assegura que um elemento de esquema, como uma tabela ou �ndice, n�o seja cancelado enquanto qualquer sess�o mant�m o bloqueio de estabilidade do esquema no elemento do esquema.
Sch-M = Modifica��o do esquema. Deve ser mantido por qualquer sess�o que desejar alterar o esquema do recurso especificado. Assegura que nenhuma outra sess�o esteja fazendo refer�ncia ao objeto indicado.
S = Compartilhado. A sess�o mantenedora possui acesso compartilhado ao recurso.
U = Atualizar. Indica um bloqueio de atualiza��o adquirido em recursos que podem ser atualizados eventualmente. � usado para evitar uma forma comum de deadlock que ocorre quando v�rias sess�es bloqueiam recursos para uma atualiza��o potencial em um momento posterior.
X = Exclusivo. A sess�o mantenedora possui acesso exclusivo ao recurso.
IS = Tentativa compartilhada. Indica a inten��o de colocar bloqueios S em algum recurso subordinado na hierarquia de bloqueio.
IU = Atualiza��o da tentativa. Indica a inten��o de colocar bloqueios U em algum recurso subordinado na hierarquia de bloqueio.
IX = Exclusivo da tentativa. Indica a inten��o de colocar bloqueios X em algum recurso subordinado na hierarquia de bloqueio.
SIU = Atualiza��o da tentativa compartilhada. Indica o acesso compartilhado a um recurso com a inten��o de adquirir bloqueios de atualiza��o em recursos subordinados na hierarquia de bloqueio.
SIX = Exclusivo da tentativa compartilhada. Indica o acesso compartilhado a um recurso com a inten��o de adquirir bloqueios exclusivos em recursos subordinados na hierarquia de bloqueio.
UIX = Atualizar exclusivo da tentativa. Indica a manuten��o de um bloqueio de atualiza��o de um recurso com a inten��o de adquirir bloqueios exclusivos em recursos subordinados na hierarquia de bloqueio.
BU = Atualiza��o em massa. Usado por opera��es em massa.
RangeS_S = Intervalo de chave compartilhada e bloqueio de recurso compartilhado. Indica varredura de intervalo serializ�vel.
RangeS_U = Intervalo de chave compartilhada e bloqueio de recurso de atualiza��o. Indica verifica��o de atualiza��o serializ�vel.
RangeI_N = Intervalo de chave de inser��o e bloqueio de recurso nulo. Usado para testar intervalos antes de inserir uma nova chave em um �ndice.
RangeI_S = Bloqueio de convers�o do intervalo de chave. Criado por uma sobreposi��o dos bloqueios RangeI_N e S.
RangeI_U = Bloqueio de convers�o de intervalo de chave criado por uma sobreposi��o dos bloqueios RangeI_N e U.
RangeI_X = Bloqueio de convers�o de intervalo de chave criado por uma sobreposi��o dos bloqueios RangeI_N e X.
RangeX_S = Bloqueio de convers�o de intervalo de chaves criado por uma sobreposi��o de bloqueios RangeI_N e RangeS-S.
RangeIX_U = Bloqueio de convers�o de intervalo de chave criado por uma sobreposi��o dos bloqueios RangeI_N e RangeS-U.
RangeX_X = Bloqueio de intervalo de chave exclusivo e de recurso exclusivo. Este � um bloqueio de convers�o usado na atualiza��o de uma chave em um intervalo.
*/
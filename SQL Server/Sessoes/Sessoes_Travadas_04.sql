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
				when 'RID' then 'RID = Bloqueio em uma única linha na tabela identificada por um identificador de linha (RID).'
				when 'KEY' then 'KEY = Bloqueio dentro de um índice que protege um intervalo de chaves em transações serializáveis.'
				when 'PAG' then 'PAG = Bloqueio em uma página de dados ou de índice.'
				when 'EXT' then 'EXT = Bloqueio em uma extensão.'
				when 'TAB' then 'TAB = Bloqueio em uma tabela inteira, inclusive todos os dados e índices.'
				when 'DB' then 'DB = Bloqueio em um banco de dados.'
				when 'FIL' then 'FIL = Bloqueio em um arquivo de banco de dados.'
				when 'APP' then 'APP = Bloqueio em um recurso de aplicativo especificado.'
				when 'MD' then 'MD = Bloqueio em metadados ou informações do catálogo.'
				when 'HBT' then 'HBT = Lock em um heap ou árvore B (HoBT). Essas informações estão incompletas no SQL Server.'
				when 'AU' then 'AU = Bloqueio em uma unidade de alocação. Essas informações estão incompletas no SQL Server.'
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
O estado de solicitação do bloqueio:
CNVRT: O bloqueio está sendo convertido de outro modo, mas a conversão está bloqueada por outro processo que mantém um bloqueio com um modo conflitante.
GRANT: O bloqueio foi obtido.
WAIT: O bloqueio está bloqueado por outro processo que mantém um bloqueio com um modo conflitante.


O modo de bloqueio solicitado. Pode ser:
NULL = Nenhum acesso concedido ao recurso. Funciona como espaço reservado.
Sch-S = Estabilidade do esquema. Assegura que um elemento de esquema, como uma tabela ou índice, não seja cancelado enquanto qualquer sessão mantém o bloqueio de estabilidade do esquema no elemento do esquema.
Sch-M = Modificação do esquema. Deve ser mantido por qualquer sessão que desejar alterar o esquema do recurso especificado. Assegura que nenhuma outra sessão esteja fazendo referência ao objeto indicado.
S = Compartilhado. A sessão mantenedora possui acesso compartilhado ao recurso.
U = Atualizar. Indica um bloqueio de atualização adquirido em recursos que podem ser atualizados eventualmente. É usado para evitar uma forma comum de deadlock que ocorre quando várias sessões bloqueiam recursos para uma atualização potencial em um momento posterior.
X = Exclusivo. A sessão mantenedora possui acesso exclusivo ao recurso.
IS = Tentativa compartilhada. Indica a intenção de colocar bloqueios S em algum recurso subordinado na hierarquia de bloqueio.
IU = Atualização da tentativa. Indica a intenção de colocar bloqueios U em algum recurso subordinado na hierarquia de bloqueio.
IX = Exclusivo da tentativa. Indica a intenção de colocar bloqueios X em algum recurso subordinado na hierarquia de bloqueio.
SIU = Atualização da tentativa compartilhada. Indica o acesso compartilhado a um recurso com a intenção de adquirir bloqueios de atualização em recursos subordinados na hierarquia de bloqueio.
SIX = Exclusivo da tentativa compartilhada. Indica o acesso compartilhado a um recurso com a intenção de adquirir bloqueios exclusivos em recursos subordinados na hierarquia de bloqueio.
UIX = Atualizar exclusivo da tentativa. Indica a manutenção de um bloqueio de atualização de um recurso com a intenção de adquirir bloqueios exclusivos em recursos subordinados na hierarquia de bloqueio.
BU = Atualização em massa. Usado por operações em massa.
RangeS_S = Intervalo de chave compartilhada e bloqueio de recurso compartilhado. Indica varredura de intervalo serializável.
RangeS_U = Intervalo de chave compartilhada e bloqueio de recurso de atualização. Indica verificação de atualização serializável.
RangeI_N = Intervalo de chave de inserção e bloqueio de recurso nulo. Usado para testar intervalos antes de inserir uma nova chave em um índice.
RangeI_S = Bloqueio de conversão do intervalo de chave. Criado por uma sobreposição dos bloqueios RangeI_N e S.
RangeI_U = Bloqueio de conversão de intervalo de chave criado por uma sobreposição dos bloqueios RangeI_N e U.
RangeI_X = Bloqueio de conversão de intervalo de chave criado por uma sobreposição dos bloqueios RangeI_N e X.
RangeX_S = Bloqueio de conversão de intervalo de chaves criado por uma sobreposição de bloqueios RangeI_N e RangeS-S.
RangeIX_U = Bloqueio de conversão de intervalo de chave criado por uma sobreposição dos bloqueios RangeI_N e RangeS-U.
RangeX_X = Bloqueio de intervalo de chave exclusivo e de recurso exclusivo. Este é um bloqueio de conversão usado na atualização de uma chave em um intervalo.
*/
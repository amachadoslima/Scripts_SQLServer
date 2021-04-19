set ansi_warnings off
go

declare 
	@nometabela		varchar(100), 
	@nomecoluna		varchar(100),
	@cmd			varchar(max)

set @nometabela = 'cont_contagem'

declare curvalue cursor for

select b.[name]
	from sys.tables a
		join sys.columns b on a.[object_id] = b.[object_id]
	where a.[name] = @nometabela
	order by b.[name]

open curvalue
fetch next from curvalue into @nomecoluna
	
	while (@@fetch_status = 0)
	begin
		select
				@cmd = 'if (select count(distinct [' + @nomecoluna + ']) from [' + @nometabela + ']) = 1 
						or isnull((select count(distinct [' + @nomecoluna + ']) from [' + @nometabela + ']), 1) = 0 
						begin print ''' + @nomecoluna + ''' end'
		--print @cmd
		exec(@cmd)

		fetch next from curvalue into @nomecoluna
	end
	
close curvalue
deallocate curvalue

set ansi_warnings off
go
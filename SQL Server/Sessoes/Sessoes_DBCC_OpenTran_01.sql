set nocount on

declare @dbname nvarchar(50)

declare dbname cursor for 
	
	select distinct c.[name]
		from sys.dm_tran_session_transactions a
			join sys.dm_tran_database_transactions b on a.transaction_id = b.transaction_id
			join sys.databases c on b.database_id = c.database_id 
			join sys.dm_exec_sessions s on a.session_id = s.session_id
		where a.session_id > 50

open dbname
fetch next from dbname into @dbname

    while @@fetch_status = 0
    begin
		declare @cmd nvarchar(4000);
		set @cmd = 'dbcc opentran([' + @dbname + ']) with tableresults, no_infomsgs;';
		--select @dbname  as dbname
		exec(@cmd)

        fetch next from dbname into @dbname
	end

close dbname
deallocate dbname

set nocount off
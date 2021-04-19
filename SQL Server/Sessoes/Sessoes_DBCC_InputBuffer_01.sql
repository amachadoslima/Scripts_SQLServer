 set nocount on

declare @session_id nvarchar(50)

declare session_id cursor for 
	
	select session_id
		from sys.dm_exec_requests
	--where	open_transaction_count > 0 
		where session_id > 50 and session_id <> @@spid

open session_id
fetch next from session_id into @session_id

    while @@fetch_status = 0
    begin

		declare @cmd nvarchar(4000);
		set @cmd = 'dbcc inputbuffer(' + @session_id + ') with no_infomsgs';
		select @session_id  as session_id
		exec(@cmd)

        fetch next from session_id into @session_id
	end

close session_id
deallocate session_id

set nocount off
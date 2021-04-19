set nocount on

declare @pendingIO int

select @pendingIO  = sum(pending_disk_io_count) 
	from sys.dm_os_schedulers 

if(@pendingIO > 0)
begin
	select *  
		from sys.dm_io_pending_io_requests
end
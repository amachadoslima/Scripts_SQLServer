use master 
go
select 
		spid,
		kpid,
		blocked,
		d.[name],
		open_tran,
		[status],
		hostname,
		cmd,
		login_time,
		loginame,
		net_library
	from sys.sysprocesses p
		join sys.databases d on p.[dbid] = d.database_id
	where spid > 50 and spid <> @@spid 
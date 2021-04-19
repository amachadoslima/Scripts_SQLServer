select 
		spid,
		kpid,
		login_time,
		last_batch,
		[status],
		hostname,
		nt_username,
		loginame,
		hostprocess,
		cpu,
		memusage,
		physical_io
	from sys.sysprocesses
	where lower(cmd) = 'killed/rollback'
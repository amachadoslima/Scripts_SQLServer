select * 
	from sys.sysprocesses 
	where open_tran = 1
	
dbcc opentran
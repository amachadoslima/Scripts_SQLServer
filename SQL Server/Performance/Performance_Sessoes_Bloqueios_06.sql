select *
	from master.dbo.sysprocesses
	where spid > 50
		and ((blocked != 0))

--dbcc inputbuffer(119);
--dbcc inputbuffer(94);
--dbcc inputbuffer(89);

--use dataunify;
--select * from sys.tables where object_id = '1429580131' 
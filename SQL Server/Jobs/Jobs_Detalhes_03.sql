use msdb
go
begin

	select
			j.[name] as JobName,
			dbo.SQLAGENT_SUSER_SNAME(j.owner_sid) as JobOwner,
			j.[Description],
			c.[name] as Category,
			'EXEC msdb.dbo.sp_update_job @job_id=N'''+cast(job_id as varchar(150))+''', @owner_login_name=N''sa'' ' as RunCode
		from sysjobs j
			join syscategories C on C.category_id = J.category_id
		where dbo.SQLAGENT_SUSER_SNAME(j.owner_sid) = 'sa'
		order by j.[name] asc

end
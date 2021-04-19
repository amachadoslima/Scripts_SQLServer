set nocount on
go
declare @tbinfo table
(
	spid			int,
	[status]		char(30),
	[login]			char(40),
	[host_name]		char(40),
	blk_by			char(40),
	[db_name]		char(40),
	command			varchar(max),
	cpu_time		int,
	disk_io			int,
	last_batch		char(14),
	[program_name]	char(610),
	sp_idx			int,
	request_id		int
)

insert into @tbinfo 
	exec master.dbo.sp_who2
	
select * 
	from @tbinfo 
	where [db_name] = db_name(db_id()) 
		and spid <> @@spid and spid >= 50
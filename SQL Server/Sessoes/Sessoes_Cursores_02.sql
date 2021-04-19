begin

	set nocount on
	set quoted_identifier off

	if(object_id(N'tempdb..#tmpapicursor') is not null)
		drop table #tmpapicursor

	declare @tb table
	(
		session_id int,
		properties nvarchar(256),
		creation_time datetime,
		is_open bit,
		[text] varchar(max)
	)

	create table #tmpapicursor
	(
		id int identity(1,1),
		session_id varchar(100),
		properties varchar(500),
		creation_time varchar(50),
		is_open varchar(100),
		[text] varchar(max)
	)

	declare @delay int
	declare @mindur int
	declare @delayW char(8)
	declare @dteini datetime

	set @delay = 1
	set @delayW = '00:00:' + replicate('0', 2 - len(@delay)) + rtrim(@delay)
	set @mindur = 3 * 60
	set @dteini = getdate()

	while(datediff(second, @dteIni, getdate()) <= @mindur)
	begin

		delete from @tb
		;with cte as
		(
			select
					session_id, 
					[text]
				from sys.dm_exec_connections c
					cross apply sys.dm_exec_sql_text(c.most_recent_sql_handle) t
				where lower([text]) like 'FETCH API_CURSOR%'
		)
		insert into @tb
			select distinct c.session_id, c.properties, c.creation_time, c.is_open, t.[text]
				from cte 
					cross apply sys.dm_exec_cursors(session_id) c
					cross apply sys.dm_exec_sql_text(c.[sql_handle]) t

		if(@@rowcount <> 0)
		begin
			insert into #tmpapicursor
				select 
						cast(session_id as varchar),
						properties,
						convert(varchar(23), creation_time, 121),
						cast(is_open as varchar),
						[text]
					from @tb
			
			insert into #tmpapicursor
				select '------', '------', '------', '------', '------'
				
		end

		waitfor delay @delayW

	end

	delete from #tmpapicursor where id = (select max(id) from #tmpapicursor where isnull([session_id], '------') = '------')
	select * from #tmpapicursor order by id
	
	/*
	;with cte as
	(
		select rn = row_number() over(partition by session_id, properties, creation_time, is_open, [text] order by creation_time asc), *
			from #tmpapicursor
	)
	select
			session_id,
			properties,
			creation_time,
			is_open,
			[text]
		from cte
		where rn = 1
		order by creation_time asc
	*/

	if(object_id(N'tempdb..#tmpapicursor') is not null)
		drop table #tmpapicursor

end
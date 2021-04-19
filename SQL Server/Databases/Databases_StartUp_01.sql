declare @tberro table
(
	log_date		datetime,
	process_info	char(20),
	[text]			varchar(max)
)

insert into @tberro 
	exec master.dbo.xp_readerrorlog
	
select * from @tberro where lower([text]) like '%starta%' order by log_date desc
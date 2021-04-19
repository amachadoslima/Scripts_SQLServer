declare @ini datetime
declare @fim datetime
	
set @ini = getdate() - 2
set @fim = getdate()

if(object_id(N'tempdb..#errorlog') is not null)
	drop table #errorlog;

create table #errorlog 
(
	 log_date		datetime
    ,process_info	varchar(max)
    ,[message]		varchar(max)
)

insert #errorlog(log_date, process_info, [message])
   exec master.dbo.xp_readerrorlog 0, 1, null, null, @ini, @fim, N'desc'

select 
		log_date, 
		[message] 
	from #errorlog
	where (lower([message]) like '%erro%' or lower([message]) like '%failed%') 
		and	lower(process_info) not like 'logon'
	order by log_date desc

if(object_id(N'tempdb..#errorlog') is not null)
	drop table #errorlog;
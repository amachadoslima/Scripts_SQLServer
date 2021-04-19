set nocount on 
 
if(object_id('tempdb..#errorLogs') is not null)
	drop table #errorLogs 

if(object_id('tempdb..#logData') is not null) 
	drop table #logData 
 
declare @maxlog int
declare @searchstr varchar(256)
declare @startdate datetime = null

select @startdate = LASTDATE from master.dbo.DBA

if(@startdate is null)
	set @startdate = dateadd(day, -5, getdate())
 
create table #errorLogs   
( 
    log_id int, 
    log_date datetime, 
    log_size bigint
)

create table #logData       
( 
    log_date datetime,
    proc_info varchar(64), 
    log_text varchar(max)
) 
 
insert into #errorLogs 
	exec sys.sp_enumerrorlogs
 
delete from #errorLogs where [log_date] < @startdate 

select  @maxlog = max(log_id) 
	FROM #errorLogs 
	where [log_date] >= @startdate 
	---ORDER BY [LogDate] DESC; 
 
while(@maxlog >= 0)
begin

    insert into #logData 
		EXEC sys.sp_readerrorlog @maxlog, 1, @searchstr; 
    set @maxlog = @maxlog - 1; 
end 
 
select *  
	from ( 
		select  
			log_date,
			substring(replace(log_text, 'sql server has encountered ', ''), 0, charindex('o', replace(log_text, 'sql server has encountered ',''))) ocurrences,
			replace(substring(substring(log_text, charindex('[',log_text), 100), 0, charindex('\', substring(log_text, charindex('[', log_text), 100))), '[','') drive_letter,
			substring(substring(substring(log_text, charindex('[',log_text), 500), charindex('\', substring(log_text, charindex('[', log_text), 500)), 500), 0, 
					charindex('(', substring(substring(log_text, charindex('[', log_text), 500),charindex('\', substring(log_text, charindex('[', log_text), 500)), 500))) as data_file
		from #logData 
		where log_text like '%i/o%'
			and log_date >= @startdate
	) as x 
	where x.drive_letter <>'' 
	order by 1 desc
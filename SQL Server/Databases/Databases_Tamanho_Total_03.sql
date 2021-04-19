use tempdb  
go 
set nocount on
go 
  
if(object_id(N'tempdb..#tbsize')  is not null)
	drop table #tbsize;
  
create table #tbsize 
( 
     [db_name]      sysname 
    ,db_cod         int
    ,filesize_mb    decimal(12,2) 
    ,spaceused_mb   decimal(12,2) 
    ,freespace_mb   decimal(12,2) 
)    
  
exec sp_MSforeachdb
    'use [?] 
        insert into #tbsize 
            select 
                  db_name() as [db_name]
                , db_id() as [db_cod] 
                , sum(convert(decimal(12,2),  
                    round(a.size / 128.000, 2))) as filesizemb 
                , sum(convert(decimal(12,2),  
                    round(fileproperty(a.name,''spaceused'') / 128.000, 2))) as spaceusedmb 
                , sum(convert(decimal(12,2),  
                    round((a.size - fileproperty(a.name,''spaceused'')) / 128.000, 2))) as freespacemb 
            from  
                dbo.sysfiles a  
    '
-- 
select 
		a.[db_name],
		a.filesize_mb,
		convert(int,((a.filesize_mb * 0.3) + a.filesize_mb)) as growth,
		a.spaceused_mb,  
		a.freespace_mb, 
		'---' as '---',
		convert(decimal(12,2),(100 * (a.spaceused_mb / a.filesize_mb))) as percentused,
		convert(decimal(12,2),(100 * (a.freespace_mb / a.filesize_mb))) as percentfree 
	from #tbsize a 
		join sys.databases b on a.db_cod = b.database_id     
	order by 8 --a.db_cod
  
if(object_id(N'tempdb..#tbsize')  is not null)
	drop table #tbsize;
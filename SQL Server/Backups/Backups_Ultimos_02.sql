use master
go
set nocount on
go

declare @database_name	sysname
declare @finish_date		datetime
declare @diff				int

declare @thresholdfull		int
declare @thresholddiff		int
declare @thresholdlog		int 
declare @msg				char(200)
	
set @thresholdfull = 7
set @thresholddiff = 24
set @thresholdlog  = 1

declare @lenstring		int
declare @tbinfo table
(
	info	char(200)
)

print '========== backup full =========='

declare curbkpdatabase cursor for
	select rtrim(ltrim([database_name])), max(backup_finish_date), datediff(day, max(backup_finish_date), getdate())
		from msdb.dbo.backupset
		where type = 'd'
			and	[database_name] in(select name from sys.databases where state <> 6)
		group by [database_name]
		order by [database_name]

open curbkpdatabase
fetch next from curbkpdatabase into @database_name, @finish_date, @diff

while(@@fetch_status = 0)
begin
	set @msg = null
	set @lenstring  = len(@database_name)
		
	set @msg = 'database: ' + @database_name + space(30 - @lenstring) + 
				' | ultimo backup full: ' + convert(char(19), @finish_date, 121)
		
	if(@diff > @thresholdfull)
		print 'alerta: ' + @database_name + ' sem bkp full há ' + rtrim(ltrim(convert(char,@diff))) + ' dias!'
		
	insert into @tbinfo values (@msg)
	fetch next from curbkpdatabase into @database_name, @finish_date, @diff

end

close curbkpdatabase
deallocate curbkpdatabase

if((select count(*) from @tbinfo) > 0 )
	select * from @tbinfo
else 
	print 'nenhum backup full realizado!'


delete from @tbinfo
print ''
print '========== backup differential =========='

declare curbkpdatabase cursor for
	select rtrim(ltrim([database_name])), max(backup_finish_date), datediff(hour, max(backup_finish_date), getdate())
		from msdb.dbo.backupset
		where lower([type]) = 'i'
			and	[database_name] in(select name from sys.databases where state <> 6)
		group by [database_name]
		order by [database_name]

open curbkpdatabase
fetch next from curbkpdatabase into @database_name, @finish_date, @diff

while(@@fetch_status = 0)
begin

	set @msg = null
	set @lenstring  = len(@database_name)
		
	set @msg = 'database: ' + @database_name + space(30 - @lenstring) + 
				' | ultimo backup diff: ' + convert(char(19), @finish_date, 121)
		
	if(@diff > @thresholddiff)
		print 'alerta: ' + @database_name + ' sem bkp diff há ' + rtrim(ltrim(convert(char,@diff))) + ' minutos!'
		
	insert into @tbinfo values (@msg)				
	fetch next from curbkpdatabase into @database_name, @finish_date, @diff

end
close curbkpdatabase
deallocate curbkpdatabase

if (select count(*) from @tbinfo) > 0 
	select * from @tbinfo
else 
	print 'nenhum backup differential realizado!'


delete from @tbinfo
print ''
print '========== backup log =========='

declare curbkpdatabase cursor for
	select rtrim(ltrim([database_name])), max(backup_finish_date), datediff(day, max(backup_finish_date), getdate())
		from msdb.dbo.backupset
		where lower([type]) = 'l'
			and	[database_name] in(select [name] from sys.databases where state <> 6)
		group by [database_name]
		order by [database_name]

open curbkpdatabase
fetch next from curbkpdatabase into @database_name, @finish_date, @diff

while(@@fetch_status = 0)
begin

	set @msg = null
	set @lenstring  = len(@database_name)
		
	set @msg = 'database: ' + @database_name + space(30 - @lenstring) + 
				' | ultimo backup log: ' + convert(char(19), @finish_date, 121)
		
	if(@diff > @thresholdlog)
	begin
		print 'alerta: ' + @database_name + ' sem bkp log há ' + rtrim(ltrim(convert(char,@diff))) + ' dias!'
	end	
		
	insert into @tbinfo values (@msg)				
	fetch next from curbkpdatabase into @database_name, @finish_date, @diff

end

close curbkpdatabase
deallocate curbkpdatabase

if (select count(*) from @tbinfo) > 0 
	select * from @tbinfo
else
	print 'nenhum backup log realizado!'

declare @horas		int 
declare @minutos	int 
declare @dias		int 
declare @data		datetime
declare @msg		varchar(150)
	
select	
		@data = crdate, 
		@horas = (datediff(minute, crdate, getdate())  / 60), 
		@minutos = datediff(minute, crdate, getdate()), 
		@dias = datediff(day, crdate, getdate())
	from sys.sysdatabases 
	where [dbid] = 2
	
if (@horas / 24) > 0
begin
	set @horas = (@horas / 24)
end

if (@minutos / 60) != 0
begin
	set @minutos = (datediff(minute, @data, getdate()) - ((datediff(minute, @data, getdate())) / 60) * 60)
end

set @msg = 'SQL Server "' + rtrim(ltrim(convert(char, serverproperty('servername')))) + '\' + @@servicename + '" está online há ' +
			+ rtrim(ltrim(convert(char, @dias))) + ' dia(s) e ' + rtrim(ltrim(convert(char, @horas))) 
			+ ' hora(s) e ' + rtrim(ltrim(convert(char, @minutos))) + ' minutos. iniciado as: "' 
			+ rtrim(ltrim(convert(char(19), @data, 121))) + '"'
			
print @msg

if not exists(select 1 from master.dbo.sysprocesses where [program_name] like N'%SQLAgent%')
begin
	set @msg = 'Alerta: SQL Server online, porém o SQL Server Agent está OFFLINE!'
end
else begin
	set @msg = 'SQL Server e SQL Server Agent online.'
end

print @msg
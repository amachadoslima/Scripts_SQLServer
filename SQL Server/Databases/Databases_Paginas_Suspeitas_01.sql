select
		a.database_id,
		b.[name],
		[file_id],
		page_id,
		event_type = 
			case event_type
				when 1 then 'erro 823 (erro de disco) - erro 824 (id da pag. invalido'
				when 2 then 'soma de verificação inválido'
				when 3 then 'página interrompida'
				when 4 then 'restaurada'
				when 5 then 'reparada'
				when 7 then 'deslocada para dbcc'
				else null end,
		error_count,
		last_update_date,
		isnull(datediff(minute, last_update_date, getdate()), 0) as diff_min
	from msdb.dbo.suspect_pages a
		join sys.databases b on a.database_id = b.database_id

-- http://msdn.microsoft.com/pt-br/library/ms174425.aspx
BEGIN

	SELECT 
			O.[name],
			P.[rows] As Linhas,
			SUM(a.total_pages * 8) As Reservado,
			SUM(CASE WHEN P.index_id > 1 THEN 0 ELSE a.data_pages * 8 END) As Dados,
			SUM(a.used_pages * 8) - SUM(CASE WHEN P.index_id > 1 THEN 0 ELSE a.data_pages * 8 END) As Indice,
			SUM((a.total_pages - a.used_pages) * 8) As NaoUtilizado,
			SUM(a.total_pages) Paginas_reservadas,
			SUM(a.data_pages)  Paginas_Usadas
		FROM sys.partitions As P
			JOIN sys.allocation_units As a ON P.hobt_id = a.container_id
			JOIN sys.objects O ON O.[object_id] = P.[object_id]
		WHERE O.[type] = 'U' -- TABELAS DO USUARIOS
		GROUP BY O.[name], [rows]
		ORDER BY Dados desc

END
use master 
go
begin

	select is_modified, count(1) from sys.dm_os_buffer_descriptors group by is_modified;
	checkpoint;
	dbcc dropcleanbuffers;
	select is_modified, count(1) from sys.dm_os_buffer_descriptors group by is_modified;

end
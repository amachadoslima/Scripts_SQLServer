USE master 
go
begin

	checkpoint;
	dbcc freeproccache;
	dbcc dropcleanbuffers;
	dbcc freesystemcache('all');
	dbcc freesessioncache;

end
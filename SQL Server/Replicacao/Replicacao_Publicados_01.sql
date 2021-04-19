select
		pub.[publication]  as publication_name,
		art.[publisher_db] as [db_name],
		art.[article] as article_name,
		art.[source_owner] as [schema],
		art.[source_object] as [object]
	from [distribution].[dbo].[msarticles]  art
			join [distribution].[dbo].[mspublications] pub on art.[publication_id] = pub.[publication_id]
	order by pub.[publication], art.[article]
/*
EVENTNAME	varchar	no	100
EVENTDATE	datetime	no	8
DEADLOCKGRAPH	xml	no	-1
*/

SET NOCOUNT ON

DECLARE @BodyHtml		VARCHAR(MAX)
DECLARE @ProfileName	SYSNAME
DECLARE @Recipients		VARCHAR(200)
DECLARE @Subject		VARCHAR(100)
DECLARE @Query			NVARCHAR(MAX)
DECLARE @Qtd			INT

IF(OBJECT_ID(N'tempdb..#TMPDEADLOCK') IS NOT NULL)
	DROP TABLE #TMPDEADLOCK
	
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

;WITH DeadlockData AS 
(
    SELECT CAST(target_data AS XML) AS TARGETDATA
		FROM sys.dm_xe_session_targets st
			JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
		WHERE [name]  = 'system_health'
			AND st.target_name = 'ring_buffer' 
)
SELECT 
		XEventData.XEvent.value('@name', 'varchar(100)') as EVENTNAME,
		XEventData.XEvent.value('@timestamp', 'datetime') as EVENTDATE,
		CAST(XEventData.XEvent.value('(data/value)[1]','VARCHAR(MAX)') AS XML) AS DEADLOCKGRAPH 
	INTO #TMPDEADLOCK
	FROM DeadlockData
		CROSS APPLY TargetData.nodes('//RingBufferTarget/event') AS XEventData (XEvent)
	WHERE XEventData.XEvent.value('@name','varchar(4000)') = 'xml_deadlock_report'
		AND XEventData.XEvent.value('@timestamp', 'datetime') > '2020-01-01'

Set @Qtd = @@ROWCOUNT

If(@Qtd > 0)
Begin

	Set @ProfileName = 'Sigero - Alerta'
	Set @Recipients  = 'alan.lima@ext.dersa.sp.gov.br;'
	Set @Subject  = 'PRD01 (DEADLOCKS)'
	

	Set @BodyHtml = '
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
				<style type="text/css">
					#Header{font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;}
					#Header td, #Header th {font-size:14px;border:1px solid #2163bf;padding:3px 7px 2px 7px;}
					#Header th {font-size:14px;text-align:left;padding-top:5px;padding-bottom:4px;background-color:#2163bf;color:#fff;}
					#Header tr.alt td {color:#000;background-color:#EAF2D3;}
					p {color:#000; font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;font-size:12px;font-weight: bold;}
				</style>
				<HTML>
					<BODY>'

	Set @BodyHtml += '<P style="color:red;">ATENÇÃO! ' + Cast(@Qtd AS VARCHAR) + ' DEADLOCKS ENCONTRADOS NOS ÚLTIMOS 5 MINUTOS.<P>'
	Set @BodyHtml += '<P><BR/> Alerta enviado automaticamente. Por favor, não responda.</P>'
	Set @BodyHtml += '</BODY></HTML>'

	PRINT @BodyHtml

	SELECT 
			EVENTNAME,
			EVENTDATE,
			DEADLOCKGRAPH
		FROM #TMPDEADLOCK
		FOR XML PATH('ELEMENT'), ROOT('DEADLOCKS')

End

IF(OBJECT_ID(N'tempdb..#TMPDEADLOCK') IS NOT NULL)
	DROP TABLE #TMPDEADLOCK
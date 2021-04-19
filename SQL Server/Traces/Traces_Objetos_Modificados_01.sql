/*
	https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-trace-setevent-transact-sql
*/

declare @filename varchar(255) 

select @filename = substring(path, 0, len(path) - charindex('\', reverse(path)) + 1) + '\log.trc'  
	from sys.traces   
	where is_default = 1;  

select 
	   gt.hostname, 
       gt.applicationname, 
       gt.ntusername, 
       gt.ntdomainname, 
       gt.loginname, 
       gt.spid, 
       gt.eventclass, 
       te.[name] as eventname,
       gt.eventsubclass,      
       gt.textdata, 
       gt.starttime, 
       gt.endtime, 
       gt.objectname, 
       gt.databasename, 
       gt.[filename], 
       gt.issystem
	from [fn_trace_gettable](@filename, default) gt 
		join sys.trace_events te on gt.eventclass = te.trace_event_id
	where eventclass in (164) --and gt.eventsubclass = 2
	order by starttime asc; 
	
/*

0-9	reserved	reserved
10	rpc:completed
11	rpc:starting
12	sql:batchcompleted
13	sql:batchstarting
14	audit login
15	audit logout
16	attention
17	existingconnection
18	audit server starts and stops
19	dtctransaction
20	audit login failed
21	eventlog
22	errorlog
23	lock:released
24	lock:acquired
25	lock:deadlock
26	lock:cancel
27	lock:timeout
28	degree of parallelism event (7.0 insert)
29-31	reserved	
32	reserved
33	exception
34	sp:cachemiss
35	sp:cacheinsert
36	sp:cacheremove
37	sp:recompile
38	sp:cachehit
39	deprecated
40	sql:stmtstarting
41	sql:stmtcompleted
42	sp:starting	indicates
43	sp:completed
44	sp:stmtstarting
45	sp:stmtcompleted
46	object:created
47	object:deleted
48	reserved	
49	reserved	
50	sql transaction	tracks transact-sql begin, commit, save, and rollback transaction statements.
51	scan:started
52	scan:stopped
53	cursoropen
54	transactionlog
55	hash warning
56-57	reserved	
58	auto stats
59	lock:deadlock
60	lock:escalation
61	ole db errors
62-66	reserved	
67	execution warnings
68	showplan text (unencoded)
69	sort warnings
70	cursorprepare
71	prepare sql	
72	exec prepared sql
73	unprepare sql
74	cursorexecute
75	cursorrecompile
76	cursorimplicitconversion
77	cursorunprepare
78	cursorclose
79	missing column statistics
80	missing join predicate
81	server memory change
82-91	user configurable (0-9)	event data defined by the user.
92	data file auto grow
93	log file auto grow
94	data file auto shrink
95	log file auto shrink
96	showplan text
97	showplan all
98	showplan statistics profile	
99	reserved	
100	rpc output parameter
101	reserved	
102	audit database scope gdr
103	audit object gdr event
104	audit addlogin event
105	audit login gdr event
106	audit login change property event
107	audit login change password event
passwords are not recorded.
108	audit add login to server role event
109	audit add db user event
110	audit add member to db role event
111	audit add role event
112	audit app role change password event
113	audit statement permission event
114	audit schema object access event
115	audit backup/restore event
116	audit dbcc event
117	audit change audit event
118	audit object derived permission event
119	oledb call event
120	oledb queryinterface event
121	oledb dataread event
122	showplan xml
123	sql:fulltextquery
124	broker:conversation
125	deprecation announcement
126	deprecation final support
127	exchange spill event
128	audit database management event
129	audit database object management event
130	audit database principal management event
131	audit schema object management event
132	audit server principal impersonation event
133	audit database principal impersonation event
134	audit server object take ownership event
135	audit database object take ownership event
136	broker:conversation group
137	blocked process report
138	broker:connection
139	broker:forwarded message sent
140	broker:forwarded message dropped
141	broker:message classify
142	broker:transmission
143	broker:queue disabled
144-145	reserved	
146	showplan xml statistics profile
148	deadlock graph
149	broker:remote message acknowledgement
150	trace file close
151	reserved	
152	audit change database owner
153	audit schema object take ownership event
154	reserved	
155	ft:crawl started
156	ft:crawl stopped
157	ft:crawl aborted
158	audit broker conversation
159	audit broker login
160	broker:message undeliverable
161	broker:corrupted message
162	user error message
163	broker:activation
164	object:altered
165	performance statistics
166	sql:stmtrecompile
167	database mirroring state change
168	showplan xml for query compile
169	showplan all for query compile
170	audit server scope gdr event
171	audit server object gdr event
172	audit database object gdr event
173	audit server operation event
175	audit server alter trace event
176	audit server object management
177	audit server principal management
178	audit database operation event
180	audit database object access event
181	tm: begin tran starting
182	tm: begin tran completed
183	tm: promote tran starting
184	tm: promote tran completed
185	tm: commit tran starting
186	tm: commit tran completed
187	tm: rollback tran starting
188	tm: rollback tran completed
189	lock:timeout (timeout > 0)
190	progress report: online index operation
191	tm: save tran starting
192	tm: save tran completed
193	background job error
194	oledb provider information
195	mount tape
196	assembly load
197	reserved	
198	xquery static type
199	qn: subscription
200	qn: parameter table	information about active subscriptions is stored in internal parameter tables
201	qn: template
202	qn: dynamics
212	bitmap warning
213	database suspect data page
214	cpu threshold exceeded
215	indicates when a logon trigger or resource governor classifier function starts execution.
216	preconnect:completed
217	plan guide successful
218	plan guide unsuccessful
235	audit fulltext
*/
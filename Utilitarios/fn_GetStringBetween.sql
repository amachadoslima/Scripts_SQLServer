USE msdb 
GO
IF(EXISTS(SELECT TOP 1 NULL FROM sys.objects WHERE name = N'fn_GetStringBetween'))
	DROP FUNCTION fn_GetStringBetween
GO
CREATE FUNCTION [dbo].[fn_GetStringBetween]
(
	@Str varchar(500), 
	@Str1 varchar(30), 
	@Str2 varchar(30)
)
RETURNS VARCHAR(200)
AS
BEGIN
   
   DECLARE @P1 int
   DECLARE @P2 int
   
   Set @P1 = CharIndex(@Str1, @Str, 1)
   Set @P2 = CharIndex(@Str2, @Str, 1)
   
   RETURN RTrim(LTrim(SubString(@Str, @P1 + Len(@Str1), @P2 - Len(@Str1) - @P1)))
   
END

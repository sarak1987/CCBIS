--Create the tables
BEGIN TRY
DROP TABLE [DimDate]
END TRY
BEGIN CATCH
--DO NOTHING
END CATCH

CREATE TABLE [dbo].[DimDate](
	[FullDate] [date] NOT NULL,
	[Day] [tinyint] NOT NULL,
	[DaySuffix] [varchar](4) NOT NULL,
	[DayOfWeek] [varchar](9) NOT NULL,
	[DayOfWeekNumber] [int] NOT NULL,
	[DayOfWeekInMonth] [tinyint] NOT NULL,
	[DayOfYearNumber] [int] NOT NULL,
	[RelativeDays] [int] NOT NULL,
	[WeekOfYearNumber] [tinyint] NOT NULL,
	[WeekOfMonthNumber] [tinyint] NOT NULL,
	[RelativeWeeks] [int] NOT NULL,
	[CalendarMonthNumber] [tinyint] NOT NULL,
	[CalendarMonthName] [varchar](9) NOT NULL,
	[RelativeMonths] [int] NOT NULL,
	[CalendarQuarterNumber] [tinyint] NOT NULL,
	[CalendarQuarterName] [varchar](6) NOT NULL,
	[RelativeQuarters] [int] NOT NULL,
	[CalendarYearNumber] [int] NOT NULL,
	[RelativeYears] [int] NOT NULL,
	[StandardDate] [varchar](10) NULL,
	[WeekDayFlag] [bit] NOT NULL,
	[HolidayFlag] [bit] NOT NULL,
	[OpenFlag] [bit] NOT NULL,
	[FirstDayOfCalendarMonthFlag] [bit] NOT NULL,
	[LastDayOfCalendarMonthFlag] [bit] NOT NULL,
	[HolidayText] [varchar](50) NULL,
 CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED 
(
	[FullDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


----insert values 
delete from [DimDate]
DECLARE @tmpDOW TABLE (DOW INT, Cntr INT)  --Table for counting DOW occurance in a month
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(1,0) --Used in the loop below
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(2,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(3,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(4,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(5,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(6,0)
INSERT INTO @tmpDOW(DOW, Cntr) VALUES(7,0)

DECLARE @StartDate datetime
, @EndDate datetime
, @Date datetime
, @WDofMonth INT
, @CurrentMonth INT
, @CurrentDate date = getdate()
 
SELECT @StartDate = '20190101'  -- Set The start and end date 
, @EndDate = '20200101'  --Non inclusive. Stops on the day before this.
, @CurrentMonth = 1  --Counter used in loop below.

SELECT @Date = @StartDate

WHILE @Date < @EndDate
BEGIN
 
IF DATEPART(MONTH,@Date) <> @CurrentMonth 
BEGIN
SELECT @CurrentMonth = DATEPART(MONTH,@Date)
UPDATE @tmpDOW SET Cntr = 0
END

UPDATE @tmpDOW
SET Cntr = Cntr + 1
WHERE DOW = DATEPART(DW,@DATE)

SELECT @WDofMonth = Cntr
FROM @tmpDOW
WHERE DOW = DATEPART(DW,@DATE) 

INSERT INTO [DimDate]
(
--[DateSK],–TO MAKE THE DateSK THE YYYYMMDD FORMAT UNCOMMENT THIS LINE… Comment for autoincrementing.
[FullDate]
, [Day]
, [DaySuffix]
, [DayOfWeek]
, [DayOfWeekNumber]
, [DayOfWeekInMonth]
, [DayOfYearNumber]
, [RelativeDays]
 
, [WeekOfYearNumber]
, [WeekOfMonthNumber] 
, [RelativeWeeks]
 
, [CalendarMonthNumber]
, [CalendarMonthName]
, [RelativeMonths]
 
, [CalendarQuarterNumber]
, [CalendarQuarterName]
, [RelativeQuarters]
 
, [CalendarYearNumber] 
, [RelativeYears]
 
, [StandardDate]
, [WeekDayFlag]
, [HolidayFlag]
, [OpenFlag]
, [FirstDayOfCalendarMonthFlag]
, [LastDayOfCalendarMonthFlag]
 
)
 
SELECT 
 
     --CONVERT(VARCHAR,@Date,112), --TO MAKE THE DateSK THE YYYYMMDD FORMAT UNCOMMENT THIS LINE COMMENT FOR AUTOINCREMENT
     @Date [FullDate]
     , DATEPART(DAY,@DATE) [Day]
     , CASE 
     WHEN DATEPART(DAY,@DATE) IN (11,12,13) THEN CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'th'
     WHEN RIGHT(DATEPART(DAY,@DATE),1) = 1 THEN CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'st'
     WHEN RIGHT(DATEPART(DAY,@DATE),1) = 2 THEN CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'nd'
     WHEN RIGHT(DATEPART(DAY,@DATE),1) = 3 THEN CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'rd'
     ELSE CAST(DATEPART(DAY,@DATE) AS VARCHAR) + 'th' 
     END AS [DaySuffix]
     , CASE DATEPART(DW, @DATE)
     WHEN 1 THEN 'Sunday'
     WHEN 2 THEN 'Monday'
     WHEN 3 THEN 'Tuesday'
     WHEN 4 THEN 'Wednesday'
     WHEN 5 THEN 'Thursday'
     WHEN 6 THEN 'Friday'
     WHEN 7 THEN 'Saturday'
     END AS [DayOfWeek]
     ,DATEPART(DW, @DATE) AS [DayOfWeekNumber]
     , @WDofMonth [DOWInMonth]  --Occurance of this day in this month. If Third Monday then 3 and DOW would be Monday.
     , DATEPART(dy,@Date) [DayOfYearNumber] --Day of the year. 0 – 365/366
     , DATEDIFF(dd,@CurrentDate,@Date) as [RelativeDays]
     
     , DATEPART(ww,@Date) [WeekOfYearNumber]  --0-52/53
     , DATEPART(ww,@Date) + 1 -
            DATEPART(ww,CAST(DATEPART(mm,@Date) AS VARCHAR) + '/1/' + CAST(DATEPART(yy,@Date) AS VARCHAR)) [WeekOfMonthNumber]
     , DATEDIFF(ww,@CurrentDate,@Date) as [RelativeWeeks]
     
     , DATEPART(MONTH,@DATE) as [CalendarMonthNumber] --To be converted with leading zero later. 
     , DATENAME(MONTH,@DATE) as [CalendarMonthName]
     , DATEDIFF(MONTH,@CurrentDate,@Date) as [RelativeMonths]
     
     , DATEPART(qq,@DATE) as [CalendarQuarterNumber] --Calendar quarter
     , CASE DATEPART(qq,@DATE) 
             WHEN 1 THEN 'Q1'
             WHEN 2 THEN 'Q2'
             WHEN 3 THEN 'Q3'
             WHEN 4 THEN 'Q4'
        END AS [CalendarQuarterName]
     , DATEDIFF(qq,@CurrentDate,@Date) as [RelativeQuarters]
        
        
     , DATEPART(YEAR,@Date) as [CalendarYearNumber]
     , DATEDIFF(YEAR,@CurrentDate,@Date) as [RelativeYears]
     
     , RIGHT('0' + convert(varchar(2),MONTH(@Date)),2) + '/' + Right('0' + convert(varchar(2),DAY(@Date)),2) + '/' + convert(varchar(4),YEAR(@Date))
     , CASE DATEPART(DW, @DATE)
             WHEN 1 THEN 0
             WHEN 2 THEN 1
             WHEN 3 THEN 1
             WHEN 4 THEN 1
             WHEN 5 THEN 1
             WHEN 6 THEN 1
             WHEN 7 THEN 0
         END AS [WeekDayFlag]
         
     , 0 as HolidayFlag
     
     , CASE DATEPART(DW, @DATE)
             WHEN 1 THEN 0
             WHEN 2 THEN 1
             WHEN 3 THEN 1
             WHEN 4 THEN 1
             WHEN 5 THEN 1
             WHEN 6 THEN 1
             WHEN 7 THEN 1
         END AS OpenFlag
         
     , CASE DATEPART(dd,@Date)
        WHEN 1 
            THEN 1
        ELSE 0
        END as [FirstDayOfCalendarMonthFlag]
        
     , CASE 
            WHEN DateAdd(day, -1, DateAdd( month, DateDiff(month , 0,@Date)+1 , 0)) = @Date 
                THEN 1
            ELSE 0
        END as [LastDayOfCalendarMonthFlag]

SELECT @Date = DATEADD(dd,1,@Date)
END

 --
 SET DATEFIRST 4

select FullDate ,
convert(tinyint,DATEPART(wk, DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)))) as ReportWeekNumber,
convert(tinyint,DATEPART(month,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)))) as ReportMonthNumber, 
convert(tinyint,DATEPART(QQ,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)))) as ReportQuarterNumber, 
convert(smallint,DATEPART(year,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)))) as ReportYearNumber ,
DATEADD(DAY, 1 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)) ReportWeekStart,   
DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)) ReportWeekEnd,
DATENAME(MONTH,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE))) as ReportMonthName,
CASE DATEPART(qq,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE))) 
             WHEN 1 THEN 'Q1'
             WHEN 2 THEN 'Q2'
             WHEN 3 THEN 'Q3'
             WHEN 4 THEN 'Q4'
        END AS ReportQuarterName
FROM [dbo].[DimCalendarDate] 
ORDER BY FullDate


SET DATEFIRST 4
UPDATE [dbo].[DimDate] 
SET
ReportWeekNumber=convert(tinyint,DATEPART(wk, DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)))) ,
ReportMonthNumber=convert(tinyint,DATEPART(month,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)))) , 
ReportQuarterNumber=convert(tinyint,DATEPART(QQ,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)))) , 
ReportYearNumber =convert(smallint,DATEPART(year,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)))) ,
ReportWeekStart=DATEADD(DAY, 1 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)) ,   
ReportWeekEnd=DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE)) ,
ReportMonthName=DATENAME(MONTH,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE))) ,
ReportQuarterName=CASE DATEPART(qq,DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), CAST(FullDate AS DATE))) 
             WHEN 1 THEN 'Q1'
             WHEN 2 THEN 'Q2'
             WHEN 3 THEN 'Q3'
             WHEN 4 THEN 'Q4'
        END 

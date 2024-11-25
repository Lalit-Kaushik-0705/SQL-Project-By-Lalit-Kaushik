-- OBJECTIVE QUESTIONS
-- 1.	List the different dtypes of columns in table “ball_by_ball” (using information schema)
use ipl;
 SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ball_by_ball';

-- 2	-- What is the total number of run scored in 1st season by RCB (bonus : also include the extra runs using the extra runs table)
with cte as (
select t3.Season_Id, t4.Season_Year, t1.Match_Id, t1.Over_Id, t1.Ball_Id, t1.Innings_No, t1.Striker, t2.Runs_Scored, t5.Player_Out
from ball_by_ball t1 
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
left join wicket_taken t5
on t1.Match_Id=t5.Match_Id and t1.Over_Id=t5.Over_Id and t1.Ball_Id=t5.Ball_Id and t1.Innings_No=t5.Innings_No
where t4.Season_Year between 2012 and 2016
),

cte2 as (
select Season_Year, sum(Runs_Scored) as Runs_in_PowerPlay_DeathOvers from cte
where (Over_Id between 1 and 6) or (Over_Id between 17 and 20)
group by 1
),

cte3 as (
select Season_Year, sum(Runs_Scored) as Runs_in_MiddleOvers from cte
where Over_Id between 7 and 16
group by 1
)

select t1.Season_Year, t1.Runs_in_PowerPlay_DeathOvers, t2.Runs_in_MiddleOvers
from cte2 t1 
join cte3 t2
on t1.Season_Year=t2.Season_Year;


-- ii) Comparison between Fall of Wickets during Power Play (1 to 6 overs) & Death Overs (17 to 20 overs) and 
-- Fall of Wickets during Middle Overs (7 to 16 Overs):

with cte as (
select t3.Season_Id, t4.Season_Year, t1.Match_Id, t1.Over_Id, t1.Ball_Id, t1.Innings_No, t1.Striker, t2.Runs_Scored, t5.Player_Out
from ball_by_ball t1 
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
left join wicket_taken t5
on t1.Match_Id=t5.Match_Id and t1.Over_Id=t5.Over_Id and t1.Ball_Id=t5.Ball_Id and t1.Innings_No=t5.Innings_No
where t4.Season_Year between 2012 and 2016
),

cte2 as (
select Season_Year, count(Player_Out) as Wickets_Lost_In_PowerPlay_DeathOvers from cte
where (Over_Id between 1 and 6) or (Over_Id between 17 and 20)
group by 1
),

cte3 as (
select Season_Year, count(Player_Out) as Wickets_Lost_In_MiddleOvers from cte
where Over_Id between 7 and 16
group by 1
)

select t1.Season_Year, t1.Wickets_Lost_In_PowerPlay_DeathOvers, t2.Wickets_Lost_In_MiddleOvers
from cte2 t1 
join cte3 t2
on t1.Season_Year=t2.Season_Year;

-- 3	How many players were more than age of 25 during season 2?
use ipl;

with cte as (
select t1.Match_Id, t2.Team_Id, t2.Player_Id, t3.Player_Name, t3.DOB, t1.Season_Id, t5.Season_Year, t5.Season_Year-(year(t3.DOB)) as Age
from matches t1
join player_match t2
on t1.Match_Id=t2.Match_Id
join player t3
on t2.Player_Id=t3.Player_Id
join team t4
on t1.Team_1=t4.Team_Id or t1.Team_2=t4.Team_Id
join season t5
on t1.Season_Id=t5.Season_Id
where t1.Season_Id=2 -- and t2.Team_Id=2 and t4.Team_Name="Royal Challengers Bangalore"
)
select count(Player_Name) as AgeMoreThan_25_Season2 from
(
select distinct Player_Id, Player_Name, Age from cte
where Age>25
) a

-- 4	How many matches did RCB win in season 1
use ipl;
select count(Match_Id) as RCB_season1_won from
(
select * from matches
where Season_ID=1 and Match_Winner=(select Team_Id from team where Team_Name="Royal Challengers Bangalore")
) a

-- 5	List top 10 players according to their strike rate in last 4 seasons
use ipl;
With cte as (
select t3.Season_Id, t4.Season_Year, t1.Match_Id, t1.Over_Id, t1.Ball_Id, t1.Innings_No, t1.Striker, t2.Runs_Scored
from ball_by_ball t1
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
),
cte2 as (
select *, dense_rank() over(order by Season_Year desc) as rnk from cte
),
cte3 as (
select * from cte2
where rnk<=4
order by Season_Year desc
),
cte4 as (
select Striker, sum(Runs_Scored) as Total_Runs, count(Striker) as Total_Balls from cte3
group by 1
)
select c1.Striker as Player_Id, c2.Player_Name, c1.Total_Runs, c1.Total_Balls, round((c1.Total_Runs/c1.Total_Balls)*100,2) as Strike_Rate
from cte4 c1
left join player c2
on c1.Striker=c2.Player_Id
where Total_Balls>=100
order by Strike_Rate desc
limit 10;

-- 6	What is the average runs scored by each batsman considering all the seasons?
use ipl;
create view Total_Players_Avg as
(
with cte as (
select t3.Season_Id, t4.Season_Year, t1.Match_Id, t1.Over_Id, t1.Ball_Id, t1.Innings_No, t1.Striker, t2.Runs_Scored, t5.Player_Out
from ball_by_ball t1
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
left join wicket_taken t5
on t1.Match_Id=t5.Match_Id and t1.Over_Id=t5.Over_Id and t1.Ball_Id=t5.Ball_Id and t1.Innings_No=t5.Innings_No
),
cte2 as (
select Season_Year, Striker as Player_Id, sum(Runs_Scored) as Total_Runs from cte
group by 1,2
),
cte3 as (
select Season_Year, Player_Out as Player_Id, count(*) as Total_Dismissals from cte
where Player_Out is not null
group by 1,2
)
select c1.*, c2.Total_Dismissals
from cte2 c1
join cte3 c2
on c1.Season_Year=c2.Season_Year and c1.Player_Id=c2.Player_Id
);
with cte as (
select Player_Id, sum(Total_Runs) as Total_Runs, sum(Total_Dismissals) as Total_Dismissals from Total_Players_Avg
group by 1
),
cte2 as (
select Player_Id, Total_Runs, Total_Dismissals, round((Total_Runs/Total_Dismissals),2) as Average from cte
order by Player_Id
)
select t1.Player_Id, t2.Player_Name, t1.Total_Runs, t1.Total_Dismissals, t1.Average
from cte2 t1
join player t2
on t1.Player_Id=t2.Player_Id
order by t1.Average desc;

-- 7	What are the average wickets taken by each bowler considering all the seasons?
use ipl;
create view highest_wickets_taken as
(
with cte as (
select t5.Season_Year, t1.Match_Id, t1.Innings_No, t1.Over_Id, t1.Ball_Id, t1.Bowler, t2.Kind_Out, t3.Out_Name
from ball_by_ball t1
join wicket_taken t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join out_type t3
on t2.Kind_Out=t3.Out_Id
join matches t4
on t1.Match_Id=t4.Match_Id
join season t5
on t4.Season_Id=t5.Season_Id
where t3.Out_Name not in ("run out","retired hurt","obstructing the field")
),
cte2 as (
select Bowler, count(Out_Name) as Total_Wickets from cte
group by Bowler
)
select c2.Player_Id, c2.Player_Name, c1.Total_Wickets
from cte2 c1
join player c2
on c1.Bowler=c2.Player_Id
order by c1.Total_Wickets desc
);
create view runs_conceded as
(
with cte as (
select t4.Season_Year, t1.Match_Id, t1.Innings_No, t1.Over_Id, t1.Ball_Id, t1.Bowler, t2.Runs_Scored
from ball_by_ball t1
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
),
cte2 as (
select t1.Match_Id, t1.Innings_No, t1.Over_Id, t1.Ball_Id, t1.Bowler, t2.Extra_Type_Id, t2.Extra_Runs, t3.Extra_Name
from ball_by_ball t1
left join extra_runs t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
left join extra_type t3
on t2.Extra_Type_Id=t3.Extra_Id
),
cte3 as (
select Bowler, sum(Runs_Scored) as Runs_Concede from cte
group by 1
),
cte4 as (
select Bowler, sum(Extra_Runs) as Extras_Concede from cte2
where Extra_Type_Id is not null and Extra_Name in ("wides","noballs")
group by 1
)
select c1.Bowler, c1.Runs_Concede, c2.Extras_Concede, (c1.Runs_Concede+coalesce(c2.Extras_Concede,0)) as Total_Runs_Conceded
from cte3 c1
left join cte4 c2
on c1.Bowler=c2.Bowler
);
select t1.*, t2.Total_Runs_Conceded, round((t2.Total_Runs_Conceded/t1.Total_Wickets),2) as Bowling_Average
from highest_wickets_taken t1
join runs_conceded t2
on t1.Player_Id=t2.Bowler
where t1.Total_Wickets >= 25
order by Bowling_Average asc;

-- 8	List all the players who have average runs scored greater than overall average and who have 
-- taken wickets greater than overall average
use ipl;
create view avg_runs_greater_than_batting_avg as (
with cte as (
select Player_Id, sum(Total_Runs) as Total_Runs, sum(Total_Dismissals) as Total_Dismissals from Total_Players_Avg
group by 1
),
cte2 as (
select Player_Id, Total_Runs, Total_Dismissals, round((Total_Runs/Total_Dismissals),2) as Average from cte
order by Player_Id
),
cte3 as (
select t1.Player_Id, t2.Player_Name, t1.Total_Runs, t1.Total_Dismissals, t1.Average
from cte2 t1
join player t2
on t1.Player_Id=t2.Player_Id
order by t1.Player_Id
),
cte4 as (
select round(avg(Average),2) as Overall_Batting_Average from cte3
)
select * from cte3 cross join cte4
where Average>Overall_Batting_Average
);
create view wickets_greater_than_bowling_avg as (
With cte as (
select t2.*, t1.Total_Runs_Conceded, round((t1.Total_Runs_Conceded/t2.Total_Wickets),2) as Bowling_Average
from runs_conceded t1
join highest_wickets_taken t2
on t1.Bowler=t2.Player_Id
),
cte2 as (
select round(avg(Bowling_Average),0) as Overall_Bowling_Average from cte
)
select * from cte cross join cte2
where Total_Wickets>Overall_Bowling_Average
);
select t1.Player_Id, t1.Player_Name, t1.Total_Runs, t1.Average as Batting_Average, t1.Overall_Batting_Average,
 t2.Total_Wickets, t2.Bowling_Average, t2.Overall_Bowling_Average
from avg_runs_greater_than_batting_avg t1
join wickets_greater_than_bowling_avg t2
on t1.Player_Id=t2.Player_Id;

-- 9	Create a table rcb_record table that shows wins and losses of RCB in an individual venue.
use ipl;
create view rcb_record_table as
(
With cte as (
select Venue_Id, Venue_Name, count(Match_Id) as No_of_Wins from (
select t1.Match_Id, t1.Team_1, t1.Team_2, t1.Season_Id, t1.Match_Winner, t1.Venue_Id, t2.Venue_Name
from matches t1
join venue t2
on t1.Venue_Id=t2.Venue_Id
where t1.Team_1=2 or t1.Team_2=2
) a
where Match_Winner=2
group by 1,2
),
cte2 as (
select Venue_Id, Venue_Name, count(Match_Id) as No_of_Losses from (
select t1.Match_Id, t1.Team_1, t1.Team_2, t1.Season_Id, t1.Match_Winner, t1.Venue_Id, t2.Venue_Name
from matches t1
join venue t2
on t1.Venue_Id=t2.Venue_Id
where t1.Team_1=2 or t1.Team_2=2
) a
where Match_Winner<>2
group by 1,2
)
select cte.*, cte2.No_of_Losses
from cte
join cte2
on cte.Venue_Id=cte2.Venue_Id
order by cte.Venue_Id
);
select * from rcb_record_table;

-- 10	What is the impact of bowling style on wickets taken.
use ipl;
with cte as (
select t1.Bowler as Player_Id, t2.Player_Name, t1.Total_Runs_Conceded, t2.Total_Wickets, 
round((t1.Total_Runs_Conceded/t2.Total_Wickets),2) as Average,
t4.Bowling_Id, t4.Bowling_Skill
from runs_conceded t1
join highest_wickets_taken t2
on t1.Bowler=t2.Player_Id
join player t3
on t1.Bowler=t3.Player_Id
join bowling_style t4
on t3.Bowling_skill=t4.Bowling_Id
)
select Bowling_Skill, sum(Total_Runs_Conceded) as Total_Runs_Given, sum(Total_Wickets) as 
Total_Wickets_Taken, round(avg(Average),2) as Bowling_Average from cte
group by 1;

-- 11-- Write the sql query to provide a status of whether the performance of the
--  team better than the previous year performance on the basis of number of runs
--  scored by the team in the season and number of wickets taken 
use ipl;
create view teams_score_each_season as (
With cte1 as (
select t1.Match_Id, t1.Team_1, t1.Team_2, t2.Team_Name, t1.Season_ID, t1.Toss_Winner, t1.Toss_Decide, t3.Toss_Name
from matches t1
join team t2
on t1.Team_1=t2.Team_Id or t1.Team_2=t2.Team_Id
join toss_decision t3
on t1.Toss_Decide=t3.Toss_Id
order by t1.Match_Id
),
cte2 as (
select distinct Match_Id, Team_1, Team_2, Season_ID, Toss_Winner, Toss_Decide, Toss_Name,
case when Toss_Winner=Team_1 and Toss_Name="bat" then Team_1
when Toss_Winner=Team_1 and Toss_Name="field" then Team_2
when Toss_Winner=Team_2 and Toss_Name="bat" then Team_2
when Toss_Winner=Team_2 and Toss_Name="field" then Team_1
end as First_Innings
from cte1
),
cte3 as (
select *,
case when First_Innings=Team_1 then Team_2 else Team_1 end as Second_Innings
from cte2
),
cte4 as (
select Match_Id, Innings_No, sum(Extra_Runs) as Extras from extra_runs
group by 1,2
),
cte5 as (
select Match_Id, Innings_No, sum(Runs_Scored) as Runs from batsman_scored
group by 1,2
),
cte6 as (
select cte4.Match_Id, cte4.Innings_No, cte5.Runs, cte4.Extras, cte5.Runs+cte4.Extras as Score
from cte4 join cte5
on cte4.Match_Id=cte5.Match_Id and cte4.Innings_No=cte5.Innings_No
),
cte7 as (
select t1.Season_ID, t1.Match_Id, t1.Team_1, t1.Team_2, t1.First_Innings, t1.Second_Innings, t2.Innings_No,
case when t2.Innings_No=1 then t2.Score end as First_Innings_Score,
case when t2.Innings_No=2 then t2.Score end as Second_Innings_Score
from cte3 t1 join cte6 t2
on t1.Match_Id=t2.Match_Id
),
cte8 as (
select Season_ID, First_Innings, sum(First_Innings_Score) as Score_First_Batting from cte7
group by 1,2
),
cte9 as (
select Season_ID, Second_Innings, sum(Second_Innings_Score) as Score_Second_Batting from cte7
group by 1,2
)
select c1.Season_ID, c4.Season_Year, c1.First_Innings as Team_ID, c3.Team_Name, c1.Score_First_Batting, c2.Score_Second_Batting,
c1.Score_First_Batting+c2.Score_Second_Batting as Total_Score
from cte8 c1 join cte9 c2
on c1.Season_ID=c2.Season_ID and c1.First_Innings=c2.Second_Innings
join team c3
on c1.First_Innings=c3.Team_Id
join season c4
on c1.Season_ID=c4.Season_Id
);
create view team_wickets_each_season as (
With cte1 as (
select t1.Match_Id, t1.Team_1, t1.Team_2, t2.Team_Name, t1.Season_ID, t1.Toss_Winner, t1.Toss_Decide, t3.Toss_Name
from matches t1
join team t2
on t1.Team_1=t2.Team_Id or t1.Team_2=t2.Team_Id
join toss_decision t3
on t1.Toss_Decide=t3.Toss_Id
order by t1.Match_Id
),
cte2 as (
select distinct Match_Id, Team_1, Team_2, Season_ID, Toss_Winner, Toss_Decide, Toss_Name,
case when Toss_Winner=Team_1 and Toss_Name="bat" then Team_1
when Toss_Winner=Team_1 and Toss_Name="field" then Team_2
when Toss_Winner=Team_2 and Toss_Name="bat" then Team_2
when Toss_Winner=Team_2 and Toss_Name="field" then Team_1
end as First_Innings
from cte1
),
cte3 as (
select *,
case when First_Innings=Team_1 then Team_2 else Team_1 end as Second_Innings
from cte2
),
cte4 as (
select t5.Season_Year, t1.Match_Id, t1.Innings_No, t1.Over_Id, t1.Ball_Id, t1.Bowler, t2.Kind_Out, t3.Out_Name
from ball_by_ball t1
join wicket_taken t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join out_type t3
on t2.Kind_Out=t3.Out_Id
join matches t4
on t1.Match_Id=t4.Match_Id
join season t5
on t4.Season_Id=t5.Season_Id
),
cte5 as (
select Season_Year, Match_Id, Innings_No, count(*) as Wickets from cte4
group by 1,2,3
),
cte6 as (
select t1.Season_ID, t2.Season_Year, t1.Match_Id, t1.Team_1, t1.Team_2, t1.First_Innings, t1.Second_Innings, t2.Innings_No,
case when t2.Innings_No=1 then t2.Wickets end as First_Innings_Wickets,
case when t2.Innings_No=2 then t2.Wickets end as Second_Innings_Wickets
from cte3 t1 join cte5 t2
on t1.Match_Id=t2.Match_Id
),
cte7 as (
select Season_ID, Season_Year, First_Innings, sum(Second_Innings_Wickets) as Wickets_1 from cte6
group by 1,2,3
),
cte8 as (
select Season_ID, Season_Year, Second_Innings, sum(First_Innings_Wickets) as Wickets_2 from cte6
group by 1,2,3
)
select c1.Season_ID, c1.Season_Year, c1.First_Innings as Team_ID, c3.Team_Name, c1.Wickets_1, c2.Wickets_2, 
c1.Wickets_1+c2.Wickets_2 as Total_Wickets
from cte7 c1
join cte8 c2
on c1.Season_ID=c2.Season_ID and c1.First_Innings=c2.Second_Innings
join team c3
on c1.First_Innings=c3.Team_Id
);
With cte as (
select t1.Season_ID, t1.Season_Year, t1.Team_ID, t1.Team_Name,
t1.Total_Score, lag(t1.Total_Score,1,"-") over(partition by t1.Team_Name order by t1.Season_Year) as Prev_Total_Score,
t2.Total_Wickets, lag(t2.Total_Wickets,1,"-") over(partition by t1.Team_Name order by t1.Season_Year) as Prev_Total_Wickets,
min(t1.Season_Year) over(partition by t1.Team_Name) as First_Season_Year
from teams_score_each_season t1
join team_wickets_each_season t2
on t1.Season_ID=t2.Season_ID and t1.Team_ID=t2.Team_ID
order by Team_Name, Season_Year
)
select Season_Year, Team_Name, Total_Score, Prev_Total_Score, Total_Wickets, Prev_Total_Wickets,
case when Season_Year=First_Season_Year then "First Season"
when Total_Score>Prev_Total_Score and Total_Wickets>Prev_Total_Wickets then "Better" else "Decline" end as Performance_Status
from cte;

-- 12 Can you derive more KPIs for the team strategy if possible?
use ipl;
---Win Percentage of Each Team--
SELECT 
    team.Team_Name,
    COUNT(CASE WHEN matches.Match_Winner = team.Team_Id THEN 1 END) * 100.0 / COUNT(matches.Match_Id) AS Win_Percentage
FROM 
    team
LEFT JOIN 
    matches ON matches.Team_1 = team.Team_Id 
GROUP BY 
    team.Team_Name;

---Number of Catches Taken by Each Player---
SELECT 
    player.Player_Name,
    COUNT(*) AS Catches_Taken
FROM 
    wicket_taken
INNER JOIN 
    player ON wicket_taken.Fielders = player.Player_Id
WHERE 
    wicket_taken.Kind_Out = (SELECT Out_Id FROM out_type WHERE Out_Name = 'Caught')
GROUP BY 
    player.Player_Name;
---Total Runs Conceded by Each Player---
SELECT 
    player.Player_Name,
    SUM(batsman_scored.Runs_Scored) + IFNULL(SUM(extra_runs.Extra_Runs), 0) AS Total_Runs_Conceded
FROM 
    ball_by_ball
INNER JOIN 
    player ON ball_by_ball.Bowler = player.Player_Id
LEFT JOIN 
    batsman_scored ON ball_by_ball.Match_Id = batsman_scored.Match_Id AND 
                     ball_by_ball.Over_Id = batsman_scored.Over_Id AND 
                     ball_by_ball.Ball_Id = batsman_scored.Ball_Id AND 
                     ball_by_ball.Innings_No = batsman_scored.Innings_No
LEFT JOIN 
    extra_Runs ON ball_by_ball.Match_Id = extra_runs.Match_Id AND 
                  ball_by_ball.Over_Id = extra_runs.Over_Id AND 
                  ball_by_ball.Ball_Id = extra_runs.Ball_Id AND 
                  ball_by_ball.Innings_No = extra_runs.Innings_No
GROUP BY 
    player.Player_Name;
---Total Wickets Taken by Each Player---
SELECT 
    player.Player_Name,
    COUNT(*) AS Total_Wickets
FROM 
    wicket_taken
INNER JOIN 
    player ON wicket_taken.Kind_Out = player.Player_Id
WHERE 
    wicket_taken.Kind_Out IN (SELECT Out_Id FROM out_type WHERE Out_Name
    IN ('Bowled', 'Caught', 'LBW', 'Stumped', 'Caught & Bowled', 'Hit Wicket'))
GROUP BY 
    player.Player_Name;
---Bowling Average---
SELECT 
    player.Player_Name,
    SUM(batsman_scored.Runs_Scored + IFNULL(extra_runs.Extra_Runs, 0)) / COUNT(*) AS Bowling_Average
FROM 
    ball_by_ball
INNER JOIN 
    player ON ball_by_ball.Bowler = player.Player_Id
LEFT JOIN 
    batsman_scored ON ball_by_ball.Match_Id = batsman_scored.Match_Id AND 
                     ball_by_ball.Over_Id = batsman_scored.Over_Id AND 
                     ball_by_ball.Ball_Id = batsman_scored.Ball_Id AND 
                     ball_by_ball.Innings_No = batsman_scored.Innings_No
LEFT JOIN 
    extra_runs ON ball_by_ball.Match_Id = extra_runs.Match_Id AND 
                  ball_by_ball.Over_Id = extra_runs.Over_Id AND 
                  ball_by_ball.Ball_Id = extra_runs.Ball_Id AND 
                  ball_by_ball.Innings_No = extra_runs.Innings_No
INNER JOIN 
    wicket_taken ON ball_by_ball.Match_Id = wicket_taken.Match_Id AND 
                    ball_by_ball.Over_Id = wicket_taken.Over_Id AND 
                    ball_by_ball.Ball_Id = wicket_taken.Ball_Id AND 
                    ball_by_ball.Innings_No = wicket_taken.Innings_No
GROUP BY 
    player.Player_Name;

-- 13 Using SQL, 
-- write a query to find out average wickets taken by each bowler in each venue. Also rank the gender according to the average value.
use ipl;
   Drop view if exists wickets_taken_by_venue;
Drop view if exists runs_conceded_by_venue;

create view wickets_taken_by_venue as (
With cte as (
select t5.Season_Year, t4.Venue_Id, t6.Venue_Name, t1.Match_Id, t1.Innings_No, t1.Over_Id, t1.Ball_Id, t1.Bowler, 
t2.Kind_Out, t3.Out_Name
from ball_by_ball t1
join wicket_taken t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join out_type t3
on t2.Kind_Out=t3.Out_Id
join matches t4
on t1.Match_Id=t4.Match_Id
join season t5
on t4.Season_Id=t5.Season_Id
join venue t6
on t4.Venue_Id=t6.Venue_Id
where t3.Out_Name not in ("run out","retired hurt","obstructing the field")
),
cte2 as (
select Venue_Id, Venue_Name, Bowler, count(Out_Name) as Total_Wickets from cte
group by 1,2,3
order by Venue_Id, Total_Wickets desc
)
select c1.Venue_Id, c1.Venue_Name, c2.Player_Id, c2.Player_Name, c1.Total_Wickets
from cte2 c1
join player c2
on c1.Bowler=c2.Player_Id
order by c1.Venue_Id, c1.Total_Wickets desc
);
create view runs_conceded_by_venue as (
with cte as (
select t4.Season_Year, t3.Venue_Id, t5.Venue_Name, t1.Match_Id, t1.Innings_No, t1.Over_Id, t1.Ball_Id, t1.Bowler, t2.Runs_Scored
from ball_by_ball t1
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
join venue t5
on t3.Venue_Id=t5.Venue_Id
),
cte2 as (
select t6.Season_Year, t4.Venue_Id, t5.Venue_Name, t1.Match_Id, t1.Innings_No, t1.Over_Id, t1.Ball_Id, t1.Bowler, t2.Extra_Type_Id, 
t2.Extra_Runs, t3.Extra_Name
from ball_by_ball t1
left join extra_runs t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
left join extra_type t3
on t2.Extra_Type_Id=t3.Extra_Id
join matches t4
on t1.Match_Id=t4.Match_Id
join venue t5
on t4.Venue_Id=t5.Venue_Id
join season t6
on t4.Season_Id=t6.Season_Id
),
cte3 as (
select Venue_Id, Venue_Name, Bowler, sum(Runs_Scored) as Runs_Concede from cte
group by 1,2,3
),
cte4 as (
select Venue_Id, Venue_Name, Bowler, sum(Extra_Runs) as Extras_Concede from cte2
where Extra_Type_Id is not null and Extra_Name in ("wides","noballs")
group by 1,2,3
)
select c1.Venue_Id, c1.Venue_Name, c1.Bowler, c1.Runs_Concede, c2.Extras_Concede, (c1.Runs_Concede+coalesce(c2.Extras_Concede,0)) 
as Total_Runs_Conceded
from cte3 c1
left join cte4 c2
on c1.Bowler=c2.Bowler and c1.Venue_Id=c2.Venue_Id
order by c1.Venue_Id
);
with cte as (
select t1.Venue_Id, t1.Venue_Name, t1.Player_Id, t1.Player_Name, t2.Total_Runs_Conceded, t1.Total_Wickets, 
round((t2.Total_Runs_Conceded/t1.Total_Wickets),2) as Bowling_Average
from wickets_taken_by_venue t1
join runs_conceded_by_venue t2
on t1.Venue_Id=t2.Venue_Id and t1.Player_Id=t2.Bowler
)
select *, dense_rank() over(partition by Venue_Name order by Bowling_Average) as Ranking
from cte
order by Venue_Id;

-- 14.Which of the given players have consistently performed well in past seasons? (will you use any visualization to solve the problem)
use ipl;
with cte as (
select *, round((Total_Runs/Total_Dismissals),2) as Average from Total_Players_Avg
),
cte2 as (
select Player_Id, sum(case when Average>30 then 1 else 0 end) as Total_Count
from cte
group by 1
having Total_Count>=4
order by Player_Id
),
cte3 as (
select t1.Player_Id, t2.Player_Name
from cte2 t1
join player t2
on t1.Player_Id=t2.Player_Id
),
cte4 as (
select Player_Id, Season_Year, round((Total_Runs/Total_Dismissals),2) as Average from Total_Players_Avg
where Player_Id in
(
select Player_Id from cte3
)
)
select t1.Player_Id, t2.Player_Name, t1.Season_Year, t1.Average
from cte4 t1
join player t2
on t1.Player_Id=t2.Player_Id
order by t1.Player_Id, t1.Season_Year;

-- 15 Are there players whose performance is more suited to specific venues or conditions? 
-- (how would you present this using charts?) 
use ipl;
with cte as (
select t3.Season_Id, t4.Season_Year, t3.Venue_Id, t5.Venue_Name, t1.Match_Id, t1.Over_Id, t1.Ball_Id, t1.Innings_No, 
t1.Striker, t2.Runs_Scored
from ball_by_ball t1
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
join venue t5
on t3.Venue_Id=t5.Venue_Id
),
cte2 as (
select Venue_Id, Venue_Name, Striker, sum(Runs_Scored) as Total_Runs from cte
group by 1,2,3
),
cte3 as (
select *, dense_rank() over(partition by Venue_Name order by Total_Runs desc) as Ranking
from cte2
order by Venue_Id
),
cte4 as (
select * from cte3
where Ranking=1
order by Venue_Id, Ranking
)
select t1.Venue_Id, t1.Venue_Name, t2.Player_Id, t2.Player_Name, t1.Total_Runs, t1.Ranking
from cte4 t1
join player t2
on t1.Striker=t2.Player_Id;

-- SUBJECTIVE QUESTIONS
-- 1	How does toss decision have affected the result of the match ? 
-- (which visualisations could be used to better present your answer) And is the impact limited to only specific venues?
use ipl;
with cte as (
select t1.Match_Id, t1.Team_1, t1.Team_2, t1.Season_ID, t1.Toss_Winner, t1.Toss_Decide, t2.Toss_Name, t1.Match_Winner,
case when Toss_Winner=Match_Winner then 1 else 0 end as Toss_Win_Results, 
case when Toss_Winner<>Match_Winner then 1 else 0 end as Toss_Loss_Results 
from matches t1 
join toss_decision t2
on t1.Toss_Decide=t2.Toss_Id
order by t1.Match_Id
),

cte2 as (
select count(Match_Id) as Total_Matches, sum(Toss_Win_Results) as Toss_Winnner_Match_Winner, sum(Toss_Loss_Results) as Toss_Loser_Match_Winner from cte 
where Match_Winner is not null
)

select *, round(Toss_Winnner_Match_Winner*100/Total_Matches,2) as "Toss_Winnner_Match_Winner_Percentage (%)", 
round(Toss_Loser_Match_Winner*100/Total_Matches,2) as "Toss_Loser_Match_Winner_Percentage (%)" from cte2; 


-- Toss Impact on Different Venues:

with cte as (
select t1.Match_Id, t1.Team_1, t1.Team_2, t1.Season_ID, t1.Venue_Id, t1.Toss_Winner, t1.Toss_Decide, t2.Toss_Name, t1.Match_Winner,
case when Toss_Winner=Match_Winner then 1 else 0 end as Toss_Win_Results, 
case when Toss_Winner<>Match_Winner then 1 else 0 end as Toss_Loss_Results 
from matches t1 
join toss_decision t2
on t1.Toss_Decide=t2.Toss_Id
order by t1.Match_Id
),

cte2 as (
select Venue_Id, count(Match_Id) as Total_Matches, sum(Toss_Win_Results) as Toss_Winnner_Match_Winner, sum(Toss_Loss_Results) as Toss_Loser_Match_Winner from cte 
where Match_Winner is not null
group by 1
),

cte3 as (
select *, round(Toss_Winnner_Match_Winner*100/Total_Matches,2) as Toss_Winnner_Match_Winner_Percentage, 
round(Toss_Loser_Match_Winner*100/Total_Matches,2) as Toss_Loser_Match_Winner_Percentage from cte2
)

select  t2.Venue_Name, t1.Total_Matches, t1.Toss_Winnner_Match_Winner, t1.Toss_Loser_Match_Winner, 
t1.Toss_Winnner_Match_Winner_Percentage as "Toss_Winnner_Match_Winner_Percentage (%)", 
t1.Toss_Loser_Match_Winner_Percentage as "Toss_Loser_Match_Winner_Percentage (%)"
from cte3 t1 
join venue t2 
on t1.Venue_Id=t2.Venue_Id
order by Venue_name;      

-- 2.Suggest some of the players who would be best fit for the team?
-- top 5 score rank in each season--players and number of times they are in top 5 in last 3 seasons 
with player_match_runs as (select bb.match_id,bb.striker,sum(runs_scored) as total_runs
					      from ball_by_ball bb join batsman_scored bs on bb.Match_Id=bs.Match_Id and bb.Innings_No=bs.Innings_No
																and bb.Over_Id=bs.Over_Id and bb.Ball_Id=bs.Ball_Id 
							group by bb.match_id,bb.striker),
result as (select pmr.striker as player_id,s.season_year,
                                 sum(pmr.total_runs) runs_scored,
                                 dense_rank() over(partition by season_year order by sum(pmr.total_runs) desc) season_runs_rank
			from player_match_runs pmr join matches m on pmr.match_id=m.match_id
			join season s on m.season_id=s.season_id
			group by pmr.striker,s.season_year),
top_run_rank_player as (select * from result
						where season_runs_rank between 1 and 5
						and season_year between 2014 and 2016
		                order by season_year,season_runs_rank)
select trp.player_id,p.player_name,count(trp.player_id) as no_of_times_in_top5 
from top_run_rank_player trp join player p on trp.player_id=p.player_id
group by trp.player_id,p.player_name
order by count(trp.player_id) desc
limit 10; 

-- 3.	What are some of parameters that should be focused while selecting the players?
use ipl;
with cte as (
select t3.Season_Id, t4.Season_Year, t1.Match_Id, t1.Over_Id, t1.Ball_Id, t1.Innings_No, t1.Striker, t2.Runs_Scored, t5.Player_Out
from ball_by_ball t1 
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
left join wicket_taken t5
on t1.Match_Id=t5.Match_Id and t1.Over_Id=t5.Over_Id and t1.Ball_Id=t5.Ball_Id and t1.Innings_No=t5.Innings_No
where t4.Season_Year in (2015,2016)
),

cte2 as (
select Season_Year, Striker as Player_Id, sum(Runs_Scored) as Total_Runs from cte
group by 1,2
),

cte3 as (
select Season_Year, Player_Out as Player_Id, count(*) as Total_Dismissals from cte
where Player_Out is not null
group by 1,2
),

cte4 as (
select c1.*, c2.Total_Dismissals
from cte2 c1
join cte3 c2
on c1.Season_Year=c2.Season_Year and c1.Player_Id=c2.Player_Id
),

cte5 as (
select Player_Id, sum(Total_Runs) as Total_Runs, sum(Total_Dismissals) as Total_Dismissals from cte4
group by 1
),

cte6 as (
select Player_Id, Total_Runs, Total_Dismissals, round((Total_Runs/Total_Dismissals),2) as Average_Performance from cte5
order by Player_Id
)
select t2.Player_Name, t1.Total_Runs, t1.Total_Dismissals, t1.Average_Performance
from cte6 t1 
join player t2 
on t1.Player_Id=t2.Player_Id
where t1.Total_Runs>=500 and t1.Average_Performance>=30
order by t1.Average_Performance desc;

-- 4.	Which players offer versatility in their skills and can contribute effectively with both bat and ball?
--  (can you visualize the data for the same)
Drop view if exists avg_runs_greater_than_batting_avg;
Drop view if exists wickets_greater_than_bowling_avg ;
create view avg_runs_greater_than_batting_avg as (
with cte as (
select Player_Id, sum(Total_Runs) as Total_Runs, sum(Total_Dismissals) as Total_Dismissals from Total_Players_Avg
group by 1
),
cte2 as (
select Player_Id, Total_Runs, Total_Dismissals, round((Total_Runs/Total_Dismissals),2) as Average from cte
order by Player_Id
),
cte3 as (
select t1.Player_Id, t2.Player_Name, t1.Total_Runs, t1.Total_Dismissals, t1.Average
from cte2 t1
join player t2
on t1.Player_Id=t2.Player_Id
order by t1.Player_Id
),
cte4 as (
select round(avg(Average),2) as Overall_Batting_Average from cte3
)
select * from cte3 cross join cte4
where Average>Overall_Batting_Average
);
create view wickets_greater_than_bowling_avg as (
With cte as (
select t2.*, t1.Total_Runs_Conceded, round((t1.Total_Runs_Conceded/t2.Total_Wickets),2) as Bowling_Average
from runs_conceded t1
join highest_wickets_taken t2
on t1.Bowler=t2.Player_Id
),
cte2 as (
select round(avg(Bowling_Average),0) as Overall_Bowling_Average from cte
)
select * from cte cross join cte2
where Total_Wickets>Overall_Bowling_Average
);
select t1.Player_Id, t1.Player_Name, t1.Total_Runs, t1.Average as Batting_Average, t1.Overall_Batting_Average, t2.Total_Wickets, t2.Bowling_Average, t2.Overall_Bowling_Average
from avg_runs_greater_than_batting_avg t1
join wickets_greater_than_bowling_avg t2
on t1.Player_Id=t2.Player_Id;

-- 5.	Are there players whose presence positively influences the morale and performance of the team? 
-- (justify your answer using visualisation)
use ipl;
with cte as (
select t3.Season_Id, t4.Season_Year, t1.Match_Id, t1.Over_Id, t1.Ball_Id, t1.Innings_No, t1.Striker, t2.Runs_Scored
from ball_by_ball t1 
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
where t4.Season_Year in (2015,2016)
),

cte2 as (
select Striker, sum(Runs_Scored) as Total_Runs from cte 
group by 1
),

cte3 as (
select Striker, sum(Runs_Scored) as Runs_In_Boundaries from cte
where Runs_Scored in (4,6)
group by 1
)

select t1.Striker as Player_Id, t3.Player_Name, t1.Total_Runs, t2.Runs_In_Boundaries, round((t2.Runs_In_Boundaries*100/t1.Total_Runs),2) as Boundary_Percentage 
from cte2 t1 
join cte3 t2 
on t1.Striker=t2.Striker
join player t3 
on t1.Striker=t3.Player_Id
where t1.Total_Runs>=100
order by Boundary_Percentage desc;

-- 7.	What do you think could be the factors contributing to the high-scoring matches and the impact on viewership and team strategies
use ipl;
with cte as (
select t3.Season_Id, t4.Season_Year, t1.Match_Id, t1.Over_Id, t1.Ball_Id, t1.Innings_No, t1.Striker, t2.Runs_Scored, t5.Player_Out
from ball_by_ball t1 
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
left join wicket_taken t5
on t1.Match_Id=t5.Match_Id and t1.Over_Id=t5.Over_Id and t1.Ball_Id=t5.Ball_Id and t1.Innings_No=t5.Innings_No
where t4.Season_Year between 2012 and 2016
),

cte2 as (
select Season_Year, sum(Runs_Scored) as Runs_in_PowerPlay_DeathOvers from cte
where (Over_Id between 1 and 6) or (Over_Id between 17 and 20)
group by 1
),

cte3 as (
select Season_Year, sum(Runs_Scored) as Runs_in_MiddleOvers from cte
where Over_Id between 7 and 16
group by 1
)

select t1.Season_Year, t1.Runs_in_PowerPlay_DeathOvers, t2.Runs_in_MiddleOvers
from cte2 t1 
join cte3 t2
on t1.Season_Year=t2.Season_Year;


-- ii) Comparison between Fall of Wickets during Power Play (1 to 6 overs) & Death Overs (17 to 20 overs) and Fall of Wickets during Middle Overs (7 to 16 Overs):

with cte as (
select t3.Season_Id, t4.Season_Year, t1.Match_Id, t1.Over_Id, t1.Ball_Id, t1.Innings_No, t1.Striker, t2.Runs_Scored, t5.Player_Out
from ball_by_ball t1 
join batsman_scored t2
on t1.Match_Id=t2.Match_Id and t1.Over_Id=t2.Over_Id and t1.Ball_Id=t2.Ball_Id and t1.Innings_No=t2.Innings_No
join matches t3
on t1.Match_Id=t3.Match_Id
join season t4
on t3.Season_Id=t4.Season_Id
left join wicket_taken t5
on t1.Match_Id=t5.Match_Id and t1.Over_Id=t5.Over_Id and t1.Ball_Id=t5.Ball_Id and t1.Innings_No=t5.Innings_No
where t4.Season_Year between 2012 and 2016
),

cte2 as (
select Season_Year, count(Player_Out) as Wickets_Lost_In_PowerPlay_DeathOvers from cte
where (Over_Id between 1 and 6) or (Over_Id between 17 and 20)
group by 1
),

cte3 as (
select Season_Year, count(Player_Out) as Wickets_Lost_In_MiddleOvers from cte
where Over_Id between 7 and 16
group by 1
)

select t1.Season_Year, t1.Wickets_Lost_In_PowerPlay_DeathOvers, t2.Wickets_Lost_In_MiddleOvers
from cte2 t1 
join cte3 t2
on t1.Season_Year=t2.Season_Year;
































































































































































































































































































































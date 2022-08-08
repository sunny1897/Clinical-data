/*creating age variable & summary statistics for age  */
data project1;
set project;
dob=compress(cat(month, '/', day, '/', year));
dob1=input(dob,mmddyy10.);

age=(diagdt-dob1)/365;
output;
trt=2;
output;
run;

proc sort data=project1;
by trt;
run;
proc means data=project1 noprint;
var age;
output out=agestats;
by trt;
run;

data agestats;
set agestats;
length value $10.;
ord=1;
if _stat_ ='N' then do; subord=1; value= strip(put(age,8.));end;
else if _stat_='MEAN' then do; subord=2; value= strip(put(age, 8.1));end;
else if _stat_='STD' then do; subord=3; value=strip(put(age, 8.2));end;
else if _stat_='MIN' then do;subord=4; value=strip(put(age, 8.1));end;
else if _stat_='MAX' then do;subord=5; value=strip(put(age, 8.1));end;

rename _stat_=stat;
drop _type_ _freq_ age;
run;


/*section 2  creating age group age grp  */
proc format ;
value agegrp
low-18='<=18 years'
18-65='18 to 65 years'
65-high='> 65 years';
 run;

data project3;
set project1;
agegroup= put(age, agegrp.);
run;
proc freq data=project3;
table trt*agegroup/ outpct out=agegrpstats;
run;

data agegrpstats;
set agegrpstats;
ord=2;
if agegroup= '<=18 years' then subord= 1;
else if agegroup= '18 to 65 years' then subord= 2;
if agegroup= '> 65 years' then subord= 3;
value=cat(count, '(', strip(put(round(pct_row, .1),8.1)), '%)');
rename agegroup=stat;
drop count pct_row pct_col;
run;

/* section 3 */
/* statistical parameter for gender */
proc format;
value genfmt
1='Male'
2='Female';
run;

data project2;
set project1;
sex=put(gender, genfmt.);
run;

proc freq data=project2;
table trt*sex/ outpct out=genderstats;
run;

data genderstats;
set genderstats;
value=cat(count, '(', strip(put(round(pct_row, .1),8.1)), '%)');
ord=3;
if sex='Male' then subord=1;
else subord=2;
rename sex=stat;
drop count percent pct_row pct_col;
run;

/* section3 */
/* deriving race variable */
proc format ;
value racefmt
1='White'
2='Black'
3='Hispanic'
4='Asian'
5='Other';
run;

data project3;
set project2;
racec= put(race,racefmt.);
run;

/*summary statistics of race  */
proc freq data=project3;
table trt*racec/ outpct out=racestats;
run;

data racestats;
set racestats;
value=cat(count, '(', strip(put(round(pct_row, .1),8.1)), '%)');
ord=4;
if racec='Asian' then subord=1;
else if racec='Black' then subord=2;
else if racec='Hispanic' then subord=3;
else if racec='White' then subord=4;
else if racec='Other' then subord=5;

rename racec=stat;
drop count percent pct_col pct_row;
run;


/* all stat together */
data allstats;
set agestats agegrpstats genderstats racestats;
run;

/*transposing data by treatment groups  */
proc sort data=allstats;
by ord subord stat;
run;

proc transpose data=allstats out=t_allstats prefix=_;
var value;
id trt;
by ord subord stat;
run;

proc sql noprint;
select count(*) into :placebo from project1 where trt=0;
select count(*) into :active from project1 where trt=1;
select count(*) into :total from project1 where trt=2;
quit;

%let placebo=&placebo;
%let active=&active;
%let total=&total;

/*final  */
data final;
length stat $30;
set t_allstats;
by ord subord;
output;
if first.ord then do ;
if ord=1 then stat='Age(years)';
if ord=2 then stat='Age groups';
if ord=3 then stat='Gender';
if ord=4 then stat='Race';
subord=0;
_0='';
_1='';
_2='';
output;
end;

proc sort;
by ord subord;
run;
/*final end  */


/*proc report and final report  */
title 'Table 1.1';
title2'Demographic and base line characterstics by treatment';
title3 'Randomized population';
footnote 'Note:percentage are based onn  the number of non-missing values in each treatment group';

proc report data=final split ='|';
columns ord subord stat _0 _1 _2;
define ord/noprint order;
define subord/ noprint order;
define stat/ display width=50 "";
define _0 / display width=30 "Placebo| (N=&Placebo)";
define _1 / display width=30 "Active Treatment| (N=&Active)";
define _2 / display width=30 "All Patients| (N=&Total)";
run;


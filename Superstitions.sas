/*Clear log if needed*/
/*dm ' log; clear;  odsresult;clear;  output; clear; ';*/

/*Import dataset, and take a look at the first 10 observations*/
proc import datafile='superstitions_00-14.csv'
	out=super
	DBMS = csv
	REPLACE;
	GETNAMES=YES;
	run;
proc print data=super(obs=10);
run;

/*1, Aggregate the data by month*/
proc sql;
	create table average_month_birth as
	select month, avg(births) as avg_month_birth from super group by month;
proc print data=average_month_birth;
run;

/*Plot birth average over month vs month*/
symbol1 interpol=join value=dot;
proc gplot data=average_month_birth;
	plot avg_month_birth*month;
	run;



/*2, Aggregate the data by day of the week*/
proc sql;
	create table average_day_birth as
	select day_of_week, avg(births) as avg_day_of_week_birth from super group by day_of_week;
proc print data=average_day_birth;
run;
/*Plot birth average over day of the week vs day of the week*/
symbol1 interpol=join value=dot;
proc gplot data=average_day_birth;
	plot avg_day_of_week_birth*day_of_week;
	run;

/*3, Compute the day of the year*/
/*I'll use variabel var1, so I check the variable type in the data to make sure it's numerical and ready for use*/
ods trace on;
proc contents data=super;
	ods output variable=VAR1;
	run;
ods trace off;

/*Change Var1 to numeric*/
data num_super;
	set super(rename=(var1=var_c));
	var1=var_c+0;
	drop var_c;
	run;
proc print data=num_super(obs=10);
run;

/*Double check if the char type has been changed to numeric type*/
ods trace on;
proc contents data=num_super;
	ods output variable=var1;
	run;
ods trace off;

/*create a new variable day_of_year*/
data day_year;
	set num_super;
	if year=2000 then
		do;
			day_of_year=var1;
		end;
	else 
		do;
			day_of_year=var1-(floor((year-2000-1)/4)+1)*366-(year-2000-(floor((year-2000-1)/4)+1))*365;
		end;
	run;
proc print data=day_year(obs=10);
run;


/*Aggregate the data by day of the year.*/
proc sql;
	create table avg_day_year as
	select day_of_year, avg(births) as avg_day_of_year_birth from day_year group by day_of_year;
proc print data=avg_day_year;
run;
/*plot birth average over day of the year vs day of the year*/
symbol1 interpol=join value=dot;
proc gplot data=avg_day_year;
	plot avg_day_of_year_birth*day_of_year;
	run;

/*Regular holiday effect*/
%let month=1;
%let date=1; 
%let week=1;
%let holi=New_year;
proc sql;
	create table new_year as
	select avg(births) as &holi from num_super where month=&month & date_of_month=&date;
	run;
proc print data=new_year;
	run;

/*4, numerically compare the births on Fridays (not the 13th) with births on Fridays that are the 13th*/
/*Create a new table concacted by table of births on Friday (not the 13th) and table of births on Fridays that are the 13th*/
proc sql;
	create table fri_13 as
	select date_of_month, births from num_super where day_of_week=5 & date_of_month=13;
	create table fri_not_13 as
	select date_of_month, births from num_super where day_of_week=5 & date_of_month^=13;
	run;
	create table compare as
		select * from fri_13 
		union all 
		select * from fri_not_13
	run;
proc print data=compare;
title "Birth on Friday that are th 13th and not the 13th";
run;

/*categorize different cases into class 1 and class 2*/
data compare_cate;
	set compare;
	if date_of_month=13 then class=1;
	if date_of_month^=13 then class=2;
	run;
proc print data=compare_cate;
run;

/*Perform a T test*/
proc glimmix data=compare_cate;
	class class;
	model births=class;
	lsmeans class;
run;





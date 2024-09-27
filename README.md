# Sports Team Activity Analysis
A real-world data analytics project for a sports technology company using SQL and Tableau by Bruno Xie

## Overview
This project analyzes team engagement and activity data for a sports technology company that offers performance analysis tools for coaches and players. The primary focus is to evaluate upload frequency, user video consumption, team retention, and upload behavior across various team levels. The goal of this analysis is to provide insights into customer behavior and inform retention and marketing strategies for different types of teams, with special attention to identifying trends that might help improve customer engagement.

## Data Source
The analysis is based on internal team activity data from the company. It includes metrics such as the number of uploads, user video views, team retention rates, and team level breakdowns (Varsity, JV, etc.). It consists of anonymized data points for thousands of teams across multiple states. The dataset can be found [here](Data/team_activity.csv).

## Methodology
1. **Data Loading**: The raw data was loaded into MySQL Workbench, and corresponding tables were created for further processing.
2. **Data Cleaning**: School-level data was cleaned to ensure accurate analysis. SQL queries were used to filter and retrieve relevant insights.
3. **Analysis**: Several key metrics were analyzed, such as:
   - Team upload frequency in the past 60 days.
   - User video consumption by team in the past 60 days.
   - Retention rates over time, focusing on teams with a significant drop in activity over the last 7 days.
   - Upload activity segmented by team level and state.
4. **Visualization**: The cleaned and processed data was exported into Tableau for visualization, presenting actionable insights on team activity, retention, and engagement patterns.

## SQL Script
The SQL code used to clean and summarize the data is included [here](Code.sql) in the repository. 

## Tableau Dashboard
The summary numbers created by the SQL code was loaded into Tableau and several dashboards were created. The Tableau workbook can be found [here](Dashboard.twb). The actual dashboards are [here](Dashboards).

## Analysis
The final deliverable of this project is a detailed analysis answering multiple business questions regarding team activity and user behavior. The Tableau dashboards created are included in it as well. One can find the analysis [here](Analysis Summary.pdf).

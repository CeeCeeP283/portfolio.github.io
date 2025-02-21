/* Set library reference*/
LIBNAME PharmE'/home/u62305756/RWE';

/* Import the dataset */
PROC IMPORT DATAFILE="/home/u62305756/RWE/RWE_Oncology_Epidemiology_Study.xlsx" 
		OUT=RWE_Oncology_Epidemiology_Study 
		DBMS=XLSX 
		REPLACE;
	GETNAMES=YES;
RUN;


/* Step 2: Check the structure of the dataset */
PROC CONTENTS DATA=RWE_Oncology_Epidemiology_Study ;
RUN;


/* Step 3: Data Cleaning - Handle missing values and validate treatment variables */
DATA oncology_cleaned1;
    SET RWE_Oncology_Epidemiology_Study;
    /* Example: Recode missing treatment values as 'Unknown' */
    IF Treatment_Type = "" THEN Treatment_Type = "Unknown";
RUN;

/* Step 4: Summary statistics for key continuous variables */
PROC MEANS DATA=oncology_cleaned1 N MEAN MEDIAN STD MIN MAX;
    VAR Age Sample_Size;
RUN;


/* Step 5: Frequency distribution of treatment types */
PROC FREQ DATA=oncology_cleaned1;
    TABLES Treatment_Type Cancer_Type / MISSING;
RUN;

/* Step 6: Construct cohorts for Chemotherapy and Immunotherapy */
DATA chemotherapy_cohort;
    SET oncology_cleaned1;
    IF Treatment_Type = "Chemotherapy";
RUN;

DATA immunotherapy_cohort;
    SET oncology_cleaned1;
    IF Treatment_Type = "Immunotherapy";
RUN;

/* Step 7: Validate cohorts (e.g., by age or comorbidity) */
PROC MEANS DATA=chemotherapy_cohort N MEAN MEDIAN;
    VAR Age Sample_Size;
RUN;


PROC MEANS DATA=immunotherapy_cohort N MEAN MEDIAN;
    VAR Age Sample_Size;
RUN;

/* Step 8: Propensity score estimation using logistic regression */
PROC LOGISTIC DATA=oncology_cleaned1 OUTMODEL=psm_model;
    CLASS Treatment_Type (PARAM=REF) Cancer_Type;
    MODEL Treatment_Type = Age Cancer_Type / SELECTION=NONE;
    OUTPUT OUT=psm_scores PREDICTED=Propensity_Score;
RUN;

/* Step 9: Match cohorts using the estimated propensity scores */
PROC SQL;
    CREATE TABLE matched_data AS
    SELECT a.*, b.Study_ID AS Matched_Study_ID
    FROM psm_scores a
    LEFT JOIN (SELECT DISTINCT Propensity_Score, Study_ID
               FROM psm_scores) b
    ON ABS(a.Propensity_Score - b.Propensity_Score) <= 0.05 /* Adjust tolerance as needed */
    ;
QUIT;



PROC FREQ DATA=matched_data;
    TABLES Study_ID / NOCUM NOPERCENT;
RUN;

PROC UNIVARIATE DATA=matched_data;
    VAR Propensity_Score;
RUN;

PROC MEANS DATA=matched_data N MEAN STD MIN MAX;
    CLASS Treatment_Type Cancer_Type;
    VAR Age ;
RUN;


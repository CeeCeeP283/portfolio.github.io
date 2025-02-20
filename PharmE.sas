/* Set library reference*/
LIBNAME PharmE'/home/u62305756/RWE';

/* Import the dataset */
PROC IMPORT DATAFILE="/home/u62305756/RWE/RWE_Oncology_Epidemiology_Study.xlsx" 
		OUT=RWE_Oncology_Epidemiology_Study DBMS=XLSX REPLACE;
	GETNAMES=YES;
RUN;

/*  Date format */
PROC PRINT DATA=RWE_Oncology_Epidemiology_Study (OBS=10);
	VAR Start_Date End_Date;
RUN;

/*  Check missing date */
PROC FREQ DATA=RWE_Oncology_Epidemiology_Study;
	TABLES Start_Date End_Date / MISSING;
RUN;

/*Check for missing values */
PROC MEANS DATA=RWE_Oncology_Epidemiology_Study N NMISS;
RUN;

/*Identify duplicate records */
PROC SORT DATA=RWE_Oncology_Epidemiology_Study NODUPKEY OUT=oncology_cleaned;
	BY Study_ID;

	/* Assuming Study_ID is a unique identifier */
RUN;

/*Check data consistency for critical variables */
PROC FREQ DATA=oncology_cleaned;
	TABLES Cancer_Type Study_Type Treatment_Type Geographic_Location / MISSING;
RUN;

/* Step 7: Recode missing values */
DATA oncology_cleaned;
	SET oncology_cleaned;

	/* Recode empty values in 'Cancer_Type' as 'Unknown' */
	IF Cancer_Type="" THEN
		Cancer_Type="Unknown";
RUN;

*Descriptive Statistics*;

/* Summary statistics for continuous variables */
PROC MEANS DATA=oncology_cleaned MEAN MEDIAN STD MIN MAX;
	VAR Sample_Size Age;

	/* Assuming Sample_Size and Age are continuous variables */
RUN;

/* Frequency distributions for categorical variables */
PROC FREQ DATA=oncology_cleaned;
	TABLES Cancer_Type Study_Type Treatment_Type Geographic_Location / MISSING;
RUN;

/* Generate summary statistics for numerical variables */
PROC MEANS DATA=RWE_Oncology_Epidemiology_Study N MEAN MEDIAN STD MIN MAX;
	VAR Sample_Size;
RUN;

/*Construct cohort of patients with Breast Cancer and Chemotherapy treatment */
DATA cohort_breast_chemotherapy;
	SET oncology_cleaned;

	IF Cancer_Type="Breast Cancer" AND Treatment_Type="Chemotherapy";
RUN;

/* Validate the cohort (e.g., check age distribution or treatment compliance) */
PROC MEANS DATA=cohort_breast_chemotherapy N MEAN MEDIAN;
	VAR Age Sample_Size;

	/* Validate cohort age and sample size */
RUN;

/*  Cross-tabulate cancer type with treatment type */
PROC FREQ DATA=oncology_cleaned;
	TABLES Cancer_Type * Treatment_Type / CHISQ;
RUN;

* Create cross-tabulation of Cancer Type by Study Type */;

PROC FREQ DATA=oncology_cleaned;
	TABLES Cancer_Type * Study_Type /Missing CHISQ NOROW NOCOL NOPERCENT;
RUN;

*Exploratory Data Analysis*;

/* Bar chart for Cancer Type distribution */
PROC SGPLOT DATA=oncology_cleaned;
	VBAR Cancer_Type / DATALABEL;
	TITLE "Distribution of Cancer Types in Oncology Study";

	/* Histogram for Age distribution */
PROC SGPLOT DATA=oncology_cleaned;
	HISTOGRAM Age / BINWIDTH=5;
	DENSITY Age;
	TITLE "Age Distribution of Oncology Patients";
RUN;

/*Pie chart for Treatment Type distribution */
PROC GCHART DATA=oncology_cleaned;
	PIE Treatment_Type / DISCRETE VALUE=INSIDE PERCENT=INSIDE;
	TITLE "Treatment Type Distribution in Oncology Study";
	RUN;
	
	

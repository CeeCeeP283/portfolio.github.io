LIBNAME PharmE'/home/u62305756/RWE';

/* Step 1: Import the dataset */

/* Import the dataset */
PROC IMPORT DATAFILE="/home/u62305756/RWE/RWE_Oncology_Epidemiology_Study.xlsx" 
		OUT=RWE_Oncology_Epidemiology_Study
		DBMS=XLSX REPLACE;
	GETNAMES=YES;
RUN;


/* Step 2: Check the structure of the dataset */

PROC CONTENTS DATA=oncology_data1;
RUN;

DATA oncology_data1;
    SET RWE_Oncology_Epidemiology_Study;

    /* Extract Hours and Minutes as Numeric */
    IF NOT MISSING(Time_of_death) THEN DO;
        Hour = INPUT(SCAN(Time_of_death, 1, ':'), BEST.);
        Minute = INPUT(SCAN(Time_of_death, 2, ':'), BEST.);

        /* Check if time extraction was successful */
        IF MISSING(Hour) OR MISSING(Minute) THEN DO;
            PUT "ERROR: Invalid Time_of_death value: " Time_of_death=;
            Survival_Time_in_Days = .;
        END;
        ELSE DO;
            /* Convert to days */
            Survival_Time_in_Days = (Hour / 24) + (Minute / 1440);
        END;
    END;
    ELSE DO;
        Survival_Time_in_Days = .;
    END;

    /* Create censoring variable: 0 = event occurred, 1 = censored */
    IF MISSING(Survival_Time_in_Days) THEN Censor = 1;
    ELSE Censor = 0;

    /* Rename variable to remove space */
    RENAME "Response_ time"n = Response_Time;
RUN;


*Descriptive Statistics*;
PROC MEANS DATA=oncology_data1 N MEAN MEDIAN STD MIN MAX;
    VAR Survival_Time_in_Days Response_time Disease_Progression Age;
RUN;

* Frequency distribution of treatment types*;
PROC FREQ DATA=oncology_data1;
    TABLES Cancer_Type Treatment_Type Gender Ethnicity Censor / MISSING;
RUN;

*Kaplan-Meier survival analysis;
PROC LIFETEST DATA=oncology_data1 PLOTS=SURVIVAL;
    TIME Survival_Time_in_Days * Censor(1); /* Censoring variable */
    STRATA Treatment_Type; /* Compare by treatment */
    TITLE "Kaplan-Meier Survival Curve by Treatment Type";
RUN;

* Cox proportional hazards model *;
PROC PHREG DATA=oncology_data1;
    CLASS Treatment_Type Cancer_Type / PARAM=REF;
    MODEL Survival_Time_in_Days * Censor(1) = Treatment_Type Age Cancer_Type / RL;
    STRATA Cancer_Type;
    TITLE "Cox Proportional Hazards Model for Treatment Effect on Survival";
RUN;

/* Kaplan-Meier survival curve */
PROC SGPLOT DATA=oncology_data1;
    SERIES X=Study_Time Y=Survival_Time_in_Days / GROUP=Treatment_Type;
    TITLE "Survival Curve by Treatment Type";
RUN;


/* Box plot for Response Time */
PROC SGPLOT DATA=oncology_data1;
    VBOX response_time / CATEGORY=Treatment_Type;
    TITLE "Response_ time by Treatment Type";
RUN;

/* Step 11: Plot survival curves for each treatment type */
PROC SGPLOT DATA=oncology_data1;
    VBAR Treatment_Type / DATALABEL;
    TITLE "Treatment Type Distribution";
RUN;


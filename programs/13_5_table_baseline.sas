/* Chapter 13: a second table with the same macros: baseline characteristics from ADSL and ADVS */

PROC FORMAT;
  VALUE trtf 0 = "Placebo" 54 = "Xanomeline Low Dose" 81 = "Xanomeline High Dose";
RUN;

%m_bign(data=refadm.adsl, by=trt01an, where=saffl = "Y", out=bl_bign)

/* BMIBLGR1 is text, and text sorts "25-<30" before "<25". ADSL has no numeric twin: make one */
DATA bl_adsl;
  SET refadm.adsl(WHERE=(saffl = "Y"));
  bmiblgr1n = WHICHC(bmiblgr1, "<25", "25-<30", ">=30");
RUN;

/* From ADSL: one record per subject */
%m_desc(data=refadm.adsl, var=heightbl, by=trt01an, where=saffl = "Y", dec=1,
        label=Height (cm), ord=1, out=bl_height)
%m_desc(data=refadm.adsl, var=weightbl, by=trt01an, where=saffl = "Y", dec=1,
        label=Weight (kg), ord=2, out=bl_weight)
%m_desc(data=refadm.adsl, var=bmibl, by=trt01an, where=saffl = "Y", dec=1,
        label=BMI (kg/m2), ord=3, out=bl_bmi)
%m_freq(data=bl_adsl, var=bmiblgr1, orderby=bmiblgr1n, by=trt01an,
        denom=bl_bign, label=BMI group, ord=4, out=bl_bmigr)

/* From ADVS: one record per subject, parameter, visit and position: the WHERE picks the baseline */
%m_desc(data=refadm.advs, var=aval, by=trtan,
        where=saffl = "Y" AND ablfl = "Y" AND paramcd = "SYSBP" AND atptn = 815,
        label=Systolic BP lying (mmHg), ord=5, out=bl_sysbp)
%m_desc(data=refadm.advs, var=aval, by=trtan,
        where=saffl = "Y" AND ablfl = "Y" AND paramcd = "DIABP" AND atptn = 815,
        label=Diastolic BP lying (mmHg), ord=6, out=bl_diabp)
%m_desc(data=refadm.advs, var=aval, by=trtan,
        where=saffl = "Y" AND ablfl = "Y" AND paramcd = "PULSE" AND atptn = 815,
        label=Pulse lying (beats/min), ord=7, out=bl_pulse)

DATA bl_rows;
  SET bl_height bl_weight bl_bmi bl_bmigr bl_sysbp bl_diabp bl_pulse;
RUN;

OPTIONS LS=110 PS=60 NOCENTER;
TITLE1 "Table 14.1.3 Baseline characteristics (safety population)";
%m_report(data=bl_rows, denom=bl_bign, fmt=trtf.)
TITLE;

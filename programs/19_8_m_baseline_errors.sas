/* EXPECT: ERROR [M_BASELINE] */
/* Case study: wrong calls of %m_baseline stop before any step runs (needs 10_1 and the macros of 10_2_0) */

/* 1: a required parameter is empty */
%m_baseline(data=advs_020, out=x1, by=)

/* 2: the input does not exist */
%m_baseline(data=advs_typo, out=x2)

/* 3: the sort order does not start with the groups */
%m_baseline(data=advs_020, out=x3, sortby=usubjid adt paramcd)

/* 4: copy= has a value the macro does not know */
%m_baseline(data=advs_020, out=x4, copy=yes)

%PUT NOTE: x1 exists=%SYSFUNC(EXIST(x1)) x2 exists=%SYSFUNC(EXIST(x2)) x3 exists=%SYSFUNC(EXIST(x3)) x4 exists=%SYSFUNC(EXIST(x4));

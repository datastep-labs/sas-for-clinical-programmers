/* EXPECT: ERROR A character operand was found in the %EVAL function */
/* Chapter 17: %EVAL knows only whole numbers */
%PUT NOTE: %EVAL(1.5 + 1);

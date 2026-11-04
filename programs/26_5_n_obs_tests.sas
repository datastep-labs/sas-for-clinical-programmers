/* EXPECT: ERROR [N_OBS] */
/* Chapter 26: the tests of %n_obs, written before the macro */
%MACRO assert_eq(actual, expected, desc);
  %IF %SUPERQ(actual) = %SUPERQ(expected) %THEN %PUT NOTE: [TEST] pass: &desc.;
  %ELSE %PUT %STR(ERR)OR: [TEST] FAIL: &desc.: got &actual., expected &expected.;
%MEND assert_eq;

%assert_eq(%n_obs(data=refadm.adsl), 254, all subjects of ADSL)
%assert_eq(%n_obs(data=refadm.adae, where=%STR(trtemfl = "Y")), 1126, treatment-emergent AE records)
%assert_eq(%n_obs(data=refadm.adae, where=%STR(trtemfl = "Y" AND aesev = "SEVERE")), 41, severe TEAE records)
%assert_eq(%n_obs(data=refadm.adae, where=%STR(aesev = "NONE")), 0, a WHERE that keeps nothing)
%assert_eq(%n_obs(data=work.nothere), -1, a data set that does not exist)

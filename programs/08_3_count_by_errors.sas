/* EXPECT: ERROR [COUNT_BY] */
/* Chapter 8: wrong calls stop with a clear message */
%count_by(data=refadm.adae, by=trtan nosuchvar)
%count_by(data=work.nothere, by=trtan)
%count_by(by=trtan)

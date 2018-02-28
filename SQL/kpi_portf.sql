SELECT   TRUNC (SYSDATE, 'ddd') - 1 AS datum,
         vonalkod,
         modtyp AS termcsop,
         CASE
            WHEN papir_tipus = 1 THEN 'Papir'
            WHEN papir_tipus = 2 THEN 'FE'
            WHEN papir_tipus = 4 THEN 'Ajp'
            WHEN papir_tipus = 5 THEN 'Elektra'
            WHEN papir_tipus = 6 THEN 'Elek'
            WHEN papir_tipus = 7 THEN 'MySigno'
            WHEN papir_tipus = 8 THEN 'Távért'
            WHEN papir_tipus = 9 THEN 'Enyil'
         END
            AS kotesi_mod,
         CASE
            WHEN EXISTS
                    (SELECT   f_vonalkod
                       FROM   ab_t_akr_esemeny x
                      WHERE   f_esemeny IN
                                    ('D2',
                                     'M3',
                                     '7S',
                                     '7T',
                                     '72',
                                     '77',
                                     '7E',
                                     '7A')
                              AND x.f_vonalkod = a.vonalkod)
            THEN
               'Automatikus'
            ELSE
               'Manualis'
         END
            AS kotvenyesites,
         erkdat,
         szerzdat,
         szerzdat - erkdat - bnap_db (szerzdat, erkdat) AS erk_szerz
  FROM   t_bsc_kontroll a
 WHERE       szerzdat IS NOT NULL
         AND TRUNC (szerzdat, 'mm') = TRUNC (SYSDATE - 1, 'mm')
         AND erkdat - alirdat < 90
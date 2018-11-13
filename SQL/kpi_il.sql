SELECT   DISTINCT
         TRUNC (SYSDATE - 1, 'ddd') AS datum,
         f_ivk,
         f_kpi_kat,
         CASE
            WHEN irat_tipus IN
                       ('_AFC_L_Ajánlatkezelés',
                        '_AFC_L_Visszaesõ tétel',
                        '_AFC_L_Díjkezelés',
                        '_AFC_L_Szerzõdéskezelés')
            THEN
               irat_tipus
            ELSE
               'Egyéb'
         END
            AS irat_tipus,
         f_szarm_szerv,
         CASE WHEN afcerk_lezarva_mn > 15 THEN 1 ELSE 0 END AS nap15,
         afcerk_lezarva_mn AS erk_lezar,
         lezarva
  FROM   (
  SELECT   DISTINCT
               AFC_LEZART.f_ivk f_ivk,
               t_afcil_attrib.F_ERKEZES AEGON_ERK,
               t_afcil_attrib.F_ERKEZES_AFC AFC_ERK,
               AFC_LEZART.LEZARVA,
               t_afcil_attrib.F_KPI_KAT,
               t_afcil_attrib.F_SZARM_SZERV,
               t_afcil_attrib.F_IRAT_TIPUSID,
               kontakt.basic.get_irat_tipusid_irat_tipus (
                  t_afcil_attrib.f_irat_tipusid
               )
                  IRAT_TIPUS,
               t_afcil_attrib.F_ALIRATTIPUSID,
               kontakt.basic.get_alirattipusid_alirattipus (
                  t_afcil_attrib.f_alirattipusid
               )
                  IRAT_FOTEV_ALIRATTIPUS,
               kontakt.basic_km.afcil_fofolyamat (AFC_LEZART.f_ivk)
                  FOTEV_IVKWFID,
               t_afcil_attrib.F_GYEREKTEV_SZAMA,
               AFC_LEZART.f_userid LEZARO_USERID,
               CASE
                  WHEN AFC_LEZART.f_userid IN
                             (SELECT   DISTINCT f_userid
                                FROM   kontakt.t_user
                               WHERE   f_csoportid IN
                                             (SELECT   DISTINCT f_csoportid
                                                FROM   kontakt.t_csoport
                                               WHERE   f_szervezet LIKE 'C%'))
                  THEN
                     'CCC'
                  WHEN AFC_LEZART.f_userid IN
                             (SELECT   DISTINCT f_userid
                                FROM   kontakt.t_user
                               WHERE   f_csoportid IN
                                             (SELECT   DISTINCT f_csoportid
                                                FROM   kontakt.t_csoport
                                               WHERE   f_szervezet = 'AFC'))
                  THEN
                     'AFC'
                  ELSE
                     'EGYÉB'
               END
                  AS LEZARO_SZERVEZET,
               TRUNC (
                  kontakt.basic.munkanapok (t_afcil_attrib.F_ERKEZES,
                                            LEZARVA),
                  2
               )
                  AEGONERK_LEZARVA_MN,
               TRUNC (
                  kontakt.basic.munkanapok (t_afcil_attrib.F_ERKEZES_AFC,
                                            LEZARVA),
                  2
               )
                  AFCERK_LEZARVA_MN,
               TRUNC (LEZARVA - t_afcil_attrib.F_ERKEZES, 2)
                  AEGONERK_LEZARVA_NN,
               TRUNC (LEZARVA - t_afcil_attrib.F_ERKEZES_AFC, 2)
                  AFCERK_LEZARVA_NN
        FROM      kontakt.t_afcil_attrib
               LEFT OUTER JOIN
                  (  SELECT   DISTINCT
                              f_ivk,
                              t_afcil_kecs.f_idopont LEZARVA,
                              MAX (f_userid) f_userid
                       FROM      k2017afc.t_afcil_kecs
                              JOIN
                                 kontakt.t_irat_wflog
                              USING (f_ivk)
                      WHERE   f_kecsid = 259
                              AND t_afcil_kecs.f_idopont BETWEEN TRUNC (
                                                                    SYSDATE - 1,
                                                                    'mm'
                                                                 )
                                                             AND  TRUNC (
                                                                     SYSDATE,
                                                                     'ddd'
                                                                  )
                              AND t_afcil_kecs.f_idopont =
                                    t_irat_wflog.f_idopont
                   GROUP BY   f_ivk, t_afcil_kecs.f_idopont) AFC_LEZART
               ON (t_afcil_attrib.f_ivk = AFC_LEZART.f_ivk)
       WHERE   t_afcil_attrib.f_lezaras BETWEEN TRUNC (SYSDATE - 1, 'mm')
                                            AND  TRUNC (SYSDATE, 'ddd')
  ) t1
 WHERE   lezarva BETWEEN TRUNC (SYSDATE - 1, 'mm') AND TRUNC (SYSDATE, 'ddd')
         AND lezaro_szervezet = 'AFC'
         AND f_alirattipusid NOT IN ('1940', '1941', '1942', '1943') --igényfelmérõ
         AND NOT EXISTS (SELECT   1
                           FROM   kontakt.t_irat_wflog t2
                          WHERE   t2.f_ivk = t1.f_ivk AND t2.f_wfid = 1195)
         AND f_irat_tipusid NOT IN (418, 423, 430, 453)
         AND afcerk_lezarva_mn <= 100
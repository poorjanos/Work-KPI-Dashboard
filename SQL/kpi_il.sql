SELECT   DISTINCT
         TRUNC (SYSDATE - 1, 'ddd') AS datum,
         f_ivk,
         f_kpi_kat,
         CASE
            WHEN irat_tipus IN
                       ('_AFC_L_Aj�nlatkezel�s',
                        '_AFC_L_Visszaes� t�tel',
                        '_AFC_L_D�jkezel�s',
                        '_AFC_L_Szerz�d�skezel�s')
            THEN
               irat_tipus
            ELSE
               'Egy�b'
         END
            AS irat_tipus,
         f_szarm_szerv,
         CASE WHEN afcerk_lezarva_mn > 15 THEN 1 ELSE 0 END AS nap15,
         afcerk_lezarva_mn AS erk_lezar,
         lezarva
  FROM   t_bsc_irat t1
 WHERE   lezarva BETWEEN TRUNC (SYSDATE - 1, 'mm') AND TRUNC (SYSDATE, 'ddd')
         AND lezaro_szervezet = 'AFC'
         AND f_alirattipusid NOT IN ('1940', '1941', '1942', '1943') --ig�nyfelm�r�
         AND NOT EXISTS (SELECT   1
                           FROM   kontakt.t_irat_wflog t2
                          WHERE   t2.f_ivk = t1.f_ivk AND t2.f_wfid = 1195)
         AND f_irat_tipusid NOT IN (418, 423, 430, 453)
         AND afcerk_lezarva_mn <= 100
CREATE OR REPLACE PROCEDURE POORJ.BSC_BASE
IS
BEGIN                                                                  --ABLAK
   EXECUTE IMMEDIATE 'TRUNCATE TABLE t_bsc_ablak';

   COMMIT;


   INSERT INTO t_bsc_ablak (idoszaki, vonalkod)
      SELECT   DISTINCT 'I', f_vonalkod
        FROM   ab_t_akr_esemeny
       WHERE   f_datum BETWEEN TRUNC (SYSDATE - 1, 'mm')
                           AND  TRUNC (SYSDATE, 'ddd')
               AND f_esemeny IN
                        ('01',
                         '31',
                         '35',
                         '70',
                         '37',
                         '38',
                         'DE',
                         'DA',
                         'M0',
                         'M1',
                         'M2',
                         'M3',
                         'M4',
                         '7D',
                         'E0',
                         'E1',
                         'E3',
                         '28');                    --37, 38 = elektrás tételek

   COMMIT;

   --prompt idõszakban szerzõdéssé ill. elutasítottá ill. stornózottá vált tételek

   INSERT INTO t_bsc_ablak (idoszaki, vonalkod)
        SELECT                             --+ driving_site (ab_t_akr_esemeny)
              DISTINCT 'N', f_vonalkod
          FROM   ab_t_akr_esemeny
         WHERE   f_datum BETWEEN TRUNC (SYSDATE - 1, 'mm')
                             AND  TRUNC (SYSDATE, 'ddd')
                 AND f_esemeny IN
                          ('14',
                           '18',
                           '50',
                           '51',
                           '60',
                           '9H',
                           '15',
                           '19',
                           '41',
                           '45',
                           '48',
                           '9C',
                           '40',
                           '52',
                           '53',
                           '72',
                           '77',
                           '79',
                           '7T',
                           '7S',
                           '7E',
                           '7A')                   --7t, 7s = elektrás tételek
      GROUP BY   f_vonalkod
        HAVING   MIN (f_datum) BETWEEN TRUNC (SYSDATE - 1, 'mm')
                                   AND  TRUNC (SYSDATE, 'ddd');

   COMMIT;

   --prompt többszörözõdõ idoszaki tételek törlése

   DELETE FROM   t_bsc_ablak
         WHERE   idoszaki = 'N'
                 AND (vonalkod) IN (SELECT   vonalkod
                                      FROM   t_bsc_ablak
                                     WHERE   idoszaki = 'I');

   COMMIT;



   --prompt szerzazon adatok töltése:;

   UPDATE   t_bsc_ablak a
      SET   szerzazon =
               (  SELECT   MAX (f.f_szerz_azon)
                    FROM   ab_t_akr_ajanlat f
                   WHERE   f.f_vonalkod = a.vonalkod
                GROUP BY   f.f_vonalkod);

   COMMIT;

   --prompt modkod töltése:;

   UPDATE   t_bsc_ablak a
      SET   (modkod) =
               (SELECT   b.f_modkod
                  FROM   ab_t_akr_kotveny b
                 WHERE   b.f_szerz_azon = a.szerzazon);

   COMMIT;

   --prompt állapotkód töltése:

   UPDATE   t_bsc_ablak a
      SET   allapotkod =
               (SELECT   NVL (b.f_allapot, c.f_allapot)
                  FROM   ab_t_kotveny b, ab_t_akr_kotveny c
                 WHERE   b.f_szerz_azon(+) = a.szerzazon
                         AND c.f_szerz_azon = a.szerzazon);

   COMMIT;

   --prompt szerzõ adatainak töltése:;
   --prompt ugynokkod és kti adatok töltése:;

   UPDATE   t_bsc_ablak a
      SET
            (ugynokkod,
            ktikod,
            ktinev,
            ertcsat
            ) =
               (SELECT                                          --+ first_rows
                      c  .f_torzsszam,
                         NVL (e.f_ktikod, '0000000'),
                         e.f_ktinev,
                         f.f_ertcsat
                  FROM   ab_r_dolg_viszony c,
                         ab_t_dolgozo d,
                         ab_m_szervhier e,
                         ab_t_jut_viszony f
                 WHERE   (fdb_akr_riport.szerzo_dazon (a.szerzazon) =
                             c.f_dazon(+)
                          AND (c.f_aktiv = 'I' OR c.f_aktiv IS NULL))
                         AND c.f_torzsszam = d.f_torzsszam(+)
                         AND d.f_gstock = e.f_stock(+)
                         AND c.f_beosztas = f.f_viszony(+));

   COMMIT;

   --prompt szerzõ nevének töltése:;

   UPDATE   t_bsc_ablak a
      SET   ugynoknev =
               (SELECT                                          --+ first_rows
                      g  .f_ugyfelnev
                  FROM   ab_t_dolgozo f, ab_t_ugyfel g
                 WHERE   f.f_torzsszam = a.ugynokkod
                         AND g.f_ugyazon = f.f_ugyazon);

   COMMIT;


   --prompt eseménybejegyzési adatok töltése:;
   --prompt Áláírás dátuma:;

   UPDATE   t_bsc_ablak a
      SET   alirdat =
               (SELECT   b.f_szerkot
                  FROM   ab_t_akr_kotveny b
                 WHERE   b.f_szerz_azon = a.szerzazon);

   COMMIT;

   --prompt Érkeztetési adatok töltése:;

   UPDATE   t_bsc_ablak a
      SET   erkdat =
               (SELECT   MIN (b.f_datum)
                  FROM   ab_t_akr_esemeny b
                 WHERE   b.f_esemeny IN
                               ('01',
                                '31',
                                '35',
                                '70',
                                '37',
                                '38',
                                'DE',
                                'DA',
                                'M0',
                                'M1',
                                'M2',
                                'M3',
                                'M4',
                                '7D',
                                'E0',
                                'E1',
                                'E3',
                                '28')
                         AND b.f_vonalkod = a.vonalkod);

   COMMIT;

   --prompt rögzítési adatok töltése:;

   UPDATE   t_bsc_ablak a
      SET
            (rogzdat,
            rogzkod
            ) =
               (SELECT   b.f_datum, c.f_torzsszam
                  FROM   ab_t_akr_esemeny b, ab_r_dolg_viszony c
                 WHERE   c.f_dazon = b.f_dazon
                         AND (b.f_vonalkod, b.f_datum) IN
                                  (  SELECT   f_vonalkod, MIN (f_datum)
                                       FROM   ab_t_akr_esemeny
                                      WHERE   f_esemeny IN ('08', '09')
                                              AND f_vonalkod = a.vonalkod
                                   GROUP BY   f_vonalkod)
                         AND b.f_esemeny IN ('08', '09')
                         AND b.f_vonalkod = a.vonalkod);

   COMMIT;

   UPDATE   t_bsc_ablak a
      SET
            (rogzdat,
            rogzkod
            ) =
               (SELECT   b.f_datum, c.f_torzsszam
                  FROM   ab_t_akr_esemeny b, ab_r_dolg_viszony c
                 WHERE   c.f_dazon = b.f_dazon
                         AND (b.f_vonalkod, b.f_datum) IN
                                  (  SELECT   f_vonalkod, MIN (f_datum)
                                       FROM   ab_t_akr_esemeny
                                      WHERE   f_esemeny IN
                                                    ('14',
                                                     '18',
                                                     '20',
                                                     '52',
                                                     '53')
                                              AND f_vonalkod = a.vonalkod
                                              AND a.rogzdat IS NULL
                                   GROUP BY   f_vonalkod)
                         AND b.f_esemeny IN ('14', '18', '20', '52', '53')
                         AND b.f_vonalkod = a.vonalkod)
    WHERE   a.rogzdat IS NULL;

   COMMIT;

   --prompt menesztési adatok töltése:;

   UPDATE   t_bsc_ablak a
      SET
            (szerzdat,
            szerzkod
            ) =
               (SELECT   b.f_datum, c.f_torzsszam
                  FROM   ab_t_akr_esemeny b, ab_r_dolg_viszony c
                 WHERE   c.f_dazon = b.f_dazon
                         AND (b.f_vonalkod, b.f_datum) IN
                                  (  SELECT   f_vonalkod, MIN (f_datum)
                                       FROM   ab_t_akr_esemeny
                                      WHERE   f_esemeny IN
                                                    ('14',
                                                     '18',
                                                     '50',
                                                     '51',
                                                     '52',
                                                     '53',
                                                     '72',
                                                     '77',
                                                     '79',
                                                     '7T',
                                                     '7S',
                                                     '7E',
                                                     '7A',
                                                     'M3')
                                              AND f_vonalkod = a.vonalkod
                                   GROUP BY   f_vonalkod)
                         AND b.f_esemeny IN
                                  ('14',
                                   '18',
                                   '50',
                                   '51',
                                   '52',
                                   '53',
                                   '72',
                                   '77',
                                   '79',
                                   '7T',
                                   '7S',
                                   '7E',
                                   '7A',
                                   'M3')
                         AND b.f_vonalkod = a.vonalkod);



   --prompt elutasítási adatok töltése:;

   UPDATE   t_bsc_ablak a
      SET   elutdat =
               (SELECT   MIN (f_datum)
                  FROM   ab_t_akr_esemeny
                 WHERE   f_esemeny IN ('15', '19', '41', '45', '48')
                         AND f_vonalkod = a.vonalkod);

   COMMIT;

   --prompt stornó adatok töltése:;

   UPDATE   t_bsc_ablak a
      SET   stornodat =
               (SELECT   MIN (f_datum)
                  FROM   ab_t_akr_esemeny
                 WHERE   f_esemeny IN ('04', '40', '9A', '9B', '9C')
                         AND f_vonalkod = a.vonalkod);

   COMMIT;


   UPDATE   t_bsc_ablak a
      SET   modtyp = 'Life'
    WHERE      a.modkod LIKE '13%'
            OR a.modkod LIKE '12%'
            OR a.modkod LIKE '11%'
            OR a.modkod LIKE '15%';

   UPDATE   t_bsc_ablak a
      SET   modtyp = 'Vagyon'
    WHERE       a.modkod LIKE '21%'
            AND a.modkod NOT LIKE '217%'
            AND a.modkod NOT LIKE '218%'
            AND a.modkod NOT LIKE '2186%';

   UPDATE   t_bsc_ablak a
      SET   modtyp = 'Casco'
    WHERE   a.modkod LIKE '218%' AND a.modkod NOT LIKE '2186%';

   UPDATE   t_bsc_ablak a
      SET   modtyp = 'GFB'
    WHERE   a.modkod LIKE '35%';

   UPDATE   t_bsc_ablak a
      SET   modtyp = 'VVR'
    WHERE      a.modkod LIKE '217%'
            OR a.modkod LIKE '2186%'
            OR a.modkod LIKE '22%'
            OR a.modkod LIKE '23%'
            OR a.modkod LIKE '24%'
            OR a.modkod LIKE '33%'
            OR a.modkod LIKE '34%'
            OR a.modkod LIKE '36%';

   COMMIT;


   UPDATE   t_bsc_ablak a
      SET   erk_esemeny =
               (SELECT   DISTINCT
                         FIRST_VALUE(f_esemeny)
                            OVER (PARTITION BY f_vonalkod
                                  ORDER BY f_datum DESC)
                  FROM   ab_t_akr_esemeny b
                 WHERE   a.vonalkod = b.f_vonalkod
                         AND f_esemeny IN
                                  ('01',
                                   '31',
                                   '32',
                                   '35',
                                   '70',
                                   '37',
                                   '38',
                                   'DE',
                                   'DA',
                                   'M0',
                                   'M1',
                                   'M4',
                                   '7D',
                                   'E0',
                                   'E1',
                                   'E3',
                                   '28'));

   COMMIT;

   UPDATE   t_bsc_ablak a
      SET   papir_tipus = 1
    WHERE   erk_esemeny IN ('01', '31');

   UPDATE   t_bsc_ablak a
      SET   papir_tipus = 2
    WHERE   erk_esemeny IN ('32', '35');

   UPDATE   t_bsc_ablak a
      SET   papir_tipus = 4
    WHERE   erk_esemeny IN ('70');

   UPDATE   t_bsc_ablak a
      SET   papir_tipus = 5
    WHERE   erk_esemeny IN ('DE');

   UPDATE   t_bsc_ablak a
      SET   papir_tipus = 6
    WHERE   erk_esemeny IN ('DA');

   UPDATE   t_bsc_ablak a
      SET   papir_tipus = 7
    WHERE   erk_esemeny IN ('M0', 'M1', 'M4');

   UPDATE   t_bsc_ablak a
      SET   papir_tipus = 8
    WHERE   erk_esemeny IN ('37', '38', '7D', '28');

   UPDATE   t_bsc_ablak a
      SET   papir_tipus = 9
    WHERE   erk_esemeny IN ('E0', 'E1', 'E3');

   COMMIT;



   --prompt frontendesnél rogzdat helyére érkdat

   UPDATE   t_bsc_ablak a
      SET   rogzdat = erkdat
    WHERE   a.frontend = 'I';

   COMMIT;



   --FUFI
   EXECUTE IMMEDIATE 'TRUNCATE TABLE t_bsc_fufi';


   EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM fpack FOR pack@dijtart_exdbp_f400';

   EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM fproposal FOR proposal@dijtart_exdbp_f400';

   EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM facquisitor FOR acquisitor@dijtart_exdbp_f400';

   EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM fproposal_error_log FOR proposal_error_log@dijtart_exdbp_f400';

   EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM fproposal_letter FOR proposal_letter@dijtart_exdbp_f400';

   COMMIT;

   INSERT INTO t_bsc_fufi (vonalkod,
                           szerzazon,
                           modkod,
                           allapotkod,
                           ugynokkod,
                           ugynoknev,
                           ktikod,
                           ktinev,
                           ertcsat,
                           alirdat,
                           erkdat,
                           rogzdat,
                           rogzkod,
                           szerzdat,
                           szerzkod,
                           elutdat,
                           stornodat,
                           frontend,
                           hibas,
                           modtyp)
        SELECT   fproposal.proposal_idntfr,                         --vonalkód
                 TO_CHAR (fpack.oid_to_idntfr (fproposal.contract_oid)), -- szerzazon
                 fproposal.product_code,                              --Módkod
                 fpack.contract_status_actuarial (fproposal.contract_oid,
                                                  SYSDATE),       --állapotkód
                 fpack.proposal_acquisitor_id (fproposal.proposal_idntfr), --Ügynökkód
                 fpack.user_name (
                    fpack.proposal_acquisitor_id (fproposal.proposal_idntfr)
                 ),                                               -- Ügynöknév
                 fpack.proposal_kti (fproposal.proposal_idntfr),    -- KTI kód
                 fpack.kti_name (
                    fpack.proposal_kti (fproposal.proposal_idntfr)
                 ),                                                   --KTInév
                 facquisitor.sales_channel,                          --ertcsat
                 fpack.proposal_sigdate (fproposal.proposal_idntfr), --aláírdátum
                 fproposal.arrival_date,                       -- érkezési idõ
                 fproposal.recording_date,                           --rogzdat
                 SUBSTR (
                    fpack.user_name_to_torzsszam(fpack.proposal_recording_user(fproposal.proposal_idntfr)),
                    1,
                    11
                 ),                                                  --rogzkod
                 fpack.proposal_contract_date (fproposal.proposal_idntfr), --szerzdat
                 SUBSTR (
                    fpack.user_name_to_torzsszam (
                       fpack.proposal_contract_user (fproposal.proposal_idntfr)
                    ),
                    1,
                    11
                 ),                                                 --szerzkod
                 fproposal.rejection_date,                           --elutdat
                 fpack.proposal_cancel_date (fproposal.proposal_idntfr), --stornodat
                 DECODE (fproposal.front_end, 'N', '', 'I'),        --frontend
                 fpack.proposal_error_log (fproposal.proposal_idntfr), --hibas
                 'Life' AS modtyp                                     --modtyp
          FROM   fproposal,
                 fproposal_error_log,
                 fproposal_letter,
                 facquisitor
         WHERE   facquisitor.proposal_idntfr = fproposal.proposal_idntfr
                 AND facquisitor.primary_acquisitor = 'Y'
                 AND (TRUNC(fpack.proposal_contract_date (
                               fproposal.proposal_idntfr
                            )) BETWEEN TRUNC (SYSDATE - 1, 'mm')
                                   AND  TRUNC (SYSDATE, 'ddd')
                      OR TRUNC (fproposal.rejection_date) BETWEEN TRUNC (
                                                                     SYSDATE
                                                                     - 1,
                                                                     'mm'
                                                                  )
                                                              AND  TRUNC (
                                                                      SYSDATE,
                                                                      'ddd'
                                                                   )
                      OR TRUNC (fproposal.arrival_date) BETWEEN TRUNC (
                                                                   SYSDATE - 1,
                                                                   'mm'
                                                                )
                                                            AND  TRUNC (
                                                                    SYSDATE,
                                                                    'ddd'
                                                                 ))
                 AND fproposal.cntry_flg LIKE 'HU'
                 AND facquisitor.sales_channel NOT LIKE 'SK'
                 AND facquisitor.sales_channel NOT LIKE 'CZ'
                 AND fproposal_error_log.proposal_idntfr(+) =
                       fproposal.proposal_idntfr
                 AND fproposal_letter.proposal_idntfr(+) =
                       fproposal.proposal_idntfr
      GROUP BY   fproposal.proposal_idntfr,
                 TO_CHAR (fpack.oid_to_idntfr (fproposal.contract_oid)),
                 fproposal.product_code,
                 fpack.contract_status_actuarial (fproposal.contract_oid,
                                                  SYSDATE),
                 fpack.proposal_acquisitor_id (fproposal.proposal_idntfr),
                 fpack.user_name (
                    fpack.proposal_acquisitor_id (fproposal.proposal_idntfr)
                 ),
                 fpack.proposal_kti (fproposal.proposal_idntfr),
                 fpack.kti_name (
                    fpack.proposal_kti (fproposal.proposal_idntfr)
                 ),
                 facquisitor.sales_channel,
                 fpack.proposal_sigdate (fproposal.proposal_idntfr),
                 fproposal.arrival_date,
                 fproposal.recording_date,
                 SUBSTR (
                    fpack.user_name_to_torzsszam(fpack.proposal_recording_user(fproposal.proposal_idntfr)),
                    1,
                    11
                 ),
                 fpack.proposal_contract_date (fproposal.proposal_idntfr),
                 SUBSTR (
                    fpack.user_name_to_torzsszam(fpack.proposal_contract_user(fproposal.proposal_idntfr)),
                    1,
                    11
                 ),
                 fproposal.rejection_date,
                 fpack.proposal_cancel_date (fproposal.proposal_idntfr),
                 DECODE (fproposal.front_end, 'N', '', 'I'),
                 fpack.proposal_error_log (fproposal.proposal_idntfr),
                 'Life';

   COMMIT;

   --  COMMIT;

   UPDATE   t_bsc_fufi a
      SET   papir_tipus = '1'
    WHERE   a.frontend IS NULL
            AND (a.vonalkod NOT IN
                       (SELECT   proposal_idntfr
                          FROM   fproposal
                         WHERE   front_end_type IN
                                       ('MYSIG', 'ENYIL', 'TAVERT')));

   COMMIT;

   UPDATE   t_bsc_fufi a
      SET   papir_tipus = '2'
    WHERE   a.frontend = 'I'
            AND (a.vonalkod NOT IN
                       (SELECT   proposal_idntfr
                          FROM   fproposal
                         WHERE   front_end_type IN
                                       ('MYSIG', 'ENYIL', 'TAVERT')));

   COMMIT;

   UPDATE   t_bsc_fufi a
      SET   papir_tipus = '7'
    WHERE   a.vonalkod IN (SELECT   proposal_idntfr
                             FROM   fproposal
                            WHERE   front_end_type = 'MYSIG');

   COMMIT;

   UPDATE   t_bsc_fufi a
      SET   papir_tipus = '8'
    WHERE   a.vonalkod IN (SELECT   proposal_idntfr
                             FROM   fproposal
                            WHERE   front_end_type = 'TAVERT');

   COMMIT;

   UPDATE   t_bsc_fufi a
      SET   papir_tipus = '9'
    WHERE   a.vonalkod IN (SELECT   proposal_idntfr
                             FROM   fproposal
                            WHERE   front_end_type = 'ENYIL');

   COMMIT;


   --MERGE
   EXECUTE IMMEDIATE 'TRUNCATE TABLE t_bsc_kontroll';

   --   COMMIT;

   INSERT INTO t_bsc_kontroll (vonalkod,
                               szerzazon,
                               allapotkod,
                               modkod,
                               modtyp,
                               papir_tipus,
                               ertcsat,
                               alirdat,
                               erkdat,
                               szerzdat,
                               elutdat,
                               stornodat,
                               ugynokkod,
                               ugynoknev,
                               ktikod,
                               ktinev)
      SELECT   TO_CHAR (vonalkod) vonalkod,
               TO_CHAR (szerzazon) szerzazon,
               allapotkod,
               modkod,
               modtyp,
               papir_tipus,
               ertcsat,
               alirdat,
               erkdat,
               szerzdat,
               elutdat,
               stornodat,
               ugynokkod,
               ugynoknev,
               ktikod,
               ktinev
        FROM   t_bsc_ablak
      UNION
      SELECT   vonalkod,
               szerzazon,
               allapotkod,
               modkod,
               modtyp,
               papir_tipus,
               ertcsat,
               alirdat,
               erkdat,
               szerzdat,
               elutdat,
               stornodat,
               ugynokkod,
               ugynoknev,
               ktikod,
               ktinev
        FROM   t_bsc_fufi;

   COMMIT;
END BSC_BASE;
/
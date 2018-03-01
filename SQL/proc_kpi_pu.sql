CREATE OR REPLACE PROCEDURE POORJ.BSC_PU
IS
BEGIN                                                                  
   EXECUTE IMMEDIATE 'TRUNCATE TABLE t_bsc_pu';
   COMMIT;

 EXECUTE IMMEDIATE
         'CREATE OR REPLACE SYNONYM fmoney_in_application FOR money_in_application@dijtart_exdbp_f400';
          COMMIT;
   
      EXECUTE IMMEDIATE
         'CREATE OR REPLACE SYNONYM fmoney_in FOR money_in@dijtart_exdbp_f400';
          COMMIT;

    EXECUTE IMMEDIATE
         'CREATE OR REPLACE SYNONYM fpack FOR pack@dijtart_exdbp_f400';
   
      EXECUTE IMMEDIATE
         'CREATE OR REPLACE SYNONYM fproposal FOR proposal@dijtart_exdbp_f400';
         
    EXECUTE IMMEDIATE
         'CREATE OR REPLACE SYNONYM fcontract_idntfr FOR contract_idntfr@dijtart_exdbp_f400';



INSERT INTO t_bsc_pu(SORSZAM,
                     SZERZAZON,
                     MODKOD,
                     IFI_MOZGKOD,
                     F_DIJBEIDO,
                     TIPUS,
                     ERKDAT,
                     KONYVDAT,
                     ATFUT)
SELECT   TO_CHAR (f_sorszam),
         TO_CHAR (f_szerz_azon),
         TO_CHAR (f_modkod),
         TO_CHAR (f_mozgtip),
         f_dijbeido,
         CASE
            WHEN a.f_mozgtip IN
                       ('I144', 'I164', 'I229', 'I114', 'I181', 'I118')
            THEN
               'ABLAK foglaló'
            WHEN a.f_mozgtip IN
                       ('I111',
                        'I112',
                        'I131',
                        'I132',
                        'I141',
                        'I142',
                        'I145',
                        'I151',
                        'I152',
                        'I161',
                        'I162',
                        'I166',
                        'I117',
                        'I119',
                        'I167',
                        'I155',
                        'I182',
                        'I191',
                        'I193',
                        'I184',
                        'I185',
                        'I192',
                        'I196',
                        'I163',
                        'I120',
                        'I187')
            THEN
               'ABLAK függõ'
            WHEN a.f_mozgtip IN ('I180', 'I183')
            THEN
               'ABLAK PSM'
         END,
         f_banknap,
         f_datum,
         f_datum - f_banknap - bnap_db (f_datum, f_banknap)
  FROM   ab_t_dijtabla a, ab_t_mozgas_kodok b
 WHERE   a.f_mozgtip = b.f_kod
         AND f_datum BETWEEN TRUNC (SYSDATE-1, 'mm')
                             AND TRUNC (SYSDATE, 'ddd')
         AND a.f_mozgtip IN
                  ('I144',
                   'I164',
                   'I229',
                   'I114',
                   'I181',
                   'I118',                                           --foglaló
                   'I111',
                   'I112',
                   'I131',
                   'I132',
                   'I141',
                   'I142',
                   'I145',
                   'I151',
                   'I152',
                   'I161',
                   'I162',
                   'I166',
                   'I117',
                   'I119',
                   'I167',
                   'I155',
                   'I182',
                   'I191',
                   'I193',
                   'I184',
                   'I185',
                   'I192',
                   'I196',
                   'I163',
                   'I120',
                   'I187',                                             --függõ
                   'I180',
                   'I183'                                                --PSM
                         )
UNION
SELECT   application_idntfr AS sorszam,
         TO_CHAR (c.contract_idntfr),
         TO_CHAR (d.product_code),
         TO_CHAR (b.ifi_mozgaskod),
         b.payment_date,
         CASE
            WHEN     money_in_type = 'propprem'
                 AND payment_mode = 'drcr1'
                 AND ifi_mozgaskod = '117'
            THEN
               'FUFI foglaló'
            WHEN     money_in_type = 'reguprem'
                 AND payment_mode = 'inttrnsf'
                 AND ifi_mozgaskod = '127'
            THEN
               'FUFI függõ'
            WHEN     money_in_type = 'propprem'
                 AND payment_mode = 'inttrnsf'
                 AND ifi_mozgaskod = '126'
            THEN
               'FUFI PSM'
         END
            AS típus,
         value_date AS erkdat,
         application_date AS konyvdat,
           application_date
         - value_date
         - bnap_db (application_date, value_date)
  FROM   fmoney_in_application a,
         (SELECT   DISTINCT money_in_idntfr,
                            payment_mode,
                            money_in_type,
                            ifi_mozgaskod,
                            payment_date,
                            value_date
            FROM   fmoney_in) b,
         fcontract_idntfr c,
         fproposal d
 WHERE   application_date BETWEEN TRUNC (SYSDATE-1, 'mm')
                             AND TRUNC (SYSDATE, 'ddd')
         AND a.money_in_idntfr = b.money_in_idntfr
         AND ref_entity_type = 'Premium'
         AND application_status = 'normal'
         AND a.cntry_flg = 'HU'
         AND a.currncy_code = 'HUF'
         AND money_in_type IN ('propprem', 'reguprem')
         AND payment_mode IN ('drcr1', 'inttrnsf')
         AND ifi_mozgaskod IN ('117', '127', '126')
         AND a.contract_oid = c.contract_oid(+)
         AND a.proposal_idntfr = d.proposal_idntfr(+);

   COMMIT;
END BSC_PU;
/

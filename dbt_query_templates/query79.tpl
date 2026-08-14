--
-- Legal Notice 
-- 
-- This document and associated source code (the "Work") is a part of a 
-- benchmark specification maintained by the TPC. 
-- 
-- The TPC reserves all right, title, and interest to the Work as provided 
-- under U.S. and international laws, including without limitation all patent 
-- and trademark rights therein. 
-- 
-- No Warranty 
-- 
-- 1.1 TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE INFORMATION 
--     CONTAINED HEREIN IS PROVIDED "AS IS" AND WITH ALL FAULTS, AND THE 
--     AUTHORS AND DEVELOPERS OF THE WORK HEREBY DISCLAIM ALL OTHER 
--     WARRANTIES AND CONDITIONS, EITHER EXPRESS, IMPLIED OR STATUTORY, 
--     INCLUDING, BUT NOT LIMITED TO, ANY (IF ANY) IMPLIED WARRANTIES, 
--     DUTIES OR CONDITIONS OF MERCHANTABILITY, OF FITNESS FOR A PARTICULAR 
--     PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OF 
--     WORKMANLIKE EFFORT, OF LACK OF VIRUSES, AND OF LACK OF NEGLIGENCE. 
--     ALSO, THERE IS NO WARRANTY OR CONDITION OF TITLE, QUIET ENJOYMENT, 
--     QUIET POSSESSION, CORRESPONDENCE TO DESCRIPTION OR NON-INFRINGEMENT 
--     WITH REGARD TO THE WORK. 
-- 1.2 IN NO EVENT WILL ANY AUTHOR OR DEVELOPER OF THE WORK BE LIABLE TO 
--     ANY OTHER PARTY FOR ANY DAMAGES, INCLUDING BUT NOT LIMITED TO THE 
--     COST OF PROCURING SUBSTITUTE GOODS OR SERVICES, LOST PROFITS, LOSS 
--     OF USE, LOSS OF DATA, OR ANY INCIDENTAL, CONSEQUENTIAL, DIRECT, 
--     INDIRECT, OR SPECIAL DAMAGES WHETHER UNDER CONTRACT, TORT, WARRANTY,
--     OR OTHERWISE, ARISING IN ANY WAY OUT OF THIS OR ANY OTHER AGREEMENT 
--     RELATING TO THE WORK, WHETHER OR NOT SUCH AUTHOR OR DEVELOPER HAD 
--     ADVANCE NOTICE OF THE POSSIBILITY OF SUCH DAMAGES. 
-- 
-- Contributors:
-- 
 define DEPCNT=random(0,9,uniform);
 define YEAR = random(1998,2000,uniform);
 define VEHCNT=random(-1,4,uniform);
 define _LIMIT=100;
 
 [_LIMITA] select [_LIMITB]
  c_last_name,c_first_name,substr(s_city,1,30) as s_city_substr,ss_ticket_number,amt,profit
  from
   (select ss_ticket_number
          ,ss_customer_sk
          ,{{ ref('store') }}.s_city
          ,sum(ss_coupon_amt) amt
          ,sum(ss_net_profit) profit
    from {{ ref('store_sales') }},{{ ref('date_dim') }},{{ ref('store') }},{{ ref('household_demographics') }}
    where {{ ref('store_sales') }}.ss_sold_date_sk = {{ ref('date_dim') }}.d_date_sk
    and {{ ref('store_sales') }}.ss_store_sk = {{ ref('store') }}.s_store_sk  
    and {{ ref('store_sales') }}.ss_hdemo_sk = {{ ref('household_demographics') }}.hd_demo_sk
    and ({{ ref('household_demographics') }}.hd_dep_count = [DEPCNT] or {{ ref('household_demographics') }}.hd_vehicle_count > [VEHCNT])
    and {{ ref('date_dim') }}.d_dow = 1
    and {{ ref('date_dim') }}.d_year in ([YEAR],[YEAR]+1,[YEAR]+2) 
    and {{ ref('store') }}.s_number_employees between 200 and 295
    group by ss_ticket_number,ss_customer_sk,ss_addr_sk,{{ ref('store') }}.s_city) ms,{{ ref('customer') }}
    where ss_customer_sk = c_customer_sk
 order by c_last_name,c_first_name,substr(s_city,1,30), profit
[_LIMITC]
;

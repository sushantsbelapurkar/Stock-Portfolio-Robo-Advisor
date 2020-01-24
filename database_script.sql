-- CREATING DATABASE

CREATE DATABASE IF NOT EXISTS AUTOMATIC_PORTFOLIO_CREATION;

USE AUTOMATIC_PORTFOLIO_CREATION;


show databases;

use sys;

select * from sys_config;

drop user 'nativeuser'@'localhost';

CREATE USER 'nativeuser'@'localhost'
IDENTIFIED WITH mysql_native_password BY 'password';

select user, host from mysql.user;

create database test1;

use test1;

GRANT ALL PRIVILEGES ON AUTOMATIC_PORTFOLIO_CREATION.* TO 'nativeuser'@'localhost';

CREATE INDEX idx_ins ON income_statement (stock_tikr,date_year);
CREATE INDEX idx_bs ON balance_sheet (stock_tikr,date_year);
CREATE INDEX idx_fr ON financial_ratio (stk_tkr,date_year);
CREATE INDEX idx_sp ON stock_profile (stk_tkr);
CREATE INDEX idx_fg ON financial_growth (stk_tkr,date_year);
CREATE INDEX idx_hp ON historical_price (stk_tkr);

-- drop view vw_req_param;
create view vw_req_param AS
(
select ins.stock_tikr, ins.date_year,ins.eps_diluted, hp.close_price, bs.total_current_assets, bs.total_curr_liabilities, bs.total_assets,bs.total_liabilities, bs.total_shareholders_equity, cf.dividend_payments,
ins.preferred_dividends,ins.net_income,st.sector, bs.net_debt, bs.goodwill_intangible_assets
from income_statement ins inner join balance_sheet bs inner join cash_flow_stmt cf inner join historical_price hp inner join stocks st
on ins.date_year = bs.date_year
and ins.date_year = cf.date_year
and ins.date_year = hp.date_year
and ins.stock_tikr = st.stock_tikr
and ins.stock_tikr = bs.stock_tikr
and ins.stock_tikr = hp.stk_tkr
and ins.stock_tikr = st.stock_tikr
);

-- This view is used to select value and growth portfolio. It is created using many diiferent tables of the database.

create view vw_select_stock AS
(
select INS.STOCK_TIKR,INS.DATE_YEAR,SP.SECTOR,SP.BETA,INS.EPS,FR.PE_RATIO,FR.PB_RATIO,FR.DEBT_TO_EQUITY,FR.DEBT_TO_ASSETS,
	   FR.CURRENT_RATIO,FR.DIVIDEND_YIELD,FG.BOOK_VALUE_PER_SHARE_GROWTH,FG.10Y_Dividend_per_Share_Growth_PER_SHARE,
       FG.3Y_Dividend_per_Share_Growth_PER_SHARE,FG.EPS_DILUTED_GROWTH,FR.MARKET_CAP,FR.ROE,FR.BOOK_VALUE_PER_SHARE,FR.ROIC,
       BS.TOTAL_SHAREHOLDERS_EQUITY AS OUTSTANDING_SHARES, FR.TANGIBLE_ASSET_VALUE,HP.CLOSE_PRICE,
       (SELECT MAX(HIGH) FROM HISTORICAL_PRICE WHERE STK_TKR = INS.STOCK_TIKR) AS HIGH_PRICE,
       (SELECT MIN(LOW) FROM HISTORICAL_PRICE WHERE STK_TKR = INS.STOCK_TIKR) AS LOW_PRICE
FROM   (INCOME_STATEMENT INS INNER JOIN BALANCE_SHEET BS INNER JOIN FINANCIAL_RATIO FR INNER JOIN STOCK_PROFILE SP INNER JOIN 
	   FINANCIAL_GROWTH FG
ON     INS.DATE_YEAR = BS.DATE_YEAR
AND	   INS.STOCK_TIKR = BS.STOCK_TIKR
AND	   INS.DATE_YEAR = FR.DATE_YEAR		
AND	   INS.STOCK_TIKR = FR.STK_TKR
AND    INS.DATE_YEAR = FG.DATE_YEAR
AND    INS.STOCK_TIKR = FG.STK_TKR
AND	   INS.STOCK_TIKR = SP.STK_TKR) LEFT JOIN HISTORICAL_PRICE HP
ON    INS.STOCK_TIKR = HP.STK_TKR
AND    INS.DATE_YEAR = HP.DATE_YEAR
);

-- This view is used to check company's valuation
create view pv_FCF as
 (
 select bs1.LONG_TERM_DEBT, bs1.TOTAL_SHAREHOLDERS_EQUITY, bs1.TOTAL_NON_CURR_LIABILITIES, bs1.STOCK_TIKR, bs1.date_year,
		bs1.TOTAL_CURRENT_ASSETS,   bs1.TOTAL_CURR_LIABILITIES,
        bs1.NWC,        inc_stmt.EARNINGS_BEFORE_TAX, inc_stmt.INCOME_TAX_EXPENSE, inc_stmt.REVENUE, inc_stmt.COST_OF_REVENUE, inc_stmt.OPERATING_EXPENSES,
		cfs.CAPITAL_EXPENDITURE, cfs.DEPRECIATION_AMORTIZATION,
		fn_rat.Working_Capital, histry.Close_price,
        (select beta 
        from stock_profile sp where sp.stk_tkr = bs1.STOCK_TIKR) beta
 from cash_flow_stmt cfs,
	income_statement inc_stmt,
    financial_ratio fn_rat,
    (select hist.*
    from historical_price hist,
   (select max(date_year) dt_yr,STOCK_TIKR from historical_price
   group by STOCK_TIKR) latst 
   where hist.STOCK_TIKR = latst.STOCK_TIKR
     and hist.date_year = latst.dt_yr
      ) histry,
   ( select bs.STOCK_TIKR,bs.LONG_TERM_DEBT, bs.TOTAL_SHAREHOLDERS_EQUITY, bs.TOTAL_NON_CURR_LIABILITIES,  bs.date_year,
		bs.TOTAL_CURRENT_ASSETS,   bs.TOTAL_CURR_LIABILITIES,
        ifnull((bs.TOTAL_CURRENT_ASSETS-bs.TOTAL_CURR_LIABILITIES) - (bs_prev.TOTAL_CURRENT_ASSETS-bs_prev.TOTAL_CURR_LIABILITIES),0) NWC
  from balance_sheet bs
  left join  balance_sheet bs_prev on bs.STOCK_TIKR = bs_prev.STOCK_TIKR and 
  CONVERT(year(bs.DATE_YEAR),unsigned integer)-1 = CONVERT(year(bs_prev.DATE_YEAR),unsigned integer)
  ) bs1
 where    bs1.stock_tikr = cfs.stock_tikr
   and substr(bs1.date_year,1,4) = substr(cfs.date_year,1,4)
    and bs1.stock_tikr = inc_stmt.stock_tikr
   and substr(bs1.date_year,1,4) = substr(inc_stmt.date_year,1,4) 
   and bs1.stock_tikr = fn_rat.stk_tkr
   and substr(bs1.date_year,1,4) = substr(fn_rat.date_year,1,4)  
   and bs1.stock_tikr = histry.STOCK_TIKR
   /*and bs1.STOCK_TIKR = 'SHOP'*/
   and CONVERT(year(bs1.DATE_YEAR),unsigned integer) between convert(year(curdate()),unsigned integer)-6 and convert(year(curdate()),unsigned integer)
   );



ALTER TABLE income_statement MODIFY stock_tikr varchar(20);
ALTER TABLE income_statement MODIFY date_year date;
ALTER TABLE balance_sheet MODIFY stock_tikr varchar(20);
ALTER TABLE balance_sheet MODIFY date_year date;
ALTER TABLE financial_ratio MODIFY stk_tkr varchar(20);
ALTER TABLE financial_ratio MODIFY date_year date;
ALTER TABLE financial_growth MODIFY stk_tkr varchar(20);
ALTER TABLE financial_growth MODIFY date_year date;
ALTER TABLE historical_price MODIFY stk_tkr varchar(20);
ALTER TABLE historical_price MODIFY date_year date;
ALTER TABLE stock_profile MODIFY stk_tkr varchar(20);




SET GLOBAL connect_timeout=28800;
SET GLOBAL wait_timeout=28800;
SET GLOBAL interactive_timeout=28800;

-- Table to create daily and average daily returns

Create table hist_annual_return as
(select A.STOCK_TIKR,/*CLOSE_PRICE,LAST_CLOSE,*/YR_OF_DATE,avg((((LAST_CLOSE)-(CLOSE_PRICE))/(CLOSE_PRICE))) as AVG_DAILY_RET
/*cast(round((pow(avg((((LAST_CLOSE)-(CLOSE_PRICE))/(CLOSE_PRICE)))+1,365))-1,4) as decimal(50,30)) as ANNUAL_RET*/
 from (select STOCK_TIKR,CLOSE_PRICE,left(date_year,4) as yr_of_date, date_year,
	lag(CLOSE_PRICE,1) over
						(partition by STOCK_TIKR              
                        order by left(date_year,4)
                        )LAST_CLOSE	
  from historical_price 
	/*where STOCK_TIKR IN ('AAPL','FB')*/) as A
    group by A.STOCK_TIKR,A.yr_of_date);
	
create table pv_fcf
   as
   select bs1.LONG_TERM_DEBT, bs1.TOTAL_SHAREHOLDERS_EQUITY, bs1.TOTAL_NON_CURR_LIABILITIES, bs1.STOCK_TIKR, bs1.date_year,
		bs1.TOTAL_CURRENT_ASSETS,   bs1.TOTAL_CURR_LIABILITIES,
        bs1.NWC,        inc_stmt.EARNINGS_BEFORE_TAX, inc_stmt.INCOME_TAX_EXPENSE, inc_stmt.REVENUE, inc_stmt.COST_OF_REVENUE, inc_stmt.OPERATING_EXPENSES,
		cfs.CAPITAL_EXPENDITURE, cfs.DEPRECIATION_AMORTIZATION,
		fn_rat.Working_Capital, histry.Close_price
insert into pv_fcf
   select bs1.LONG_TERM_DEBT, bs1.TOTAL_SHAREHOLDERS_EQUITY, bs1.TOTAL_NON_CURR_LIABILITIES, bs1.STOCK_TIKR, bs1.date_year,
		bs1.TOTAL_CURRENT_ASSETS,   bs1.TOTAL_CURR_LIABILITIES,
        bs1.NWC,        inc_stmt.EARNINGS_BEFORE_TAX, inc_stmt.INCOME_TAX_EXPENSE, inc_stmt.REVENUE, inc_stmt.COST_OF_REVENUE, inc_stmt.OPERATING_EXPENSES,
		cfs.CAPITAL_EXPENDITURE, cfs.DEPRECIATION_AMORTIZATION,
		fn_rat.Working_Capital, histry.Close_price
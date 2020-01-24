# Stock-Portfolio-Robo-Advisor
White paper also located at:
https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3517001

Stock Portfolio Robo advisor is the automatic stock portfolio construction and rebalancing software created. Using the listed company's financial statements, we built a customized model based on value investment and growth investment strategy to select stocks for Value and Growth portfolio. Also, we constructed a Machine Learning based model to identify the stocks which may perform better than the S&P 500 for the upcoming year.

Technology and tools used: Python, MySQL, Machine Learning - Classification algorithms, Feature Engineering, cross validation, DNN, Keras. 

Concepts used: Financial Analytics-Value investment and growth investment, Sharpe Ratio,Modern Portfolio Theory(MPT), Optimization - To decide the weights of the stocks according to MPT.

[Dataset used] https://github.com/antoinevulcain/Financial-Modeling-Prep-API: Balance sheet, Cashflow statement, income statement, and historical returns of 4000 listed stocks.


Steps:
-	Calculating the intrinsic value of each stock - This code is not shared here.
- Automatically load all the data to dataset periodically & created complex SQL quries to select the data required for Python/ML models -   This code is not shared here.
-	Based on value investing and growth investing strategy, automatically select the undervalued stocks based on intrinsic value.
-	Using optimization, Modern Portfolio Theory, and Sharpe ratio allocate weight to the portfolio stocks.
-	Rebalancing the portfolio once a three year.
-	Portfolio risk customization and watchlist options available to consumers through optimization.
-	Using Machine learning classification, PCA, DNN algorithms and passing entire financial statements data, predict the list of stocks that may perform better than S&P500. 

# Result
- For Value and Growth portfolio, performance is better than S&P500 for the period of 2015-2018
- For ML/AI driven stock selection - Accuracy achieved ~ 75%

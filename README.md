# Customer Retention Analysis

## Preview
<p align="center">
  <table>
    <tr>
      <td><img src="outputs/churn_by_contract.png" alt="Churn by Contract" width="300"></td>
      <td><img src="outputs/churn_by_tenure.png" alt="Churn by Tenure" width="300"></td>
      <td><img src="outputs/revenue_at_risk.png" alt="Revenue at Risk" width="300"></td>
    </tr>
  </table>
</p>

## 1. Business Problem

A telecom provider is losing a meaningful share of its customer base every month, and leadership wants to know: **which customers are churning, why they’re leaving, and where to focus limited retention efforts.**

This isn't a modeling exercise — it's a resource-allocation problem. The company can't stop all churn, so the real question is: what's the highest-impact place to intervene?

## 2. Data

Public dataset: [IBM Telco Customer Churn sample](https://www.kaggle.com/datasets/blastchar/telco-customer-churn), 7,043 customer records covering demographics, account details, services, and churn status.

## 3. Approach

I performed the analysis twice — once in Python and once in SQL Server. I started with Python, then rebuilt the table from scratch in SQL Server and repeated the analysis there, including a window function, to get real, demonstrable SQL experience rather than just listing it as a skill.

Matching results in both versions confirmed the work was done correctly. See `analysis_python.ipynb` and `analysis_sqlserver.sql`.

## 4. Key Findings

- Churn sits at 26.6% overall, but it's not evenly spread — the customers leaving are worth 
more than the average customer, since they account for 30.5% of monthly revenue ($139K of 
$455K).

- Contract type is the clearest driver I found. Month-to-month customers churn at 42.7%, one-year 
at 11.3%, two-year at 2.8%. Risk is also front-loaded early in the relationship — over half of 
customers in their first 6 months churn, compared to under 10% after year four.

- The narrowest, most useful segment I found is month-to-month customers paying by electronic 
check with 12 months or less of tenure: 954 customers, 63.1% churn, $66K/month exposed.

- Something I didn't expect: the highest-paying churned customers aren't concentrated in 
month-to-month at all — they're spread pretty evenly across all three contract types. So the 
group with the most churn risk and the group with the biggest individual losses aren't quite 
the same thing.

## 5. Recommendation

Target the compounding-risk segment first — month-to-month, electronic check, tenure ≤12 
months — with a proactive offer (discounted contract conversion, or a nudge toward automatic 
payment, which independently correlates with lower churn). This is the highest concentration 
of risk in the data, so it's the most efficient place to start.

Before rolling this out broadly, I'd run it as an A/B test: give the offer to half the segment 
at random, leave the other half as-is, and compare churn after a few months. The payment-method 
correlation could just as easily reflect a price-sensitive customer type as an actual fixable 
problem, and that's worth knowing before spending real budget on it.

## 6. Limitations

This is one snapshot in time, not tracked over time, so what I'm calling 'risk factors' are really just strong correlations.

Before spending real budget on any of this, I'd want to test it on a smaller group first and check it actually works.

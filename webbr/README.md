<h1> Webbr UBI App </h1>
<p>This app allows the user to explore the possibility of a Universal Basic Income (UBI) funded by a progressive income tax. The user is offered three inputs to fill in, at which point the app will give the optimal marginal tax rate associated with the user's choices. </p>

<h3> Inputs </h2>
<ul>
  <li> Choose an initial endowment of income from two choices: actual US household data from 2019 and UK household data from 2017-2018. Note that the US data is in USD and the UK data is in Pounds Sterling, which doesn't affect the distribution of each country but makes utility comparisons between the countries impossible. This is by design, as comparing utility or social welfare between countries is problematic anyway. </li>
  <li> The amount of lost national income on the marginal dollar taxed varies by economy, type of taxation, time, and more. Choose a number from 0 to 3 that represents the dollars lost in deadweight loss from every dollar collected in taxes. </li>
  <li> Choose a Social Welfare Function, a way of relating utility or happiness to income. A linear SWF means that equality is unimportant -- the 10,000th dollar is just as important as the 10th to the recipient. On the other side, the max-min distribution says that social welfare is only as high as the happiness of the poorest individual. The Gini function, proposed by the economist Amartya Sen, is a weighted average of mean income and the Gini Coefficient, a measure of inequality. </li>
</ul>

<h3> Algorithm</h3>
  <p> The heart of the backend is in the <code>post_inc()</code> function. The function mainly consists of a nested <code>for</code> loop, where the outer loop iterates    over a vector top tax rates and the inner loop iterates over the 100 reference households, each representing a percentile of the income distribution. In the inner        loop, four values are computed that are of particular note:
<ul>
  <li> <b> Individual Tax Rate (R) </b> is computed based on the top tax rate passed to the inner loop. If that rate is called <b>r</b>, then the individual tax rate for each quartile in descending order is <b>i, r/2, r/4, </b> and <b>0</b>.</li>
  <li> <b> Income after Loss (A) </b> is computed based on the assumption that individuals anticipate their tax bill and adjust their output to compensate in advance. Thus, as a function of the individual tax rate <b>R</b>, counterfactual income <b>I</b>, and the income loss value passed as a user input <b>L</b>, we have <b>A = I / (1 + RL)</b>.</li>
  <li><b> After-Tax Income (F) </b> is just <b>A - A*R</b>.</li>
  <li> <b> After-UBI Income (U) </b> is just <b> F + (A - F)</b>.</l> </ul>
  
  <p> There are two significant simplifying assumptions in this procedure. The first is that the progressive income tax is not marginal -- households in a higher income quartile see their entire income taxed at a higher rate than lower-income households. Although this would create a tax cliff and thus be a terrible taxation model in real life, it should not be overly problematic for this exercise. Second, the deadweight loss from taxation has a constant elasticity throughout the household's production function. In reality, there is no reason to expect that an extra dollar of collected taxes should have the same effect on a household's output no matter what the effective tax rate is or how wealthy the household is. Again, this simplification should not affect the thrust of the analysis. </p>
  
 <p> The rest of the backend code is straightforward and hopefully uncontroversial. If you have any questions, email the author at jacobg314@hotmail.com
    
    
<h3>Sources:</h3>
<a href="https://dqydj.com/average-median-top-household-income-percentiles">US Household Income data</a> <br>
<a href="https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/895407/NS_Table_3_1a_1718.xlsx">UK Household Income data</a> <br>
<a href="https://www.jstor.org/stable/1806725?seq=1">Range of estimates for Marginal Welfare Cost of Taxation </a> <br>

